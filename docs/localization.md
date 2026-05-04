# CSV Localization Layer

The localization layer keeps engine-facing data in English and adds translated display/search fields beside canonical fields.

## Verify Locally

Windows machines can verify the localization layer without installing Busted by using the bundled Lua runtime:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1
```

Hosted coding agents or Linux containers that do not have PowerShell can run the cloud-friendly static/sync verifier:

```bash
python3 tools/verify-localization-cloud.py
```

This does not replace the Windows runtime smoke test, but it is enough for cloud agents to validate CSV shape, synchronization with generated PoB data, sample translations, and canonical English preservation.

This checks Lua syntax for the localization touch points, then runs a standalone smoke test for:

- CSV synchronization with the current generated PoB data
- UTF-8 CSV parsing, BOM handling, quoted commas, and escaped quotes
- English fallback
- Korean display/search fields for a sample gem, item base, and passive tree node
- Canonical English keys staying unchanged

Busted verification can be requested explicitly when Busted is available on PATH:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1 -RunBusted
```

## Update CSV

Regenerate the managed Korean CSV files from current PoB data:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1
```

The update step preserves existing Korean translations and fills newly discovered entries with a machine draft based on the glossary in `tools/localization-lib.lua`.

When the glossary changes and the machine draft should be regenerated, use refresh mode:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Refresh
```

Check mode fails when current data and CSV are out of sync:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-localization-csv.ps1 -Check
```

Runtime localization logs can be enabled for development:

```powershell
$env:POB_LOG_LOCALIZATION = "1"
```

Docker-based Busted verification can be requested explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-localization.ps1 -RunDocker
```

## Full Test

The existing project test container still works as the full regression path when Docker Desktop is running:

```powershell
docker compose run --rm busted-tests busted --lua=luajit
```
