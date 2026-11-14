#[cfg(target_os = "android")]
pub mod appearance;
#[cfg(desktop)]
pub mod automation;
#[cfg(desktop)]
pub mod logs;
pub mod ntfy;
pub mod schedule;

#[cfg(desktop)]
pub fn handler() -> impl Fn(tauri::ipc::Invoke<tauri::Wry>) -> bool + Send + Sync + 'static {
    tauri::generate_handler![
        automation::get_rules,
        automation::create_rule,
        automation::update_rule,
        automation::delete_rule,
        automation::toggle_rule,
        automation::test_rule,
        logs::get_logs,
        ntfy::ntfy_snapshot,
        ntfy::ntfy_save_server,
        ntfy::ntfy_remove_server,
        ntfy::ntfy_subscribe,
        ntfy::ntfy_topic_display,
        ntfy::ntfy_update_display,
        ntfy::ntfy_update_topic,
        ntfy::ntfy_messages,
        ntfy::ntfy_message_action,
        ntfy::ntfy_publish,
        ntfy::ntfy_reconnect,
        ntfy::ntfy_preferences,
        ntfy::ntfy_open_url,
        ntfy::get_url,
        schedule::get_schedule,
        schedule::update_schedule,
    ]
}

#[cfg(mobile)]
pub fn handler() -> impl Fn(tauri::ipc::Invoke<tauri::Wry>) -> bool + Send + Sync + 'static {
    tauri::generate_handler![
        appearance::android_set_appearance,
        ntfy::ntfy_snapshot,
        ntfy::ntfy_save_server,
        ntfy::ntfy_remove_server,
        ntfy::ntfy_subscribe,
        ntfy::ntfy_topic_display,
        ntfy::ntfy_update_display,
        ntfy::ntfy_update_topic,
        ntfy::ntfy_messages,
        ntfy::ntfy_message_action,
        ntfy::ntfy_publish,
        ntfy::ntfy_reconnect,
        ntfy::ntfy_preferences,
        ntfy::ntfy_open_url,
        ntfy::get_url,
        schedule::get_schedule,
        schedule::update_schedule,
    ]
}
