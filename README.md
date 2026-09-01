# OLY — Olympic Weightlifting, Periodization & Metabolic Nutrition Tracker

<p align="center">
  <img src="assets/icon/icon.jpg" width="140" alt="OLY App Icon" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);" />
</p>

<p align="center">
  <b>A comprehensive, high-contrast Flutter application engineered for Olympic weightlifters, strength athletes, and coaches — integrating periodization programming, real-time TUT workout tracking, metabolic energy balance, 2M+ offline USDA & restaurant food database with FTS5 search, continuous barcode scanning, and on-device biometric scale OCR.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/SQLite-FTS5%20Engine-003B57?logo=sqlite&logoColor=white" alt="SQLite FTS5" />
  <img src="https://img.shields.io/badge/USDA%20FoodData-2.06M%20Items-005E36?logo=usda&logoColor=white" alt="USDA FoodData Central" />
  <img src="https://img.shields.io/badge/Open%20Food%20Facts-SDK%20v3-00B259?logo=openfoodfacts&logoColor=white" alt="Open Food Facts SDK" />
  <img src="https://img.shields.io/badge/Google%20ML%20Kit-OCR%20Vision-4285F4?logo=google&logoColor=white" alt="ML Kit Vision" />
  <img src="https://img.shields.io/badge/Theme-Dark%20Obsidian-121214" alt="Theme" />
  <img src="https://img.shields.io/badge/Tests-183%20Passing-brightgreen" alt="Tests" />
  <img src="https://img.shields.io/badge/License-Proprietary-FF9E1B" alt="License" />
</p>

---

## 🌟 Overview

**OLY** unites elite Olympic weightlifting periodization with a rigorous athlete nutrition engine, metabolic expenditure modeling, an offline-first **Anatomical Body Map & Biomechanical Injury Adaptation Engine**, a **Guided Wim Hof Breathwork & Retention Analytics Suite**, and a complete **2.06M+ item USDA & Restaurant SQLite database with FTS5 token search**. Designed from the ground up for serious athletes:

