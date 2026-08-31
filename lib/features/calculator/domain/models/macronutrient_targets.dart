class MacronutrientTargets {
  final double dailyCalories;
  final double dailyProteinG;
  final double dailyFatG;
  final double dailyCarbsG;
  final double dailySodiumMg;
  final double dailyWaterLiters;
  final double dailyGasFuelG;
  final double bmr;
  final double pal;
  final double equivalentDistanceKm;
  final double dailyEquivalentKm;
  final double coldBonusKcal;

  const MacronutrientTargets({
    required this.dailyCalories,
    required this.dailyProteinG,
    required this.dailyFatG,
    required this.dailyCarbsG,
    required this.dailySodiumMg,
    required this.dailyWaterLiters,
    required this.dailyGasFuelG,
    required this.bmr,
    required this.pal,
    required this.equivalentDistanceKm,
    required this.dailyEquivalentKm,
    required this.coldBonusKcal,
  });

  /// Protein calories percentage
  double get proteinCalPercent => (dailyProteinG * 4.0 / dailyCalories) * 100.0;

  /// Fat calories percentage
  double get fatCalPercent => (dailyFatG * 9.0 / dailyCalories) * 100.0;

  /// Carbs calories percentage
  double get carbsCalPercent => (dailyCarbsG * 4.0 / dailyCalories) * 100.0;
}
