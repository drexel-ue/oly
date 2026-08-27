# OLY — Olympic Weightlifting & Periodization Tracker

<p align="center">
  <img src="assets/icon/icon.jpg" width="140" alt="OLY App Icon" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);" />
</p>

<p align="center">
  <b>A modern, high-contrast Flutter application designed for Olympic weightlifting athletes, coaches, and strength enthusiasts.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS-4E8EF7" alt="Platform" />
  <img src="https://img.shields.io/badge/Theme-Dark%20Obsidian-121214" alt="Theme" />
  <img src="https://img.shields.io/badge/Tests-51%20Passing-brightgreen" alt="Tests" />
  <img src="https://img.shields.io/badge/License-Proprietary-FF9E1B" alt="License" />
</p>

---

## 🌟 Overview

**OLY** is engineered specifically for the demands of Olympic weightlifting (Snatch, Clean & Jerk, and Squats). It integrates dynamic 4-Day and 5-Day periodization programming, real-time working percentage calculation (`65% → 70% → 75% → 70% → Retest`), movement video tutorials, an intelligent rest timer with lock-screen alerts, an IWF color-coded bumper plate calculator, Greg Everett / Catalyst Athletics 1RM variation ratios, in-workout exercise variation swapping, working weight adjustment with live 1RM recalculation, an adaptive active recovery generator, and native data backup into a sleek, dark-mode mobile experience.

---

## 📱 Visual Feature Tour

| Home Dashboard | Live Workout Session |
| :---: | :---: |
| <img src="screenshots/01_dashboard_screen.png" width="360" alt="Home Dashboard" /> | <img src="screenshots/09_workout_session_screen.png" width="360" alt="Live Workout Session" /> |
| *Cycle periodization, workout selector, and quick recovery trigger* | *Set checklist, live rest timer, and working weight banner* |

| Movement Variation Swaps | Weight Adjustment & 1RM Recalculator |
| :---: | :---: |
| <img src="screenshots/10_workout_swap_modal.png" width="360" alt="Movement Variation Swaps" /> | <img src="screenshots/11_workout_weight_dialog.png" width="360" alt="Weight Adjustment & 1RM Recalculator" /> |
| *Segmented Suggested Swaps vs Other Movements with live target weights* | *Tune working weight and auto-recalculate baseline 1RM* |

| Active Recovery Routine | Guided Olympic Warm-Up |
| :---: | :---: |
| <img src="screenshots/12_recovery_session_screen.png" width="360" alt="Active Recovery Routine" /> | <img src="screenshots/08_warmup_session_screen.png" width="360" alt="Guided Olympic Warm-Up" /> |
| *Multi-phase mobility flow adapted from joint strain feedback* | *Multi-phase warm-up drills with video guides and form cues* |

| Lift Catalog & Percentages | Olympic Ratio Balance |
| :---: | :---: |
| <img src="screenshots/02_lifts_matrix_screen.png" width="360" alt="Lift Catalog" /> | <img src="screenshots/03_lift_ratios_screen.png" width="360" alt="Olympic Ratio Balance" /> |
| *1RM baselines with expanded 50%–105% percentage matrix* | *Benchmark targets & diagnostic balance analysis* |

| Barbell Plate Loader | Training Analytics & Logs |
| :---: | :---: |
| <img src="screenshots/05_plate_calculator_screen.png" width="360" alt="Barbell Plate Loader" /> | <img src="screenshots/07_analytics_screen.png" width="360" alt="Training Analytics" /> |
| *IWF color-coded bumper plates and per-side breakdown* | *Total tonnage moved, completed workouts, sets, and reps* |

| 1RM Retest Assistant | Olympic Ratio Standards Sheet |
| :---: | :---: |
| <img src="screenshots/06_max_test_screen.png" width="360" alt="1RM Retest Assistant" /> | <img src="screenshots/04_standard_ratios_sheet.png" width="360" alt="Olympic Ratio Standards Sheet" /> |
| *Week 5 Max Test protocol, warmup jumps, and opener targets* | *Catalyst Athletics ideal ratio reference standards* |

---

