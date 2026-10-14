use crate::{
    errors::{AppError, Result},
    model::Selection,
};
use serde::{Deserialize, Serialize, de::DeserializeOwned};
use std::{
    io::{BufRead, BufReader, Read},
    path::PathBuf,
    process::{Command, Stdio},
    sync::OnceLock,
};
use ts_rs::TS;

#[cfg(windows)]
use std::os::windows::process::CommandExt;

const BRIDGE: &str = include_str!("../motor-api.ps1");
/// The engine the PowerShell version runs too, taken from `src/` so a fix there reaches both.
const ENGINE: [(&str, &str); 3] = [
    ("1-catalogo.ps1", include_str!("../../../src/1-catalogo.ps1")),
    ("2-motor.ps1", include_str!("../../../src/2-motor.ps1")),
    ("2b-recomendacion.ps1", include_str!("../../../src/2b-recomendacion.ps1")),
];
/// Windows PowerShell 5.1 reads a script without it as ANSI and breaks every accent.
const UTF8_BOM: &[u8] = b"\xEF\xBB\xBF";
const ENGINE_FOLDER: &str = "OfficeGo-motor";
const PAYLOAD_VARIABLE: &str = "OFFICEGO_PAYLOAD";
const CREATE_NO_WINDOW: u32 = 0x0800_0000;
const STDERR_TAIL: usize = 600;

/// One-shot questions to the engine.
#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(tag = "action", rename_all = "kebab-case")]
pub enum Query {
    Catalog,
    Machine,
    License,
    Configuration { selection: Selection },
}

/// Long jobs that report their progress line by line.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(tag = "action", rename_all = "kebab-case")]
pub enum Task {
    Install { selection: Selection },
    Download { selection: Selection, folder: String },
    Activate,
    ApplyKey { key: String },
    Repair,
    Uninstall,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(tag = "event", rename_all = "camelCase")]
