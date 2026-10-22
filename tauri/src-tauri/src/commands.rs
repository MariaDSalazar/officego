use crate::{
    engine::{self, Query, Task, TaskEvent, TaskOutcome},
    errors::{AppError, Result},
    model::{Catalog, License, MachineReport, Selection},
    updates::{self, Release},
};
use std::process::Command;
use tauri::{AppHandle, ipc::Channel};
use tauri_plugin_opener::OpenerExt;

#[cfg(windows)]
use std::os::windows::process::CommandExt;

/// Passive progress window, update mode that never uninstalls, and OfficeGo reopened when done.
const INSTALLER_UPDATE_ARGS: [&str; 3] = ["/P", "/UPDATE", "/R"];
const UPDATE_FOLDER: &str = "OfficeGo-update";
const RELAUNCH_VARIABLE: &str = "OFFICEGO_EXE";
const RELAUNCH_ELEVATED: &str = "Start-Process -FilePath $env:OFFICEGO_EXE -Verb RunAs";
const CREATE_NO_WINDOW: u32 = 0x0800_0000;

async fn blocking<T: Send + 'static>(job: impl FnOnce() -> Result<T> + Send + 'static) -> Result<T> {
    tauri::async_runtime::spawn_blocking(job).await.map_err(|e| AppError::Engine(e.to_string()))?
}

#[tauri::command]
pub async fn catalog() -> Result<Catalog> {
    blocking(|| engine::query(&Query::Catalog)).await
}

#[tauri::command]
pub async fn machine() -> Result<MachineReport> {
    blocking(|| engine::query(&Query::Machine)).await
}

#[tauri::command]
pub async fn license() -> Result<Option<License>> {
    blocking(|| engine::query(&Query::License)).await
}

#[tauri::command]
pub async fn configuration(selection: Selection) -> Result<String> {
    blocking(move || engine::query(&Query::Configuration { selection })).await
}

#[tauri::command]
pub async fn run_task(task: Task, events: Channel<TaskEvent>) -> Result<TaskOutcome> {
    blocking(move || {
        engine::run(&task, |event| {
            let _ = events.send(event);
        })
    })
    .await
}

#[tauri::command]
pub async fn stop_task() -> Result<()> {
    blocking(engine::stop).await
}

/// Opens OfficeGo again with administrator rights and closes this copy; Windows asks the user first.
#[tauri::command]
pub async fn relaunch_as_admin(app: AppHandle) -> Result<()> {
    let exe = std::env::current_exe()?;
    let granted = blocking(move || {
        let mut command = Command::new(engine::power_shell());
        command.args(["-NoProfile", "-NonInteractive", "-Command", RELAUNCH_ELEVATED]).env(RELAUNCH_VARIABLE, exe);
        #[cfg(windows)]
        command.creation_flags(CREATE_NO_WINDOW);
        Ok(command.status().map_err(AppError::power_shell)?.success())
    })
    .await?;
    if !granted {
        return Err(AppError::AdminDeclined);
    }
    app.exit(0);
    Ok(())
}

#[tauri::command]
pub fn open_folder(app: AppHandle, path: String) -> Result<()> {
    std::fs::create_dir_all(&path)?;
    app.opener().open_path(path, None::<&str>).map_err(|e| AppError::Storage(e.to_string()))
}

#[tauri::command]
pub async fn check_update(language: String) -> Result<Option<Release>> {
    updates::check(&language).await
}

/// Downloads the newer installer, checks it and runs it over this copy, which closes to let it work.
#[tauri::command]
pub async fn install_update(app: AppHandle, progress: Channel<f64>) -> Result<()> {
    let release = updates::latest().await?.ok_or(AppError::UpToDate)?;
    let installer = updates::download(&release, &std::env::temp_dir().join(UPDATE_FOLDER), |done| {
        let _ = progress.send(done);
    })
    .await?;
    Command::new(installer).args(INSTALLER_UPDATE_ARGS).spawn()?;
    app.exit(0);
    Ok(())
}