- **🏋️ Periodization & Lifts**: 4-Day and 5-Day wave loading programs (`65% → 70% → 75% → Deload → Retest`), Catalyst Athletics / Greg Everett 1RM variation ratios, dynamic in-workout exercise swapping, working weight & rep adjustments with live Epley 1RM recalculation, per-set fine-tuning, and an IWF color-coded bumper plate visualizer.
- **🌬️ Guided Wim Hof Breathwork & Retention Tracking**: Configurable 1–10 round breathing protocol, 20/30/40 breath counts, adjustable pacing (Relaxed, Normal, Fast), animated pulsing breathing orb, exhale breath hold stopwatch timer, 15-second recovery countdown, and dedicated **Breathwork Analytics** tracking retention progression over time via `fl_chart` LineCharts and round-by-round averages.
- **🥗 Complete Offline 2.06M+ USDA & Restaurant Database**: Embedded SQLite database (`usda_foods.db`) powered by FTS5 full-text indexing. Contains **Foundation Foods**, **SR Legacy**, **Survey Foods (FNDDS)**, **1.98M+ Branded products** with offline UPC barcode lookup, and curated menus across 26 major restaurant chains (McDonald's, Wingstop, Wendy's, Chick-fil-A, Chipotle, Starbucks, In-N-Out, Panda Express, Subway, Popeyes, Raising Cane's, Five Guys, Shake Shack, etc.).
- **🥞 Athlete Smart Portion Drawer**: Protein density index ($g\text{ protein} / 100\text{ kcal}$), 3-color macro split bar ($P\% / C\% / F\%$), standard serving steppers, and discrete piece-unit chips (`10 wings`, `6 nuggets`, `2 tacos`, `3 tenders`, `1 biscuit`, `1 patty`).
- **🩺 Body Map & Injury Adaptation**: Interactive 14-region Front & Back vector anatomical body map, OSIICS-16 local sports medicine taxonomy, duration-based **Acute ($< 14$d)** vs. **Subacute ($14-42$d)** vs. **Chronic ($> 42$d)** stage tracking, pre-session 1-tap biomechanical movement regressions, and post-session before-vs-after strain check-ins.
- **⚡ Nutrition & Metabolic Engine**: Dual Energy In / Energy Out balance gauge, Katch-McArdle LBM-based BMR calculation, Compendium of Physical Activities (Algorithm B net vs Algorithm A gross expenditure), automated WOD TUT physics calories sync, and dynamic daily hydration tracking.
- **📷 Smart Barcode Scanner & Open Food Facts**: Live camera viewfinder with golden animated targeting reticle, continuous scanning with haptic feedback, local SQLite offline UPC lookup with fallback to typed Open Food Facts SDK, and recent scanned pantry ribbons.
- **⚖️ Renpho Smart Scale OCR**: On-device text recognition extracting 13 biometric indicators directly from smart scale screenshots, visualized through an interactive Lean Mass vs. Fat Mass donut chart.
- **🛡️ Local Diagnostics & Crash Reporting**: Real-time in-memory ring buffer (250 logs), persistent crash log storage (50 crashes), global error interceptors, and an in-app diagnostics inspector with copy-all reporting.

---

## 📱 Visual Feature Tour

### 🌬️ Guided Wim Hof Breathwork & Retention Analytics

| Breathwork Setup & PRs | Live Guided Breathing (Pulsing Orb) |
| :---: | :---: |
| <img src="screenshots/24_wim_hof_setup_sheet.png" width="360" alt="Wim Hof Setup Sheet" /> | <img src="screenshots/25_wim_hof_session_screen.png" width="360" alt="Wim Hof Breathing Orb" /> |
| *Customizable 1–10 rounds, breath counts (20, 30, 40), pacing speeds, and all-time PR badge* | *Pulsing neon breathing orb with real-time cues (Inhale/Exhale) and live breath counter* |

| Breath Retention Stopwatch | Post-Session Completion Summary |
| :---: | :---: |
| <img src="screenshots/26_wim_hof_retention_screen.png" width="360" alt="Breath Retention Stopwatch" /> | <img src="screenshots/27_wim_hof_summary_screen.png" width="360" alt="Breathwork Summary" /> |
| *Upward stopwatch timer with milestone PR alerts and one-tap recovery transition* | *Round-by-round retention duration bars, PR celebration, and readiness rating* |

| Breathwork Retention Analytics Tab |
| :---: |
| <img src="screenshots/28_breathwork_analytics_tab.png" width="480" alt="Breathwork Analytics Tab" /> |
| *All-time KPI cards (Max PR, Total Time, Avg Hold), retention progression LineChart, and round-by-round breakdown* |

---

### 🥗 Nutrition & Metabolic Energy Balance

| Nutrition Dashboard (Top) | Nutrition Dashboard (Scrolled) |
| :---: | :---: |
| <img src="screenshots/14_nutrition_dashboard_screen.png" width="360" alt="Nutrition Dashboard Top" /> | <img src="screenshots/14_nutrition_dashboard_screen_scrolled.png" width="360" alt="Nutrition Dashboard Scrolled" /> |
| *Energy In vs Out gauge, net deficit/surplus, and Renpho body composition glance* | *Daily meal logs, Compendium activities & WOD energy, and quick hydration tracker* |

| Metabolic Science Explainer (Top) | Metabolic Science Explainer (Scrolled) |
| :---: | :---: |
| <img src="screenshots/15_metabolic_science_explainer_screen.png" width="360" alt="Metabolic Science Explainer Top" /> | <img src="screenshots/15_metabolic_science_explainer_screen_scrolled.png" width="360" alt="Metabolic Science Explainer Scrolled" /> |
| *Interactive 5-tab science reference: Energy & TDEE, Algorithm B vs A, and WOD physics* | *Katch-McArdle formula breakdown, MET math, and open-source scientific citations* |

---

### 📷 Live Barcode Scanner & Athlete Portion Drawer

| Live Camera Barcode Scanner | Athlete Smart Portion Drawer |
| :---: | :---: |
| <img src="screenshots/18_live_barcode_scanner_sheet.png" width="360" alt="Live Barcode Scanner" /> | <img src="screenshots/17_smart_portion_drawer.png" width="360" alt="Athlete Smart Portion Drawer" /> |
| *Continuous camera stream with golden reticle overlay, torch toggle, and recent scans ribbon* | *Protein density index, 3-color macro split bar, discrete piece chips (wings, nuggets, tenders), and steppers* |

| Food Search & Recent Pantry Items | Renpho Body Composition OCR Scanner |
| :---: | :---: |
| <img src="screenshots/16_food_search_sheet.png" width="360" alt="Food Search Sheet" /> | <img src="screenshots/19_renpho_scanner_sheet.png" width="360" alt="Renpho OCR Scanner" /> |
| *Instant zero-latency search across 2.06M+ USDA, Survey FNDDS, fast-food menus, and recent scans* | *13-field OCR parser from screenshot with Lean Mass vs Fat Mass donut visualizer* |

---

### 🏋️ Periodization & Live Workout Tracking

| Home Dashboard (Top) | Home Dashboard (Scrolled) |
| :---: | :---: |
| <img src="screenshots/01_dashboard_screen.png" width="360" alt="Home Dashboard Top" /> | <img src="screenshots/01_dashboard_screen_scrolled.png" width="360" alt="Home Dashboard Scrolled" /> |
| *Active cycle week, next prescribed workout, and one-tap recovery launcher* | *Current cycle calendar, weekly workout timeline, and recent session summaries* |

| Live Workout Session (Top) | Live Workout Session (Scrolled) |
| :---: | :---: |
| <img src="screenshots/09_workout_session_screen.png" width="360" alt="Live Workout Session Top" /> | <img src="screenshots/09_workout_session_screen_scrolled.png" width="360" alt="Live Workout Session Scrolled" /> |
| *Periodized target weight banner, warm-up trigger, and interactive set checklist* | *Accessory movements, live rest timer bar, and session notes* |

| Movement Variation Swaps | Weight & Rep Adjustment & 1RM Recalculator |
| :---: | :---: |
| <img src="screenshots/10_workout_swap_modal.png" width="360" alt="Movement Variation Swaps" /> | <img src="screenshots/11_workout_weight_dialog.png" width="360" alt="Weight Adjustment Dialog" /> |
| *Segmented Suggested Swaps vs Other Movements with live target weights* | *Tune working weight and reps, live Epley 1RM recalculation, and quick rep presets* |

---

### 🧘‍♂️ Active Recovery, Analytics & Diagnostics

| Interactive Anatomical Body Map | Clinical PDF & JSON Export |
| :---: | :---: |
| <img src="screenshots/21_injury_tracker_screen.png" width="360" alt="Body Map & Injury Tracker" /> | <img src="screenshots/23_injury_export_sheet.png" width="360" alt="Clinical PDF & JSON Export" /> |
| *14-region clickable body map, acute (<14d) vs chronic (6w+) tags, and OSIICS catalog* | *Multi-page clinical PDF report and structured raw JSON data backup* |

| Post-Session Strain Check-In | Active Recovery Routine |
| :---: | :---: |
| <img src="screenshots/22_post_session_body_checkin.png" width="360" alt="Post-Session Strain Check-In" /> | <img src="screenshots/12_recovery_session_screen.png" width="360" alt="Active Recovery Top" /> |
| *Before-vs-after session strain comparison modal and recovery sync* | *Adaptive 5-phase mobility flow generated from previous joint strain tags* |

| Guided Olympic Warm-Up | Mobility & Drill Swaps |
| :---: | :---: |
| <img src="screenshots/08_warmup_session_screen.png" width="360" alt="Guided Warm-Up" /> | <img src="screenshots/13_mobility_swap_modal.png" width="360" alt="Mobility Swaps" /> |
| *Dynamic warmup with bar drills and YouTube coaching tutorials* | *Joint-specific mobility regressions and alternative drill browser* |

---

## 🍽️ Nutrition & Offline USDA Database Engine

OLY includes an embedded **2.06 million item** offline database stored in `assets/data/usda_foods.db` and searched with SQLite FTS5:

```
Total Foods:     2,064,169 items
Total Brands:    52,840 brands
Offline Barcodes: 1,981,654 barcoded products
Engine:          SQLite with FTS5 BM25 prefix search (porter unicode61)
Size:            689 MB (standalone rollback journal, zero network latency)
```

### Dataset Sub-Collections Included

1. **USDA Survey Foods (FNDDS)** (5,432 items):
   - Comprehensive composite meals, home-cooked preparations, and standard recipes (e.g. `Ham sandwich on wheat`, `Roast beef`, `Chicken stir-fry`, `Apple pie`).
   - Standardized macros mapped across nutrient numbers (`208` Energy, `203` Protein, `204` Fat, `205` Carbs, `291` Fiber).
2. **USDA Foundation Foods** (68,867 items):
   - Gold-standard whole foods, produce, eggs, dairy, and detailed nutrient profiles.
3. **USDA SR Legacy** (7,793 items):
   - All standard reference cuts of beef, poultry, pork, seafood, and whole grains.
4. **USDA Branded Foods** (1,981,654 items):
   - Full commercial packaged grocery database with direct 1-to-1 UPC barcode indexing.
5. **Fast-Food & Restaurant Chains** (316 items):
   - Curated menus across McDonald's (48+ items), Wingstop, Wendy's, Chick-fil-A, Taco Bell, Burger King, Chipotle, Starbucks, In-N-Out, Panda Express, Subway, Popeyes, Raising Cane's, Five Guys, Shake Shack, Domino's, Sweetgreen, Cava, Panera, and Texas Roadhouse.
   - Discrete piece units: `wing`, `nugget`, `tender`, `patty`, `slice`, `taco`, `biscuit`, `donut`, `egg`.

---

## 📸 Automated Screenshot Verification Pipeline

OLY includes an automated screenshot capture suite supporting both top and scrolled viewports:

```bash
# Run automated screenshot generation test (captures all 30 high-res PNG images)
flutter test test/screenshot_capture_test.dart
```

Generated screenshots are saved directly to `screenshots/` and verified across 28 multi-screen rendering tests.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── main.dart                                  # Application root, error interceptors & provider setup
├── theme/
│   └── app_theme.dart                         # Dark Obsidian (#121214) & Neon Amber (#FF9E1B) design system
├── models/
│   ├── lift_model.dart                        # Lift definitions & Olympic variation ratio math
│   ├── program_model.dart                     # 4-Day & 5-Day periodization templates & week loaders
│   ├── workout_session.dart                   # Workout session logs, RPE, and strain models
│   ├── mobility_exercise_model.dart           # Active recovery exercises with cues & video links
│   ├── injury_model.dart                      # Anatomical regions, OSIICS catalog, & rehabilitation plans
│   ├── breathing_session_model.dart           # Wim Hof round logs, retention hold times, & pace configs
│   ├── nutrition_entry.dart                   # Daily food logs, activities, and macro models
│   ├── body_comp_model.dart                   # 13-field Renpho scale biometrics & historical trends
│   └── plate_calc.dart                        # Barbell sleeve greedy plate allocation algorithm
├── providers/
│   ├── lift_provider.dart                     # 1RM catalog & ratio balance calculations
│   ├── program_provider.dart                  # Periodization cycle progression & week advancement
│   ├── recovery_provider.dart                 # Recovery routine generation & readiness tracking
│   ├── injury_provider.dart                   # Joint strain lifecycle, regressions, & PDF export
│   ├── breathing_provider.dart                # Wim Hof session history, PR detection, & retention trends
│   ├── nutrition_provider.dart                # Calorie balance, macro tracking, & hydration
│   ├── body_comp_provider.dart                # Renpho scale history & lean mass calculations
│   └── settings_provider.dart                 # Units (kg/lbs), bar specs, audio/haptic toggles
├── services/
│   ├── usda_database_service.dart             # Embedded SQLite FTS5 2M+ USDA & fast-food search engine
│   ├── food_database_service.dart             # SQLite first-pass search with fallback to OpenFoodFacts SDK
│   ├── storage_service.dart                   # Local persistence, JSON/CSV backup & product caching
│   ├── renpho_ocr_service.dart                # Google ML Kit OCR text parser for smart scale screens
│   ├── app_log_service.dart                   # Ring-buffer logging & persistent crash storage
│   ├── notification_service.dart              # Timezone-aware local notifications & audio alerts
│   ├── recovery_engine_service.dart           # Adaptive mobility routine generator
│   └── warmup_engine_service.dart             # Dynamic warmup generator
├── views/
│   ├── splash_screen.dart                     # Animated launch splash
│   ├── dashboard_screen.dart                  # Main hub with cycle status & workout launchers
│   ├── workout_session_screen.dart            # Live workout tracking, rest timer, weight adjust & swap
│   ├── recovery_session_screen.dart           # Interactive 5-phase mobility routine
│   ├── warmup_session_screen.dart             # Guided warm-up sequence with video drills
│   ├── lifts_screen.dart                      # 1RM catalog & Olympic variation standards
│   ├── plate_calculator_screen.dart           # Barbell plate visualizer & specs
│   ├── max_test_screen.dart                   # Week 5 1RM retest protocol
│   ├── analytics_screen.dart                  # Total tonnage, workout history, & ratio charts
│   ├── injury_tracker_screen.dart             # 14-region vector body map & clinical export
│   ├── breathing/
│   │   ├── wim_hof_setup_sheet.dart           # Breathwork setup sheet with round & pace steppers
│   │   ├── wim_hof_session_screen.dart        # Guided flow with pulsing orb & retention timer
│   │   ├── wim_hof_summary_screen.dart        # Post-session summary, PR banner & readiness rating
│   │   └── breathing_analytics_tab.dart       # Retention duration progression & round averages
│   ├── nutrition/
│   │   ├── nutrition_dashboard_screen.dart    # Energy In vs Out gauge, macros, and activity logs
│   │   ├── live_barcode_scanner_sheet.dart    # Live camera barcode scanner with reticle overlay
│   │   ├── food_search_sheet.dart             # Zero-latency search across 2M+ items with source filter tabs
│   │   ├── renpho_scanner_sheet.dart          # Smart scale OCR scanner & donut chart view
│   │   ├── activity_log_sheet.dart            # Compendium activity logger with Algorithm B
│   │   └── metabolic_science_explainer_screen.dart # 5-tab metabolic science reference hub
│   └── diagnostics/
│       └── crash_report_screen.dart           # In-app log inspector, error filter, & diagnostic export
└── widgets/
    ├── barbell_visualizer.dart                # CustomPainted IWF bumper plate rendering
    ├── exercise_swap_modal.dart               # Segmented exercise swap modal (Suggested vs Other)
    ├── workout_weight_dialog.dart             # Working weight adjust & 1RM recalculator dialog
    ├── rest_timer_widget.dart                 # Timer dial, micro-steppers, and alert dispatcher
    ├── video_player_card.dart                 # YouTube thumbnail preview & coaching link launcher
    ├── standard_ratios_sheet.dart             # Catalyst Athletics ratio benchmarks table
    ├── body_map_painter.dart                  # Interactive 14-region vector anatomical map painter
    └── nutrition/
        ├── energy_balance_card.dart           # Circular Energy In/Out gauge & deficit indicator
        ├── smart_portion_drawer.dart          # Protein density pill, macro split bar, piece chips & steppers
        ├── macro_summary_card.dart            # Linear progress bars for Protein, Carbs, and Fat
        └── body_donut_chart.dart              # CustomPainted Lean Mass vs Fat Mass donut visualizer
```

---

---

## 🗄️ Building & Ingesting the SQLite Food Database

Because `assets/data/usda_foods.db` (689 MB) exceeds GitHub's 100 MB standard file limit, it is ignored by Git and generated on-demand using our automated ingestion scripts. You can build the database locally with a single command:

### Option A: Build the Full 2.06M+ Bulk Database (Recommended)
Downloads official USDA FoodData Central releases, extracts macros and nutrient numbers, indexes 1.98M+ barcoded products, and builds the FTS5 full-text search index:

```bash
# Ingests Foundation, SR Legacy, Survey Foods (FNDDS), Branded Products & 26 Restaurant Chains
python3 scripts/import_usda_bulk.py
```
> **Note**: Raw USDA ZIP archives are cached in `.usda_cache/`. First-time download takes ~30–60 seconds depending on connection speed; subsequent rebuilds take only ~15 seconds.

### Option B: Build the Lightweight Core Database (19 MB)
If you only need core whole staples, Foundation foods, Survey recipes, and fast-food chains without the 1.98M commercial branded grocery items:

```bash
# Ingests 26 fast-food chains + core whole staples catalog into SQLite
python3 scripts/generate_restaurant_catalog.py
python3 scripts/build_usda_sqlite.py
```

### Option C: Run via VS Code Tasks (One-Click)
In Visual Studio Code or Antigravity IDE:
1. Press `Cmd + Shift + P` (macOS) or `Ctrl + Shift + P` (Windows/Linux).
2. Select **`Tasks: Run Task`**.
3. Choose:
   - **`Update USDA Database (Full 2M+ Bulk Ingestion)`** for the complete 2.06M dataset.
   - **`Update USDA Database (Core Whole Foods & Fast Food)`** for the lightweight build.
   - **`Generate Restaurant Menus Catalog`** to re-export fast-food JSON definitions.

### 🔄 Device Auto-Synchronization
When you bundle an updated `assets/data/usda_foods.db` and launch the app on an iOS or Android device, `UsdaDatabaseService` automatically compares the asset file size against local device storage. If a newer database is detected, it cleanly refreshes local storage and connects instantly without requiring an app reinstall.

---

## 💻 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.13.0` or later
- **Dart SDK**: `^3.0.0` or later
- **Xcode**: 15+ (for iOS development & testing)
- **CocoaPods**: Latest
- **Python**: 3.10+ (for database ingestion scripts)

### Installation & Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/drexel-ue/oly.git
   cd oly
   ```

2. **Run the automated setup script**:
   ```bash
   # Installs Flutter dependencies, verifies toolchain, and compiles all offline SQLite databases:
   dart setup.dart

   # (Optional) For ultra-fast core database setup without full 2M+ branded products:
   # dart setup.dart --quick
   ```

3. **Run code analysis & automated test suite**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch on connected device or simulator**:
   ```bash
   # Launch on iOS Simulator or connected iPhone
   flutter run -d iPhone

   # Launch directly to a specific tab (0=Home, 1=Lifts, 2=Loader, 3=MaxTest, 4=Analytics, 5=Nutrition)
   flutter run --dart-define=TAB=5
   ```

---

## 📄 Testing Suite (150 Passing Tests)

Run the full suite of unit, widget, domain engine, and screenshot rendering tests:
```bash
flutter test
```

Test coverage includes:
- `usda_database_test.dart`: SQLite database initialization, FTS5 BM25 token search, McDonald's/Wingstop/Cane's variety, whole food search, and direct UPC barcode lookups.
- `injury_export_test.dart`: Clinical PDF document byte generation, structured JSON backup format, and export bottom sheet widget interactions.
- `injury_model_test.dart`: OSIICS serialization, duration calculation, and acute/subacute/chronic classification.
- `injury_adaptation_test.dart`: Biomechanical loading vector rules, exercise regressions, and rehab warmup injection.
- `injury_provider_test.dart`: Injury CRUD, persistent storage, history tracking, and post-session diff sync.
- `injury_tracker_widget_test.dart`: Interactive body map front/back toggle, tap detection, adaptation card 1-tap swap, and check-in dialog.
- `energy_balance_test.dart`: Katch-McArdle, Mifflin-St Jeor, Compendium MET calculations (Algorithm B vs A), and WOD TUT physics.
- `energy_balance_widget_test.dart`: `EnergyBalanceCard` gauge, `MetabolicScienceExplainerScreen` 5 tabs, and `ActivityLogSheet`.
- `food_database_service_test.dart`: SQLite local search first-pass, Open Food Facts SDK query, typed parsing, and offline caching.
- `smart_portion_widget_test.dart`: Protein density index, macro split bar, custom piece chips (wings, nuggets, tenders), steppers, and live barcode camera scanner.
- `renpho_ocr_test.dart`: 13-field OCR regex parsing from smart scale screenshots, lean mass calculations, and BMR updates.
- `app_log_service_test.dart`: Ring-buffer logging, persistent crash storage, and `CrashReportScreen` UI controls.
- `screenshot_capture_test.dart`: 23 multi-view layout tests verifying rendering and generating high-res PNGs for all views.
- `exercise_swap_test.dart`: Movement substitution, variation categorization, and weight recalculation.
- `workout_weight_recalculation_test.dart`: In-workout weight adjustment, 1RM reverse formulas, steppers, and save modes.
- `feature_audit_test.dart`: Session serialization, RPE, joint strain tags, recovery adaptation, and JSON/CSV backup.
- `plate_calculator_test.dart`: Greedy plate allocation algorithm across kg/lb configurations.
- `percentage_calculator_test.dart`: Working weight calculation and rounding rules across periodization weeks.
- `recovery_engine_test.dart`: Adaptive mobility exercise selection and strain focus algorithms.

---

## 📝 License

Developed for Olympic weightlifters, coaches, and strength athletes.  
Copyright © 2026 Lamont Labs. All rights reserved.