## 🚀 Comprehensive Feature Breakdown

### 🏋️‍♂️ 1. Structured Periodization Engine (4-Day & 5-Day Sequences)
- **Periodized Wave Loading**: Automatically calculates target weights for every working set based on your 1RMs and current cycle week:
  - **Week 1 (Base Loading)**: ~65% target intensity
  - **Week 2 (Loading)**: ~70% target intensity
  - **Week 3 (Peak Loading)**: ~75% target intensity
  - **Week 4 (Deload & Priming)**: ~70% reduced volume
  - **Week 5 (1RM Retest)**: Dedicated testing protocol with guided warmup ramps
- **Program Flexibility**: Toggle between **4-Day Strength & Technique** and **5-Day Classical Sequence** in Settings.
- **Preview & Exploration Mode**: Explore and review any past or future week/routine without modifying active cycle state or polluting analytics logs.

### ⏱️ 2. Live Workout Session Companion
- **Set & Rep Tracking**: Interactive set completion pills with real-time weight overrides and rep adjustments.
- **Working Weight Banner & Quick Recalculator**: Prominent banner showing current exercise working weight with one-tap access to the adjustment dialog.
- **Movement Video Links**: Tap the video icon on any exercise card to instantly watch curated YouTube coaching tutorials for that exact movement.
- **Quick Plate Calculator**: Tap the barbell icon on any exercise card to calculate exact plate loading for that specific exercise target weight.
- **Post-Workout Diagnostics**: Rate session RPE (1–10) and tag joint strain areas (e.g., Shoulders, Knees, Wrists) upon completion to adapt your next recovery routine.

### 🔄 3. Smart In-Workout Movement Swaps
- **Suggested Swaps Segmentation**: Automatically identifies direct variations within the same movement pattern family (e.g., Power Snatch, Hang Snatch, Muscle Snatch for Snatch variations) and displays them at the top of the swap sheet.
- **Other Movements**: Search and select from any Olympic lift or accessory in the catalog.
- **Dynamic Weight Recalculation**: Swapped exercises automatically calculate target working weight based on the replacement exercise's 1RM and current week's periodization percentage.
- **One-Tap Reset**: Easily restore original prescribed exercises at any time.

### ⚖️ 4. In-Workout Weight Adjustment & 1RM Recalculator
- **Live 1RM Reverse Calculation**: When adjusting your working weight during a session, Oly automatically reverse-calculates what your estimated 1RM is based on current week's periodization formula ($1\text{RM} = \text{Working Weight} / \% \text{Periodization}$).
- **Quick Steppers**: Instant `-5.0`, `-2.5`, `-1.0`, `+1.0`, `+2.5`, `+5.0` buttons for fast barbell adjustments.
- **Delta Comparison**: Real-time badge indicating change vs. current PR (e.g., `+5 kg vs PR`).
- **Flexible Save Options**:
  - **Weight Only**: Adjusts working sets for the current workout without altering your baseline PR.
  - **Update & Recalc 1RM**: Updates working weight and updates your official 1RM catalog with an audit history note.

### ⏳ 5. Intelligent Rest Timer
- **Quick Presets**: Fast 30s, 60s, 90s, 2m, 3m, and 5m rest duration presets.
- **Micro-Adjustments**: Fine-tune timer on the fly with `-10s`, `-5s`, `-1s`, `+1s`, `+5s`, `+10s` step buttons.
- **Audio & Haptic Alerts**: Multi-stage audio beeps and vibration feedback upon timer expiration.
- **Lock-Screen Local Notifications**: Background notifications ensure you never miss rest expiration when your phone screen turns off or when switching apps.

### 🧘‍♂️ 6. Adaptive Active Recovery & Mobility Engine
- **Targeted Routine Generation**: 12 structured drills across 5 dedicated phases:
  - **Phase 1**: Zone 2 Aerobic Conditioning & Warmup
  - **Phase 2**: Mobility & Joint Health Flow (Thoracic extension, Hip openers, Ankle dorsiflexion, Wrists)
  - **Phase 3**: Arms & Upper Body Hypertrophy
  - **Phase 4**: Core & Abs Stability
  - **Phase 5**: Grip Strength
