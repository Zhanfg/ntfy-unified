//! Minimal Android-native system-bar bridge; no network or credential access.
use tauri::{plugin::{Builder, PluginHandle, TauriPlugin}, Manager, Wry};

pub(crate) struct AppearanceState(pub PluginHandle<Wry>);

pub(crate) fn init() -> TauriPlugin<Wry> {
    Builder::<Wry>::new("appearance")
        .setup(|app, api| {
            let handle = api.register_android_plugin(
                "cc.axymorrsen.ntfyunified",
                "AppearancePlugin",
            )?;
            app.manage(AppearanceState(handle));
            Ok(())
        })
        .build()
}
