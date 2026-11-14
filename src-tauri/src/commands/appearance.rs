#[tauri::command]
pub fn android_set_appearance(app: tauri::AppHandle, dark: bool) -> Result<(), String> {
    use tauri::Manager;

    let state = app.state::<crate::appearance::AppearanceState>();
    state.0.run_mobile_plugin::<()>(
        "setAppearance",
        serde_json::json!({ "dark": dark }),
    ).map_err(|_| "Cannot update Android system bar appearance".to_string())
}
