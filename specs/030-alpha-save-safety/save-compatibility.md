# Save Compatibility Notes

External alpha saves start at schema version `1` and build version `0.1.0-alpha+20260627.1`.

Save files are supported when their `schema_version` is between `1` and the current `SaveGameService.FORMAT_VERSION`. Older payloads that only include `format_version` still load through the same guard. Future unsupported saves must fail with `unsupported_format_version` and leave existing garden state unchanged.

Tester bug reports should include the version shown in the settings menu and, when relevant, whether the issue happened after desktop close/reopen, Web reload, or Android background/resume.

Web reload persistence is verified by `031-itch-web-alpha`. Android background/resume persistence is verified by `032-android-alpha`.
