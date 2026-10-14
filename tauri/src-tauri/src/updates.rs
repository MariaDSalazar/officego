use crate::errors::{AppError, Result};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::{
    io::Write,
    path::{Path, PathBuf},
    time::Duration,
};
use ts_rs::TS;

const LATEST_RELEASE: &str = "https://api.github.com/repos/MariaDSalazar/officego/releases/latest";
const GITHUB_JSON: &str = "application/vnd.github+json";
/// The NSIS installer; the portable executable and the PowerShell files ship beside it.
const INSTALLER_SUFFIX: &str = "-setup.exe";
/// Tauri's NSIS uninstaller sits next to the installed app and never next to the portable one.
const UNINSTALLER: &str = "uninstall.exe";
const SHA256_PREFIX: &str = "sha256:";
const CHECK_TIMEOUT: Duration = Duration::from_secs(10);
const DOWNLOAD_TIMEOUT: Duration = Duration::from_secs(600);
const CURRENT_VERSION: &str = env!("CARGO_PKG_VERSION");
const USER_AGENT: &str = concat!("officego/", env!("CARGO_PKG_VERSION"));

/// A published version newer than the running one.
#[derive(Clone, Debug, PartialEq, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Release {
    pub version: String,
    pub notes_url: String,
    /// Whether this copy was installed and can update itself; a portable copy sends the user to the release page.
    pub installable: bool,
    #[serde(skip)]
    installer_url: String,
    #[serde(skip)]
    size: u64,
    #[serde(skip)]
    sha256: Option<String>,
}

#[derive(Deserialize)]
struct ReleaseAnswer {
    tag_name: String,
    html_url: String,
    assets: Vec<AssetAnswer>,
}

#[derive(Deserialize)]
struct AssetAnswer {
    name: String,
    browser_download_url: String,
    size: u64,
    digest: Option<String>,
}

fn version_numbers(version: &str) -> Vec<u64> {
    version.trim_start_matches('v').split('.').map(|part| part.parse().unwrap_or(0)).collect()
}

fn is_newer(candidate: &str, current: &str) -> bool {
    version_numbers(candidate) > version_numbers(current)
}

fn installed() -> bool {
    std::env::current_exe().is_ok_and(|exe| exe.with_file_name(UNINSTALLER).exists())
}

fn newer_release(answer: ReleaseAnswer, current: &str, installable: bool) -> Option<Release> {
    let installer = answer.assets.into_iter().find(|asset| asset.name.to_lowercase().ends_with(INSTALLER_SUFFIX))?;
    is_newer(&answer.tag_name, current).then(|| Release {
        version: answer.tag_name.trim_start_matches('v').to_string(),
        notes_url: answer.html_url,
        installable,
        installer_url: installer.browser_download_url,
        size: installer.size,
        sha256: installer.digest.and_then(|digest| digest.strip_prefix(SHA256_PREFIX).map(str::to_lowercase)),
    })
}

fn client(timeout: Duration) -> Result<reqwest::Client> {
    Ok(reqwest::Client::builder().timeout(timeout).user_agent(USER_AGENT).build()?)
}

/// The latest GitHub release when it is newer than this app and ships an installer.
pub async fn check() -> Result<Option<Release>> {
    let answer: ReleaseAnswer =
        client(CHECK_TIMEOUT)?.get(LATEST_RELEASE).header(reqwest::header::ACCEPT, GITHUB_JSON).send().await?.error_for_status()?.json().await?;
    Ok(newer_release(answer, CURRENT_VERSION, installed()))
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

/// Downloads the installer into `dir`, reporting the share done (0-1), and checks it against the published SHA-256.
pub async fn download(release: &Release, dir: &Path, mut progress: impl FnMut(f64)) -> Result<PathBuf> {
    std::fs::create_dir_all(dir)?;
    let path = dir.join(format!("OfficeGo-{}{INSTALLER_SUFFIX}", release.version));
    let mut response = client(DOWNLOAD_TIMEOUT)?.get(&release.installer_url).send().await?.error_for_status()?;
    let mut file = std::fs::File::create(&path)?;
    let mut hash = Sha256::new();
    let mut received = 0u64;
    while let Some(chunk) = response.chunk().await? {
        file.write_all(&chunk)?;
        hash.update(&chunk);
        received += chunk.len() as u64;
        progress(received as f64 / release.size.max(1) as f64);
    }
    file.flush()?;
    drop(file);
    let intact = received == release.size && release.sha256.as_deref().is_none_or(|expected| hex(&hash.finalize()) == expected);
    if !intact {
        std::fs::remove_file(&path)?;
        return Err(AppError::BadDownload);
    }
    Ok(path)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn answer(tag: &str, asset: &str) -> ReleaseAnswer {
        serde_json::from_value(json!({
            "tag_name": tag,
            "html_url": "https://github.com/MariaDSalazar/officego/releases/tag/v2.4.0",
            "assets": [
                { "name": "OfficeGo-portable.exe", "browser_download_url": "https://example.com/portable", "size": 1, "digest": null },
                { "name": asset, "browser_download_url": "https://example.com/installer", "size": 3, "digest": "sha256:ABC" }
            ]
        }))
        .unwrap()
    }

    #[test]
    fn offers_only_newer_releases_with_an_installer() {
        assert!(is_newer("v2.10.0", "2.9.9"));
        assert!(is_newer("v2.4.0", "2.3"));
        assert!(!is_newer("v2.4.0", "2.4.0"));
        assert!(!is_newer("v2.3", "2.4.0"));
        let release = newer_release(answer("v2.5.0", "OfficeGo-setup.exe"), "2.4.0", true).unwrap();
        assert_eq!(
            (release.version.as_str(), release.installer_url.as_str(), release.sha256.as_deref()),
            ("2.5.0", "https://example.com/installer", Some("abc"))
        );
        assert!(newer_release(answer("v2.5.0", "OfficeGo.ps1"), "2.4.0", true).is_none());
        assert!(newer_release(answer("v2.4.0", "OfficeGo-setup.exe"), "2.4.0", true).is_none());
    }
}
