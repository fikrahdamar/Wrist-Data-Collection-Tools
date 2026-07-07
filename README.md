# WristDataCollectionTools

Apple Watch + iPhone companion app for collecting labeled wrist motion data (accelerometer + gyroscope) — built for fall-detection / activity-recognition (ADL) dataset collection.

Record on the Watch → CSV is transferred automatically to the iPhone → export anywhere via the Share sheet.

## How It Works

```
┌─────────────── Apple Watch ───────────────┐      ┌────────────── iPhone ──────────────┐
│ Pick Subject (P1–P5) + Label (FALL/ADL)   │      │ Receives file via WCSession        │
│ Start → CoreMotion @ 100 Hz               │ ───▶ │ Saves to Documents/WristData/      │
│ Stop & Save → CSV → WCSession transfer    │      │ File list + ShareLink export       │
└───────────────────────────────────────────┘      └────────────────────────────────────┘
```

- **Watch app** (`WristDataCollectionToolsWatch Watch App/`)
  - `MotionRecorder.swift` — samples device motion at **100 Hz**, buffers in memory, writes CSV on stop, sends it to the phone with `WCSession.transferFile`.
  - `WatchContentView.swift` — subject picker, label picker, Start / Stop & Save, live sample counter.
- **iOS app** (`WristDataCollectionTools/`)
  - `PhoneSessionManager.swift` — receives files from the Watch, stores them in `Documents/WristData/`.
  - `PhoneContentView.swift` — lists received CSVs; tap any file to share (AirDrop, Files, email, …).

## Data Format

Filename: `<subject>_<label>_<unixTimestamp>.csv` (e.g. `P1_FALL-forward_1751871234.csv`)

| Column | Meaning | Unit |
|--------|---------|------|
| `t` | Time since recording start | seconds |
| `ax, ay, az` | Total acceleration (userAcceleration + gravity) | g |
| `gx, gy, gz` | Rotation rate | deg/s |

Built-in labels (edit the arrays at the top of `WatchContentView.swift` to change them):

- **Falls:** `FALL-forward`, `FALL-backward`, `FALL-lateral`, `FALL-slow`
- **ADL:** `ADL-walking`, `ADL-sit-down-fast`, `ADL-lie-down`, `ADL-pick-object`, `ADL-arm-move`

Subjects: `P1`–`P5` (same file, same idea — edit to add more).

## Requirements

- Xcode 15+
- iPhone running iOS 17+ and a **paired** Apple Watch running watchOS 10+
- An Apple ID (free account is enough for on-device development)

## First-Time Xcode Configuration

Setting up a Watch companion app for the first time is fiddly. These are the steps that matter:

### 1. Signing (both targets)

1. Open `WristDataCollectionTools.xcodeproj` in Xcode.
2. Select the project in the navigator → **Signing & Capabilities** tab.
3. For **both** targets (`WristDataCollectionTools` and `WristDataCollectionToolsWatch Watch App`):
   - Check **Automatically manage signing**.
   - Select your **Team** (add your Apple ID under Xcode → Settings → Accounts if it's not listed).

### 2. Bundle identifiers must match

The Watch app's bundle ID **must** be prefixed by the iOS app's bundle ID, or the pairing breaks:

| Target | Bundle Identifier |
|--------|-------------------|
| iOS app | `com.yourname.WristDataCollectionTools` |
| Watch app | `com.yourname.WristDataCollectionTools.watchkitapp` |

If you change one, change the other to match the pattern.

### 3. Motion usage permission

The Watch target's Info needs **`NSMotionUsageDescription`** (Privacy – Motion Usage Description) with any short text, e.g. *"Records wrist motion for dataset collection."* Without it, the app crashes silently when recording starts. (Already set in this repo — only relevant if you recreate the targets.)

### 4. Run on real devices

Simulators can't generate real motion data, so use hardware:

1. Plug in the iPhone (or use Wi-Fi debugging). The paired Watch appears in the device list automatically.
2. Select the **Watch scheme** (`WristDataCollectionToolsWatch Watch App`) → destination: your Apple Watch (shown *via* your iPhone) → Run.
   - First install to the Watch is slow (several minutes). Keep the Watch on its charger and unlocked to speed it up.
3. Select the **iOS scheme** → destination: your iPhone → Run.
4. On first launch of each app, trust the developer certificate if prompted: **Settings → General → VPN & Device Management** (on the iPhone; the Watch inherits it).

### Common pitfalls

- **"Watch app not installing"** — open the Watch app on the iPhone, scroll to *Available Apps*, and install it from there; or reboot both devices (fixes most pairing weirdness).
- **Files not arriving on the phone** — `WCSession.transferFile` is opportunistic. Keep both apps installed and Bluetooth on; transfer can take from seconds up to a couple of minutes. Files queue and survive reboots.
- **Free Apple ID provisioning expires after 7 days** — just re-run from Xcode to re-sign.

## Usage

1. **On the Watch:** pick a subject and a label, tap **Start**.
2. Perform the movement (the screen shows `● REC` and a live sample count).
3. Tap **Stop & Save**. The CSV is written and queued for transfer; the filename appears with a ✓.
4. **On the iPhone:** open the app — received files appear in the list automatically (bring the app to the foreground if the list looks stale).
5. Tap a file to export it via the Share sheet (AirDrop, Files, Drive, email, …).

## Loading the Data (Python)

```python
import pandas as pd

df = pd.read_csv("P1_FALL-forward_1751871234.csv")
# columns: t, ax, ay, az (g), gx, gy, gz (deg/s) — sampled at 100 Hz
```

## Project Structure

```
WristDataCollectionTools/
├── WristDataCollectionTools/               # iOS companion app
│   ├── WristDataCollectionToolsApp.swift
│   ├── PhoneContentView.swift              # file list + ShareLink export
│   └── PhoneSessionManager.swift           # WCSession receiver → Documents/WristData
└── WristDataCollectionToolsWatch Watch App/ # watchOS app
    ├── WristDataCollectionToolsWatchApp.swift
    ├── WatchContentView.swift              # subject/label pickers + record UI
    └── MotionRecorder.swift                # CoreMotion @100 Hz → CSV → WCSession
```
