// =====================================================================
//  OfficeGo · capa Rust
//
//  Deliberadamente fina. Todo el trabajo lo hace el mismo motor de
//  PowerShell que usa la version 1.x: aqui solo se le llama y se
//  reenvia lo que responde a la interfaz web.
// =====================================================================
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::io::{BufRead, BufReader, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use tauri::{Emitter, Window};

#[cfg(windows)]
use std::os::windows::process::CommandExt;
#[cfg(windows)]
const SIN_VENTANA: u32 = 0x0800_0000; // CREATE_NO_WINDOW

// El motor viaja dentro del ejecutable, y se toma directamente de src/:
// una copia aparte se desincroniza en cuanto alguien arregla algo en una sola.
const API: &str = include_str!("../motor-api.ps1");
const CATALOGO: &str = include_str!("../../../src/1-catalogo.ps1");
const MOTOR: &str = include_str!("../../../src/2-motor.ps1");
const RECOM: &str = include_str!("../../../src/2b-recomendacion.ps1");

/// Deja el motor en %TEMP%\OfficeGo-motor y devuelve la ruta del api.
fn preparar_motor() -> Result<PathBuf, String> {
    let base = std::env::temp_dir().join("OfficeGo-motor");
    let sub = base.join("motor");
    std::fs::create_dir_all(&sub).map_err(|e| e.to_string())?;

    let escribir = |ruta: PathBuf, contenido: &str| -> Result<(), String> {
        let mut f = std::fs::File::create(&ruta).map_err(|e| e.to_string())?;
        // BOM UTF-8: sin el, PowerShell 5.1 lee el archivo como ANSI
        // y destroza los acentos y los caracteres de dibujo.
        f.write_all(&[0xEF, 0xBB, 0xBF]).map_err(|e| e.to_string())?;
        f.write_all(contenido.as_bytes()).map_err(|e| e.to_string())
    };

    let api = base.join("motor-api.ps1");
    escribir(api.clone(), API)?;
    escribir(sub.join("1-catalogo.ps1"), CATALOGO)?;
    escribir(sub.join("2-motor.ps1"), MOTOR)?;
    escribir(sub.join("2b-recomendacion.ps1"), RECOM)?;
    Ok(api)
}

fn comando_ps(api: &PathBuf, accion: &str, datos: &str) -> Command {
    let mut c = Command::new("powershell.exe");
    c.args([
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", api.to_str().unwrap_or_default(),
        "-Accion", accion,
        "-Datos", datos,
    ]);
    #[cfg(windows)]
    c.creation_flags(SIN_VENTANA);
    c
}

/// Acciones que responden de una vez: devuelven el JSON del motor.
#[tauri::command]
async fn consultar(accion: String, datos: Option<String>) -> Result<String, String> {
    let api = preparar_motor()?;
    let datos = datos.unwrap_or_else(|| "{}".into());
    let salida = comando_ps(&api, &accion, &datos)
        .output()
        .map_err(|e| format!("No se pudo ejecutar PowerShell: {e}"))?;

    if !salida.status.success() && salida.stdout.is_empty() {
        return Err(String::from_utf8_lossy(&salida.stderr).trim().to_string());
    }
    Ok(String::from_utf8_lossy(&salida.stdout).trim().to_string())
}

/// Acciones largas: cada linea que escribe el motor se reenvia como
/// evento, para que la barra de progreso se mueva de verdad.
#[tauri::command]
async fn ejecutar(window: Window, accion: String, datos: Option<String>) -> Result<(), String> {
    let api = preparar_motor()?;
    let datos = datos.unwrap_or_else(|| "{}".into());

    let mut hijo = comando_ps(&api, &accion, &datos)
        .stdout(Stdio::piped())
        .spawn()
        .map_err(|e| format!("No se pudo ejecutar PowerShell: {e}"))?;

    let salida = hijo.stdout.take().ok_or("Sin salida del motor")?;
    for linea in BufReader::new(salida).lines().map_while(Result::ok) {
        let l = linea.trim();
        if l.is_empty() { continue; }
        let _ = window.emit("motor", l);
    }
    let _ = hijo.wait();
    Ok(())
}

#[tauri::command]
fn abrir_enlace(url: String) {
    // solo http/https: no queremos que la web lance cualquier cosa
    if url.starts_with("https://") || url.starts_with("http://") {
        let _ = Command::new("cmd").args(["/c", "start", "", &url]).spawn();
    }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            consultar, ejecutar, abrir_enlace
        ])
        .run(tauri::generate_context!())
        .expect("no se pudo iniciar OfficeGo");
}
