//! Opt-in delivery breadcrumbs. Never print URLs, topics, tokens or message bodies.
pub(crate) fn stage(stage: &'static str) {
    if std::env::var_os("NTFY_UNIFIED_DIAGNOSTICS").as_deref()
        != Some(std::ffi::OsStr::new("1"))
    {
        return;
    }

    let epoch_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|duration| duration.as_millis())
        .unwrap_or(0);
    eprintln!("ntfy-diag ts_ms={epoch_ms} stage={stage}");
}