- **Strain Adaptation**: Automatically prioritizes mobility drills targeting joints flagged during previous workout logs.
- **Daily Readiness Scoring**: Log 5-star readiness assessments to calibrate daily intensity.

### 💡 7. Catalyst Athletics Olympic 1RM Variation Ratios
- **Automated Ratio Calculations**: Built-in benchmark targets derived from Greg Everett Olympic standards:
  - **Hang Snatch**: 88% of Snatch
  - **Power Snatch**: 82% of Snatch
  - **Overhead Squat**: 110% of Snatch
  - **Hang Clean**: 88% of Clean & Jerk
  - **Power Clean**: 85% of Clean & Jerk
  - **Block Clean**: 90% of Clean & Jerk
  - **Front Squat**: 85% of Back Squat
  - **Push Press**: 75% of Clean & Jerk
- **One-Tap Suggestion Chips**: Auto-fill variation 1RMs calculated directly from your primary lifts.
- **Ratio Balance Diagnostic**: Identifies whether technique, pulling power, or leg strength is your limiting factor.

### 🔴 8. Visual IWF Barbell Bumper Plate Loader
- **Realistic Barbell Rendering**: Visually renders standard IWF colored bumper plates loaded on the sleeve:
  - 🔴 **25 kg / 45 lb** (Red)
  - 🔵 **20 kg / 35 lb** (Blue)
  - 🟡 **15 kg / 25 lb** (Yellow)
  - 🟢 **10 kg / 10 lb** (Green)
  - ⚪ **5 kg** (White Bumper)
  - ⚪ **Fractionals**: 2.5 kg, 2.0 kg, 1.5 kg, 1.0 kg, 0.5 kg
- **Customizable Equipment**: Switch between Men's 20kg bar, Women's 15kg bar, 10kg Technique bar, 45lb bar, and collar configurations (2.5kg competition collars or collarless).

### 📈 9. Lifetime Volume & Tonnage Analytics
- **Total Workload Calculation**: Multiplies `weight × reps` across all completed sets.
- **Metric & Imperial Support**: View total workload in **Metric Tonnes** ($1{,}000\text{ kg}$) or **US Short Tons** ($2{,}000\text{ lbs}$).
- **Historical Logs**: Comprehensive session breakdown with dates, RPE ratings, joint strain tags, and completed exercise sets.

### 💾 10. Native Backup, Export & Import
- **JSON Full Backup**: One-tap export and import of all user preferences, 1RMs, cycle history, and workout logs.
- **CSV Log Export**: Export human-readable spreadsheet-compatible workout logs for external analysis or coach review.

---

## 📸 Automated Screenshot Capture Pipeline

OLY includes an automated screenshot capture system built with Flutter's `integration_test` and `flutter drive`, powered by realistic mock data:

```bash
# Run automated screenshot capture on iOS Simulator
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_test.dart -d "iPhone Air"
```

Launch configurations are also included in `.vscode/launch.json` for one-click execution from Antigravity IDE and VS Code.

---

## ⚠️ Known Issues & Platform Considerations

### iOS Background Audio & Lock-Screen Notifications
- **Behavior**: On iOS, when the device is locked or the application is in the background, Apple's `AVAudioEngine` / `caulk` audio pipeline is placed into a suspended state by iOS CoreAudio. Attempting to trigger arbitrary in-app audio synthesizer playback during a resume race condition can lead to an iOS watchdog termination.
- **Implementation Design**: 
  - Rest timer expiration when the app is in the background is delivered reliably via native iOS `UNUserNotificationCenter` local notifications (`DarwinNotificationDetails` with system alert sound).
  - In-app audio player playback and tactile haptic sequences are reserved for active foreground use. If you return to the app after the timer has finished in the background, the UI updates gracefully without attempting an unsafe late audio playback.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── main.dart                        # Application root & multi-provider wiring
