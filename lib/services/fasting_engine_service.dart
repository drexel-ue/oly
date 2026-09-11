import 'package:intl/intl.dart';
import 'package:oly/models/fasting_grocery_item.dart';
import 'package:oly/models/fasting_session_model.dart';

class FastingEngineService {
  /// Calculate Glucose-Ketone Index (GKI)
  /// Formula: (Glucose in mg/dL / 18.016) / Ketones in mmol/L
  static double calculateGki({
    required double glucoseMgDl,
    required double ketoneMmolL,
  }) {
    if (ketoneMmolL <= 0.05) {
      return 99.0;
    }
    final double glucoseMmolL = glucoseMgDl / 18.016;
    return glucoseMmolL / ketoneMmolL;
  }

  /// Get current biological stage based on elapsed hours
  static FastingBiologicalStage getStageForHours(double elapsedHours) {
    if (elapsedHours < 4.0) {
      return FastingBiologicalStage.fed;
    }
    if (elapsedHours < 12.0) {
      return FastingBiologicalStage.postAbsorptive;
    }
    if (elapsedHours < 18.0) {
      return FastingBiologicalStage.ketosisOnset;
    }
    if (elapsedHours < 24.0) {
      return FastingBiologicalStage.autophagyActive;
    }
    if (elapsedHours < 48.0) {
      return FastingBiologicalStage.deepAutophagy;
    }
    return FastingBiologicalStage.stemCellReset;
  }

  /// Barbell and training recommendation based on current fasting duration
  static String getBarbellAdvisory(double elapsedHours) {
    if (elapsedHours < 18.0) {
      return '🟢 Full Olympic Lifting & Metcons Permitted. Intramuscular glycogen is intact from your previous feeding window.';
    }
    if (elapsedHours < 28.0) {
      return '🟡 Technique & Moderate Volume. Avoid maximal 1RM attempts (>90%). Focus on clean positions, speed under the bar, and pull technique.';
    }
    if (elapsedHours < 42.0) {
      return '🟠 Deload / Light Barbell & Aerobic Zone 2. Glycogen stores are significantly depleted. Stick to empty barbell drills, rowing, or light kettlebells.';
    }
    return '🔴 Fasting Peak — Zero Heavy Lifting. High cellular stress. Swap training for OLY Active Mobility, Wim Hof breathwork, and slow walking.';
  }

  /// 5:15 AM Pre-Workout Platform Primer recommendation
  static String getPlatformPrimerRecipe() {
    return '16–20 oz Room-Temp Water + 600–800 mg Sodium (1/4 tsp Pink Himalayan salt or Celtic sea salt) + Optional 1 cup black coffee. Take 45 min before 6:00 AM lift to restore plasma volume and prevent orthostatic dizziness.';
  }

  /// Generate a forward-looking 7–14 day fasting projection
  /// Synchronized with 4:45 AM wake, 6:00 AM workout, and 8:45 PM bed
  static List<FastingScheduleDay> generateProjection({
    required FastingProtocol currentProtocol,
    required AthleteCircadianConfig config,
    int daysCount = 7,
  }) {
    final List<FastingScheduleDay> days = <FastingScheduleDay>[];
    final DateTime now = DateTime.now();

    for (int i = 0; i < daysCount; i++) {
      final DateTime date = now.add(Duration(days: i));
      final int weekday = date.weekday; // 1 = Mon, 7 = Sun
      final String dayName = DateFormat('EEEE').format(date);

      final FastingProtocol dayProtocol = currentProtocol;
      String workoutFocus;
      bool isWorkoutDay = true;
      String notes;

      // Program alignment: Olympic lifters train Mon, Tue, Wed, Fri, Sat (Rest Thu, Sun)
      switch (weekday) {
        case DateTime.monday:
          workoutFocus = 'Snatch Wave & Clean Pulls (6:00 AM)';
          notes = 'High CNS day. Intramuscular glycogen fully loaded.';
          break;
        case DateTime.tuesday:
          workoutFocus = 'Clean & Jerk + Front Squat (6:00 AM)';
          notes = 'Heavy leg drive session. Stay on top of hydration.';
          break;
        case DateTime.wednesday:
          workoutFocus = 'Power Snatch & Overhead Squats (6:00 AM)';
          notes = 'Moderate volume speed work.';
          break;
        case DateTime.thursday:
          workoutFocus = 'Active Recovery / Mobility (6:00 AM)';
          isWorkoutDay = false;
          notes = 'Rest day. Great day for an extended fast or Wim Hof breathwork.';
          break;
        case DateTime.friday:
          workoutFocus = 'Clean & Jerk Complex (6:00 AM)';
          notes = 'Full platform intensity.';
          break;
        case DateTime.saturday:
          workoutFocus = 'Max Test or Heavy Singles (6:00 AM)';
          notes = 'Barbell peaking session.';
          break;
        case DateTime.sunday:
        default:
          workoutFocus = 'Full Rest & Mobility (6:00 AM)';
          isWorkoutDay = false;
          notes = 'Weekly reset. Fasting starts Sunday 6:00 PM.';
          break;
      }

      // Fasting & Feeding window calculations
      const String fastStart = '6:00 PM';
      String fastEnd;
      String feedingSummary;

      if (dayProtocol == FastingProtocol.intermittent16_8) {
        fastEnd = '10:00 AM';
        feedingSummary = '10:00 AM – 6:00 PM (8h window)';
      } else if (dayProtocol == FastingProtocol.intermittent18_6) {
        fastEnd = '12:00 PM';
        feedingSummary = '12:00 PM – 6:00 PM (6h window)';
      } else if (dayProtocol == FastingProtocol.warrior20_4) {
        fastEnd = '2:00 PM';
        feedingSummary = '2:00 PM – 6:00 PM (4h window)';
      } else if (dayProtocol == FastingProtocol.dinnerToDinner24) {
        fastEnd = '6:00 PM';
        feedingSummary = '6:00 PM – 7:30 PM (Dinner-to-Dinner break)';
      } else {
        fastEnd = '10:00 AM';
        feedingSummary = '10:00 AM – 6:00 PM (Standard 16:8 window)';
      }

      days.add(
        FastingScheduleDay(
          date: date,
          dayName: dayName,
          protocol: dayProtocol,
          fastingStartHour: fastStart,
          fastingEndHour: fastEnd,
          feedingWindowSummary: feedingSummary,
          workoutFocus: workoutFocus,
          isWorkoutDay: isWorkoutDay,
          notes: notes,
        ),
      );
    }

    return days;
  }

