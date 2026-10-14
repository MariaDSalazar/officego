use serde::Serialize;
use std::fmt;
use ts_rs::TS;

/// Failure reasons the UI renders as `errors:<code>`.
#[derive(Clone, Debug, PartialEq, Serialize, TS)]
#[ts(export)]
#[serde(tag = "code", content = "detail", rename_all = "camelCase")]
pub enum AppError {
    PowerShell(String),
    Engine(String),
    EngineAnswer(String),
    EngineStopped(String),
    AdminDeclined,
    Network(String),
    BadDownload,
    UpToDate,
    Storage(String),
}

pub type Result<T> = std::result::Result<T, AppError>;

impl AppError {
    pub fn power_shell(error: impl fmt::Display) -> AppError {
        AppError::PowerShell(error.to_string())
    }
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for AppError {}

impl From<std::io::Error> for AppError {
    fn from(error: std::io::Error) -> AppError {
        AppError::Storage(error.to_string())
    }
}

impl From<reqwest::Error> for AppError {
    fn from(error: reqwest::Error) -> AppError {
        AppError::Network(error.to_string())
    }
}