pub enum TaskEvent {
    Step {
        step: TaskStep,
    },
    #[serde(rename_all = "camelCase")]
    Progress {
        percent: u32,
        done_mb: f64,
        total_mb: f64,
    },
    Waiting {
        seconds: u32,
    },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum TaskStep {
    DownloadSetup,
    DownloadOffice,
    Install,
    Activate,
    ApplyKey,
    Repair,
    Uninstall,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct TaskOutcome {
    pub ok: bool,
    #[serde(default)]
    pub reason: Option<TaskReason>,
    #[serde(default)]
    pub exit_code: Option<i64>,
    #[serde(default)]
    pub folder: Option<String>,
    /// What Microsoft's tool answered, when it said no.
    #[serde(default)]
    pub detail: Option<String>,
}

/// Why a task ended without doing its job.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum TaskReason {
    NotAdmin,
    LowDisk,
    Offline,
    OnlineOnly,
    NoOffice,
    InvalidKey,
    KeyRejected,
    NotActivated,
    InstallerFailed,
    StillInstalled,
}

#[derive(Deserialize)]
#[serde(untagged)]
enum Answer<T> {
    Failure { error: String },
    Data { data: T },
}

#[derive(Deserialize)]
#[serde(untagged)]
enum Line {
    Event(TaskEvent),
    End(End),
}

#[derive(Deserialize)]
#[serde(tag = "event", rename_all = "camelCase")]
enum End {
    Done(TaskOutcome),
    Failed { error: String },
}

fn write_engine() -> std::io::Result<PathBuf> {
    let folder = std::env::temp_dir().join(ENGINE_FOLDER);
    std::fs::create_dir_all(folder.join("motor"))?;
    let write = |path: PathBuf, text: &str| {
        let bytes = [UTF8_BOM, text.as_bytes()].concat();
        if std::fs::read(&path).is_ok_and(|current| current == bytes) { Ok(path) } else { std::fs::write(&path, bytes).map(|()| path) }
    };
    for (name, text) in ENGINE {
        write(folder.join("motor").join(name), text)?;
    }
    write(folder.join("motor-api.ps1"), BRIDGE)
}

/// The bridge script on disk, written once per run.
fn bridge() -> Result<PathBuf> {
    static WRITTEN: OnceLock<std::result::Result<PathBuf, String>> = OnceLock::new();
    WRITTEN.get_or_init(|| write_engine().map_err(|e| e.to_string())).clone().map_err(AppError::Storage)
}

/// Windows PowerShell by its full path: an elevated process must not run whatever `powershell.exe` the PATH finds first.
pub fn power_shell() -> PathBuf {
    let system = std::env::var_os("SystemRoot").map_or_else(|| PathBuf::from(r"C:\Windows"), PathBuf::from);
    system.join(r"System32\WindowsPowerShell\v1.0\powershell.exe")
}

fn command(payload: &impl Serialize) -> Result<Command> {
    let payload = serde_json::to_string(payload).map_err(|e| AppError::Engine(e.to_string()))?;
    let mut command = Command::new(power_shell());
    command
        .args(["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"])
        .arg(bridge()?)
        .env(PAYLOAD_VARIABLE, payload)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    #[cfg(windows)]
    command.creation_flags(CREATE_NO_WINDOW);
    Ok(command)
}

fn tail(text: &[u8]) -> String {
    let text = String::from_utf8_lossy(text);
    let text = text.trim();
    let start = text.char_indices().rev().nth(STDERR_TAIL).map_or(0, |(index, _)| index);
    text[start..].to_string()
}

fn parse_answer<T: DeserializeOwned>(stdout: &str) -> Option<Result<T>> {
    stdout.lines().rev().find_map(|line| serde_json::from_str::<Answer<T>>(line.trim()).ok()).map(|answer| match answer {
        Answer::Data { data } => Ok(data),
        Answer::Failure { error } => Err(AppError::Engine(error)),
    })
}

pub fn query<T: DeserializeOwned>(query: &Query) -> Result<T> {
    let output = command(query)?.output().map_err(AppError::power_shell)?;
    parse_answer(&String::from_utf8_lossy(&output.stdout)).unwrap_or_else(|| Err(AppError::EngineAnswer(tail(&output.stderr))))
}

fn parse_line(line: &str) -> Option<Line> {
    serde_json::from_str(line.trim()).ok()
}

/// Runs a task, handing each progress event to `report`; a task always ends, even if PowerShell dies halfway.
pub fn run(task: &Task, mut report: impl FnMut(TaskEvent)) -> Result<TaskOutcome> {
    let mut child = command(task)?.spawn().map_err(AppError::power_shell)?;
    let stderr = child.stderr.take().map(|mut pipe| {
        std::thread::spawn(move || {
            let mut text = Vec::new();
            pipe.read_to_end(&mut text).map(|_| text).unwrap_or_default()
        })
    });
    let mut end = None;
    if let Some(stdout) = child.stdout.take() {
        for line in BufReader::new(stdout).lines().map_while(std::result::Result::ok) {
            match parse_line(&line) {
                Some(Line::Event(event)) => report(event),
                Some(Line::End(found)) => end = Some(found),
                None => {}
            }
        }
    }
    child.wait()?;
    let stderr = stderr.and_then(|reader| reader.join().ok()).unwrap_or_default();
    match end {
        Some(End::Done(outcome)) => Ok(outcome),
        Some(End::Failed { error }) => Err(AppError::Engine(error)),
        None => Err(AppError::EngineStopped(tail(&stderr))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::{Catalog, License, MachineReport};
    use serde_json::json;

    fn action(payload: impl Serialize) -> String {
        serde_json::to_value(payload).unwrap()["action"].as_str().unwrap().to_string()
    }

    #[test]
    fn the_bridge_answers_every_action() {
        let selection = Selection::default();
        let actions = [
            action(Query::Catalog),
            action(Query::Machine),
            action(Query::License),
            action(Query::Configuration { selection: selection.clone() }),
            action(Task::Install { selection: selection.clone() }),
            action(Task::Download { selection, folder: String::new() }),
            action(Task::Activate),
            action(Task::ApplyKey { key: String::new() }),
            action(Task::Repair),
            action(Task::Uninstall),
        ];
        for name in actions {
            assert!(BRIDGE.contains(&format!("'{name}' {{")), "motor-api.ps1 has no '{name}' case");
        }
    }

    #[test]
    fn the_bridge_loads_the_engine_files_rust_writes() {
        for (name, _) in ENGINE {
            assert!(BRIDGE.contains(&format!(r"\motor\{name}")), "motor-api.ps1 does not load {name}");
        }
    }

    #[test]
    fn reads_answers_and_failures() {
        let noise = "Advertencia\n{\"data\":{\"activated\":true,\"name\":\"Office\"}}\n";
        assert_eq!(parse_answer::<Option<License>>(noise).unwrap().unwrap(), Some(License { activated: true, name: "Office".into() }));
        assert_eq!(parse_answer::<Option<License>>("{\"data\":null}").unwrap().unwrap(), None);
        let failure = "{\"error\":\"Acción desconocida\",\"event\":\"failed\"}";
        assert_eq!(parse_answer::<Option<License>>(failure).unwrap(), Err(AppError::Engine("Acción desconocida".into())));
        assert!(parse_answer::<Option<License>>("").is_none());
    }

    #[test]
    fn tells_progress_from_the_end_of_a_task() {
        let progress = parse_line(r#"{"event":"progress","percent":42,"doneMb":1.5,"totalMb":3.6}"#);
        assert!(matches!(progress, Some(Line::Event(TaskEvent::Progress { percent: 42, .. }))));
        let done = parse_line(r#"{"event":"done","ok":false,"reason":"onlineOnly","exitCode":null}"#);
        assert!(matches!(done, Some(Line::End(End::Done(TaskOutcome { ok: false, reason: Some(TaskReason::OnlineOnly), .. })))));
        let failed = parse_line(r#"{"event":"failed","error":"boom"}"#);
        assert!(matches!(failed, Some(Line::End(End::Failed { .. }))));
        assert!(parse_line("Descargando…").is_none());
    }

    #[test]
    fn keeps_the_end_of_long_errors() {
        let long = "x".repeat(STDERR_TAIL * 2) + "final";
        assert!(tail(long.as_bytes()).ends_with("final"));
        assert_eq!(tail(long.as_bytes()).chars().count(), STDERR_TAIL + 1);
    }

    #[test]
    fn reads_a_machine_as_the_bridge_writes_it() {
        let answer = json!({ "data": {
            "machine": { "os": "Windows 11 Home", "build": "26300.9457", "supported": true, "architecture": "64 bits", "bits": "64",
                "powershell": "5.1", "cpu": "AMD Ryzen 7", "cpuGhz": 3.8, "cores": 8, "threads": 16, "cpuLoad": 14, "ramGb": 31.3,
                "ramFreeGb": 7.7, "ramLoad": 75, "ramModules": 2, "ramSpeed": "5600 MHz", "gpu": "AMD Radeon 780M", "resolution": "1920 × 1200",
                "admin": false, "defender": null, "disks": [{ "letter": "C:", "totalGb": 951.8, "freeGb": 300.5, "usedPercent": 68, "system": true }] },
            "graphics": { "brand": "amd", "color": "#ED1C24", "abbreviation": "AMD", "old": false },
            "office": null,
            "recommendation": { "product": "2024", "reason": "win10Before22H2", "supported": true,
                "warnings": [{ "level": "error", "code": "lowDisk", "values": { "freeGb": 2.0, "drive": "C:", "minimumGb": 5.0 } },
                             { "level": "info", "code": "defenderOn", "values": {} }] } } });
        let report = parse_answer::<MachineReport>(&answer.to_string()).unwrap().unwrap();
        assert_eq!(report.recommendation.warnings[0].values.drive.as_deref(), Some("C:"));
        assert_eq!(report.machine.defender, None);
    }

    #[test]
    #[ignore = "runs the real engine on this Windows"]
    fn the_real_engine_answers() {
        let catalog: Catalog = query(&Query::Catalog).unwrap();
        assert_eq!(catalog.products.len(), 6);
        let report: MachineReport = query(&Query::Machine).unwrap();
        assert!(report.machine.ram_gb > 0.0);
        let _: Option<License> = query(&Query::License).unwrap();
        let selection = Selection {
            product: "2021".into(),
            edition: "Standard".into(),
            language: "es-mx".into(),
            bits: "64".into(),
            apps: vec!["Word".into()],
            add_ons: vec!["VisioPro".into()],
        };
        let xml: String = query(&Query::Configuration { selection: selection.clone() }).unwrap();
        assert!(xml.contains("VisioPro2021Volume"));
        let outcome = run(&Task::Download { selection: Selection { product: "2016".into(), ..selection }, folder: "x".into() }, |_| {}).unwrap();
        assert_eq!(outcome.reason, Some(TaskReason::OnlineOnly));
    }
}