├── theme/
│   └── app_theme.dart               # Dark Obsidian (#121214) & Neon Amber (#FF9E1B) design system
├── models/
│   ├── lift_model.dart              # Lift definitions & Olympic variation ratio math
│   ├── program_model.dart           # 4-Day & 5-Day periodization templates & week loaders
│   ├── workout_session.dart         # Workout session logs, RPE, and strain models
│   ├── mobility_exercise_model.dart # Active recovery exercises with cues & video links
│   └── plate_calc.dart              # Barbell sleeve greedy plate allocation algorithm
├── providers/
│   ├── lift_provider.dart           # 1RM catalog & ratio balance calculations
│   ├── program_provider.dart        # Periodization cycle progression & week advancement
│   ├── recovery_provider.dart       # Recovery routine generation & readiness tracking
│   └── settings_provider.dart       # Units (kg/lbs), bar specs, audio/haptic toggles
├── services/
│   ├── storage_service.dart         # Local persistence, JSON/CSV backup & restore
│   ├── notification_service.dart    # Timezone-aware local notifications & foreground audio
│   ├── recovery_engine_service.dart # Adaptive mobility routine generator
│   └── warmup_engine_service.dart   # Dynamic warmup generator
├── views/
│   ├── splash_screen.dart           # Animated launch splash
│   ├── dashboard_screen.dart        # Main hub with cycle status & workout launchers
│   ├── workout_session_screen.dart  # Live workout tracking, rest timer, weight adjust & swap
│   ├── recovery_session_screen.dart # Interactive 5-phase mobility routine
│   ├── warmup_session_screen.dart   # Guided warm-up sequence with video drills
│   ├── lifts_screen.dart            # 1RM catalog & Olympic variation standards
│   ├── plate_calculator_screen.dart # Barbell plate visualizer & specs
│   ├── max_test_screen.dart         # Week 5 1RM retest protocol
│   └── analytics_screen.dart        # Total tonnage, workout history, & ratio charts
└── widgets/
    ├── barbell_visualizer.dart      # CustomPainted IWF bumper plate rendering
    ├── exercise_swap_modal.dart     # Segmented exercise swap modal (Suggested vs Other)
    ├── workout_weight_dialog.dart   # Working weight adjust & 1RM recalculator dialog
    ├── rest_timer_widget.dart       # Timer dial, micro-steppers, and alert dispatcher
    ├── video_player_card.dart       # YouTube thumbnail preview & coaching link launcher
    ├── warm_up_modal.dart           # Dynamic warm-up modal sheet
    └── standard_ratios_sheet.dart   # Catalyst Athletics ratio benchmarks table
```

---

## 💻 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.13.0` or later
- **Dart SDK**: `^3.0.0` or later
- **Xcode**: 15+ (for iOS development & simulator testing)
- **CocoaPods**: Latest

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/drexel-ue/oly.git
   cd oly
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code analysis & automated tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch on connected device or iOS Simulator**:
   ```bash
   # Launch on iOS Simulator
   flutter run -d iPhone

   # Launch directly to a specific tab (0=Home, 1=Lifts, 2=Loader, 3=MaxTest, 4=Analytics)
   flutter run --dart-define=TAB=1

   # Launch directly into a workout session
   flutter run --dart-define=SCREEN=workout
   ```

---

## 📄 Testing

Run the full suite of unit, widget, and domain engine tests:
```bash
flutter test
```

Test coverage includes:
- `exercise_swap_test.dart`: Movement substitution, variation categorization, and weight recalculation.
- `workout_weight_recalculation_test.dart`: In-workout weight adjustment, 1RM reverse formulas, steppers, and save modes.
- `screenshot_capture_test.dart`: Multi-screen layout and mock data rendering verification across 12 views.
- `feature_audit_test.dart`: Session serialization, RPE, joint strain tags, recovery adaptation, and JSON/CSV backup.
- `plate_calculator_test.dart`: Greedy plate allocation algorithm across kg/lb configurations.
- `percentage_calculator_test.dart`: Working weight calculation and rounding rules across periodization weeks.
- `recovery_engine_test.dart`: Adaptive mobility exercise selection and strain focus algorithms.

---

## 📝 License

Developed for Olympic weightlifters, coaches, and strength athletes.
Copyright © 2026 Lamont Labs. All rights reserved.