  /// Default pre-seeded Fasting Pantry and Refeeding items
  static List<FastingGroceryItem> getSeedPantryItems() {
    return const <FastingGroceryItem>[
      // Fasting Essentials
      FastingGroceryItem(
        id: 'fast_pink_salt',
        name: 'Pink Himalayan / Celtic Sea Salt',
        category: FastingGroceryCategory.fastingEssentials,
        description: 'Crucial for natriuresis. Take 500-800mg in water during fast.',
      ),
      FastingGroceryItem(
        id: 'fast_potassium',
        name: 'Potassium Chloride (NoSalt / Nu-Salt)',
        category: FastingGroceryCategory.fastingEssentials,
        description: 'Essential for cardiac rhythm & preventing muscle cramps.',
      ),
      FastingGroceryItem(
        id: 'fast_magnesium',
        name: 'Magnesium Glycinate or Malate (300-400mg)',
        category: FastingGroceryCategory.fastingEssentials,
        description: 'Take in evening to promote deep sleep and prevent cramping.',
      ),
      FastingGroceryItem(
        id: 'fast_green_tea',
        name: 'Organic Green Tea or Matcha',
        category: FastingGroceryCategory.fastingEssentials,
        description: 'EGCG stimulates autophagy and provides natural hunger suppression.',
      ),
      FastingGroceryItem(
        id: 'fast_mineral_water',
        name: 'Sparkling Mineral Water (San Pellegrino / Gerolsteiner)',
        category: FastingGroceryCategory.fastingEssentials,
        description: 'Natural bicarbonates and calcium; helps soothe the stomach.',
      ),

      // 5:15 AM Pre-Workout Primer
      FastingGroceryItem(
        id: 'primer_salt_packets',
        name: 'Electrolyte Packets (LMNT Raw or Salt Shaker)',
        category: FastingGroceryCategory.preWorkoutPrimer,
        description: 'Take 45 min before 6:00 AM lift to restore plasma blood volume.',
      ),
      FastingGroceryItem(
        id: 'primer_black_coffee',
        name: 'Whole Bean Quality Black Coffee',
        category: FastingGroceryCategory.preWorkoutPrimer,
        description: 'Spikes epinephrine and mobilizes free fatty acids for lifting.',
      ),

      // Refeeding Phase 1 (Broth)
      FastingGroceryItem(
        id: 'refeed_bone_broth',
        name: 'Organic Grass-Fed Beef or Chicken Bone Broth',
        category: FastingGroceryCategory.refeedingBroth,
        description: 'Rich in glycine and glutamine to nourish quiescent gut mucosa.',
      ),
      FastingGroceryItem(
        id: 'refeed_miso',
        name: 'Organic Fermented Miso Paste',
        category: FastingGroceryCategory.refeedingBroth,
        description: 'Gentle electrolytes and enzymes for waking digestive secretions.',
      ),

      // Refeeding Phase 2 (Gentle Foods)
      FastingGroceryItem(
        id: 'refeed_pasture_eggs',
        name: 'Pasture-Raised Organic Eggs (Soft Boiled/Poached)',
        category: FastingGroceryCategory.refeedingGentle,
        description: 'Choline, complete bioavailable protein, and healthy fats.',
      ),
      FastingGroceryItem(
        id: 'refeed_avocado',
        name: 'Ripe Hass Avocados',
        category: FastingGroceryCategory.refeedingGentle,
        description: 'High potassium and monounsaturated oleic acid; gentle on stomach.',
      ),
      FastingGroceryItem(
        id: 'refeed_kimchi',
        name: 'Raw Kimchi or Unpasteurized Sauerkraut',
        category: FastingGroceryCategory.refeedingGentle,
        description: 'Replenishes gut microbiome diversity after deep autophagy.',
      ),

      // Refeeding Phase 3 (Recovery)
      FastingGroceryItem(
        id: 'refeed_salmon',
        name: 'Wild Alaskan Salmon or Chicken Breast',
        category: FastingGroceryCategory.refeedingRecovery,
        description: 'Clean lean protein and omega-3s for muscle protein synthesis.',
      ),
      FastingGroceryItem(
        id: 'refeed_sweet_potatoes',
        name: 'Japanese Sweet Potatoes or Jasmine Rice',
        category: FastingGroceryCategory.refeedingRecovery,
        description: 'Clean digestible starches for replenishing muscle glycogen stores.',
      ),
    ];
  }
}
