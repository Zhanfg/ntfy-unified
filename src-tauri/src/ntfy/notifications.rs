#[cfg(desktop)]
use crate::automation::engine::handle_notification;
#[cfg(desktop)]
use crate::automation::matcher::AutomationEvent;
use crate::db::{DbState, models::DayKey, repo, run};
use crate::ntfy::models::{Message, Topic};

use chrono::{Datelike, Local, Timelike, Weekday};
use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_notification::NotificationExt;

pub(crate) async fn process_notification(
    app: &AppHandle,
    topic: &Topic,
    message: &Message,
) -> Result<(), String> {
    let id = topic.id.clone();

    let stored = message.clone();

    let fresh = run(app.state::<DbState>(), move |connection| {
        repo::ntfy::receive(connection, &id, &stored)
    })
    .await?;

    if !fresh {
        super::diagnostics::stage("receipt_duplicate_no_notification");
        return Ok(());
    }

    super::diagnostics::stage("receipt_stored");
    let _ = app.emit("ntfy:changed", ());

    if message.event != "message" {
        super::diagnostics::stage("non_message_event_no_notification");
        return Ok(());
    }

    if topic.muted {
        super::diagnostics::stage("notification_suppressed_muted");
    } else if should_show_notification(app).await? {
        let preview = run(app.state::<DbState>(), |connection| {
            Ok(repo::ntfy::meta(connection, "notification_preview")?.as_deref() == Some("1"))
        })
        .await?;

        super::diagnostics::stage(if preview {
            "notification_attempt_preview_on"
        } else {
            "notification_attempt_preview_off"
        });

        let (display_title, display_body) = notification_content(message, preview);
        let builder = app
            .notification()
            .builder()
            .title(display_title)
            .body(display_body);

        if builder.show().is_err() {
            super::diagnostics::stage("notification_native_error");
            let _ = app.emit(
                "ntfy:delivery-error",
                "Native notification delivery failed. Check operating system permissions.",
            );
        } else {
            super::diagnostics::stage("notification_native_accepted");
        }
    } else {
        super::diagnostics::stage("notification_suppressed_schedule");
    }

    #[cfg(desktop)]
    if let Err(_error) = handle_notification(
        app,
        AutomationEvent {
            topic: message.topic.clone(),
            title: message.title.clone(),
            message: message.message.clone(),
        },
    )
    .await
    {
        let _ = app.emit(
            "ntfy:delivery-error",
            "An automation failed. Review the encrypted automation logs.",
        );
    }

    Ok(())
}

async fn should_show_notification(app: &AppHandle) -> Result<bool, String> {
    let schedule = run(app.state::<DbState>(), repo::get_schedule).await?;

    if !schedule.schedule_enabled {
        return Ok(true);
    }

    let now = Local::now();

    let day_key = match now.weekday() {
        Weekday::Mon => DayKey::Monday,
        Weekday::Tue => DayKey::Tuesday,
        Weekday::Wed => DayKey::Wednesday,
        Weekday::Thu => DayKey::Thursday,
        Weekday::Fri => DayKey::Friday,
        Weekday::Sat => DayKey::Saturday,
        Weekday::Sun => DayKey::Sunday,
    };

    let Some(day) = schedule.days.get(&day_key) else {
        return Ok(false);
    };

    if !day.enabled {
        return Ok(false);
    }

    let current = now.hour() * 60 + now.minute();

    let start = repo::time_to_minutes(&day.start_time)
        .ok_or_else(|| "Invalid schedule start time".to_string())?;

    let end = repo::time_to_minutes(&day.end_time)
        .ok_or_else(|| "Invalid schedule end time".to_string())?;

    Ok(current >= u32::from(start) && current < u32::from(end))
}

fn notification_content<'a>(message: &'a Message, preview: bool) -> (&'a str, &'a str) {
    if preview {
        let title = message
            .title
            .as_deref()
            .filter(|title| !title.is_empty())
            .unwrap_or(&message.topic);
        (title, &message.message)
    } else {
        ("Ntfy", "New notification. Open Ntfy to view it.")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_message() -> Message {
        serde_json::from_value(serde_json::json!({
            "id": "synthetic-id",
            "time": 1,
            "event": "message",
            "topic": "synthetic-topic",
            "title": "Synthetic title",
            "message": "Synthetic body"
        }))
        .unwrap()
    }

    #[test]
    fn preview_off_remains_generic_and_private() {
        let message = sample_message();
        assert_eq!(
            notification_content(&message, false),
            ("Ntfy", "New notification. Open Ntfy to view it.")
        );
    }

    #[test]
    fn preview_on_shows_payload_without_changing_eligibility() {
        let message = sample_message();
        assert_eq!(
            notification_content(&message, true),
            ("Synthetic title", "Synthetic body")
        );
    }
}
