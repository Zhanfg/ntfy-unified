use tauri::AppHandle;
use tauri_plugin_window_state::{AppHandleExt, StateFlags};

pub mod system;

pub fn exit_app(app: &tauri::AppHandle) {
    let _ = app.save_window_state(StateFlags::SIZE | StateFlags::POSITION);

    app.exit(0);
}
