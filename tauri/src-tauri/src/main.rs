#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod engine;
mod errors;
mod model;
mod updates;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .invoke_handler(tauri::generate_handler![
            commands::catalog,
            commands::machine,
            commands::license,
            commands::configuration,
            commands::run_task,
            commands::stop_task,
            commands::relaunch_as_admin,
            commands::open_folder,
            commands::check_update,
            commands::install_update,
        ])
        .run(tauri::generate_context!())
        .expect("OfficeGo window");
}

#[cfg(test)]
mod tests {
    use serde_json::Value;
    use std::{collections::BTreeSet, fs, path::Path};

    const BASE_LANGUAGE: &str = "es";

    fn keys(value: &Value, prefix: &str, found: &mut BTreeSet<String>) {
        match value.as_object() {
            Some(object) => object.iter().for_each(|(key, child)| keys(child, &format!("{prefix}{key}."), found)),
            None => {
                found.insert(prefix.trim_end_matches('.').to_string());
            }
        }
    }

    fn language_keys(folder: &Path) -> BTreeSet<String> {
        let mut found = BTreeSet::new();
        for file in fs::read_dir(folder).unwrap().map(|entry| entry.unwrap().path()) {
            let namespace = file.file_stem().unwrap().to_string_lossy().to_string();
            keys(&serde_json::from_str(&fs::read_to_string(&file).unwrap()).unwrap(), &format!("{namespace}:"), &mut found);
        }
        found
    }

    fn invoked_commands(source: &str) -> Vec<String> {
        source
            .split("invoke")
            .skip(1)
            .filter_map(|call| call.split_once("('").and_then(|(head, rest)| (head.is_empty() || head.starts_with('<')).then_some(rest)))
            .filter_map(|rest| rest.split_once('\'').map(|(name, _)| name.to_string()))
            .collect()
    }

    #[test]
    fn every_command_the_ui_invokes_is_registered() {
        let services = Path::new(env!("CARGO_MANIFEST_DIR")).join("../src/lib/services");
        let registered = include_str!("main.rs").split_once("generate_handler![").unwrap().1.split_once(']').unwrap().0;
        let mut invoked = Vec::new();
        for file in fs::read_dir(services).unwrap().map(|entry| entry.unwrap().path()) {
            invoked.extend(invoked_commands(&fs::read_to_string(file).unwrap()));
        }
        assert!(invoked.len() >= 10, "only found {invoked:?}");
        for command in invoked {
            assert!(registered.contains(&format!("commands::{command},")), "the UI invokes '{command}', which main.rs does not register");
        }
    }

    #[test]
    fn every_language_has_the_base_keys() {
        let locales = Path::new(env!("CARGO_MANIFEST_DIR")).join("../locales");
        let base = language_keys(&locales.join(BASE_LANGUAGE));
        for language in fs::read_dir(&locales).unwrap().map(|entry| entry.unwrap().path()) {
            let found = language_keys(&language);
            let missing: Vec<_> = base.difference(&found).collect();
            assert!(missing.is_empty(), "{} lacks {missing:?}", language.display());
        }
    }
}
