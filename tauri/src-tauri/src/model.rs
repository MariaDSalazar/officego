use serde::{Deserialize, Serialize};
use ts_rs::TS;

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Catalog {
    pub products: Vec<Product>,
    pub editions: Vec<Edition>,
    pub apps: Vec<OfficeApp>,
    pub add_ons: Vec<AddOn>,
    pub add_on_weight_gb: f64,
    /// Office language codes, like `es-es`.
    pub languages: Vec<String>,
    pub minimum_free_gb: f64,
    /// Where the engine leaves `setup.exe`, the configuration and Microsoft's logs.
    pub work_folder: String,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Product {
    pub key: String,
    pub name: String,
    pub abbreviation: String,
    pub color: String,
    pub route: Route,
    pub channel: String,
    pub weight_gb: f64,
    /// The oldest Windows build this version installs on.
    pub minimum_build: u32,
    pub editions: Vec<String>,
}

/// How Microsoft delivers a product: the Deployment Tool can leave apps out, Click-to-Run setup installs the whole suite.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum Route {
    Odt,
    C2r,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct Edition {
    pub key: String,
    pub name: String,
    pub apps: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct OfficeApp {
    pub key: String,
    pub name: String,
    pub abbreviation: String,
    pub color: String,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct AddOn {
    pub key: String,
    pub name: String,
    pub abbreviation: String,
    pub color: String,
    pub products: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct MachineReport {
    pub machine: Machine,
    pub graphics: Graphics,
    pub office: Option<InstalledOffice>,
    pub recommendation: Recommendation,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Machine {
    pub os: String,
    pub build: String,
    pub supported: bool,
    pub architecture: String,
    pub bits: String,
    pub powershell: String,
    pub cpu: String,
    pub cpu_ghz: f64,
    pub cores: u32,
    pub threads: u32,
    pub cpu_load: u32,
    pub ram_gb: f64,
    pub ram_free_gb: f64,
    pub ram_load: u32,
    pub ram_modules: u32,
    pub ram_speed: String,
    pub gpu: String,
    pub resolution: String,
    pub admin: bool,
    /// Whether real-time protection is on; unknown when Defender does not answer.
    pub defender: Option<bool>,
    pub disks: Vec<Disk>,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Disk {
    pub letter: String,
    pub total_gb: f64,
    pub free_gb: f64,
    pub used_percent: u32,
    pub system: bool,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct Graphics {
    pub brand: GraphicsBrand,
    pub color: String,
    pub abbreviation: String,
    /// Too old or without its own driver for Office's hardware acceleration.
    pub old: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum GraphicsBrand {
    Nvidia,
    Amd,
    Intel,
    NoDriver,
    Other,
    Unknown,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct InstalledOffice {
    pub products: String,
    pub version: String,
    pub language: String,
    pub architecture: String,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct Recommendation {
    pub product: String,
    pub reason: RecommendationReason,
    pub supported: bool,
    pub warnings: Vec<Warning>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum RecommendationReason {
    Latest,
    Win10Before22H2,
    Win10Early,
    BeforeWin10,
    LowMemory,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct Warning {
    pub level: WarningLevel,
    pub code: WarningCode,
    pub values: WarningValues,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum WarningLevel {
    Info,
    Warn,
    Error,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub enum WarningCode {
    LowMemory,
    Windows32,
    LowDisk,
    OldGraphics,
    DefenderOn,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase", default)]
pub struct WarningValues {
    pub ram_gb: Option<f64>,
    pub free_gb: Option<f64>,
    pub drive: Option<String>,
    pub minimum_gb: Option<f64>,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct License {
    pub activated: bool,
    pub name: String,
}

/// What to install: catalog keys, an Office language code and the apps and add-ons to include.
#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct Selection {
    pub product: String,
    pub edition: String,
    pub language: String,
    pub bits: String,
    pub apps: Vec<String>,
    pub add_ons: Vec<String>,
}
