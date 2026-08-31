// ignore_for_file: constant_identifier_names

enum Season {
  summer,
  spring_autumn,
  winter,
  extreme_cold;

  String get displayNameRu {
    switch (this) {
      case Season.summer:
        return 'Лето (+15°C и выше)';
      case Season.spring_autumn:
        return 'Межсезонье / Осень-Весна (-5...+15°C)';
      case Season.winter:
        return 'Зима (-5...-15°C)';
      case Season.extreme_cold:
        return 'Экстремальный мороз (ниже -15°C)';
    }
  }

  static Season fromString(String val) {
    switch (val.toLowerCase()) {
      case 'summer':
        return Season.summer;
      case 'winter':
        return Season.winter;
      case 'extreme_cold':
        return Season.extreme_cold;
      case 'spring_autumn':
      default:
        return Season.spring_autumn;
    }
  }
}

enum ActivityType {
  hiking,
  mountain,
  water,
  survival;

  String get displayNameRu {
    switch (this) {
      case ActivityType.hiking:
        return 'Пеший туризм / Трекинг';
      case ActivityType.mountain:
        return 'Горный поход / Альпинизм';
      case ActivityType.water:
        return 'Водный поход / Сплав';
      case ActivityType.survival:
        return 'Выживание / Бушкрафт';
    }
  }

  static ActivityType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'mountain':
        return ActivityType.mountain;
      case 'water':
        return ActivityType.water;
      case 'survival':
        return ActivityType.survival;
      case 'hiking':
      default:
        return ActivityType.hiking;
    }
  }
}

enum FoodCategory {
  grains,
  proteins,
  fats,
  snacks,
  basics;

  String get displayNameRu {
    switch (this) {
      case FoodCategory.grains:
        return '🌾 Крупы и углеводы';
      case FoodCategory.proteins:
        return '🥩 Мясо и белки';
      case FoodCategory.fats:
        return '🧈 Масла и жиры';
      case FoodCategory.snacks:
        return '🥜 Снеки и перекусы';
      case FoodCategory.basics:
        return '🧂 Базовые (соль, сахар, чай)';
    }
  }

  String get shortNameRu {
    switch (this) {
      case FoodCategory.grains:
        return '🌾 Крупы';
      case FoodCategory.proteins:
        return '🥩 Белки';
      case FoodCategory.fats:
        return '🧈 Жиры';
      case FoodCategory.snacks:
        return '🥜 Снеки';
      case FoodCategory.basics:
        return '🧂 База';
    }
  }

  static FoodCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'proteins':
        return FoodCategory.proteins;
      case 'fats':
        return FoodCategory.fats;
      case 'snacks':
        return FoodCategory.snacks;
      case 'basics':
        return FoodCategory.basics;
      case 'grains':
      default:
        return FoodCategory.grains;
    }
  }
}

enum GearCategory {
  shelter,
  cooking,
  tools,
  electronics,
  med_hygiene,
  clothing,
  packs,
  winter;

  String get displayNameRu {
    switch (this) {
      case GearCategory.shelter:
        return '⛺ Бивуак и укрытие';
      case GearCategory.cooking:
        return '🍳 Кухня и вода';
      case GearCategory.tools:
        return '🛠️ Инструменты и огонь';
      case GearCategory.electronics:
        return '🔋 Электроника и навигация';
      case GearCategory.med_hygiene:
        return '🩹 Аптечка и гигиена';
      case GearCategory.clothing:
        return '👕 Одежда и обувь';
      case GearCategory.packs:
        return '🎒 Рюкзаки и упаковка';
      case GearCategory.winter:
        return '❄️ Зимнее снаряжение';
    }
  }

  String get shortNameRu {
    switch (this) {
      case GearCategory.shelter:
        return '⛺ Укрытие';
      case GearCategory.cooking:
        return '🍳 Кухня';
      case GearCategory.tools:
        return '🛠️ Инструменты';
      case GearCategory.electronics:
        return '🔋 Электроника';
      case GearCategory.med_hygiene:
        return '🩹 Аптечка';
      case GearCategory.clothing:
        return '👕 Одежда';
      case GearCategory.packs:
        return '🎒 Рюкзаки';
      case GearCategory.winter:
        return '❄️ Зима';
    }
  }

  static GearCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'shelter':
        return GearCategory.shelter;
      case 'cooking':
        return GearCategory.cooking;
      case 'tools':
        return GearCategory.tools;
      case 'electronics':
        return GearCategory.electronics;
      case 'med_hygiene':
        return GearCategory.med_hygiene;
      case 'clothing':
        return GearCategory.clothing;
      case 'packs':
        return GearCategory.packs;
      case 'winter':
        return GearCategory.winter;
      default:
        return GearCategory.tools;
    }
  }
}

enum GearType {
  personal,
  group;

  String get displayNameRu {
    switch (this) {
      case GearType.personal:
        return 'Личное';
      case GearType.group:
        return 'Групповое';
    }
  }

  static GearType fromString(String val) {
    return val.toLowerCase() == 'group' ? GearType.group : GearType.personal;
  }
}

enum GearSeason {
  all,
  summer,
  spring_autumn,
  winter;

  String get displayNameRu {
    switch (this) {
      case GearSeason.all:
        return 'Всесезонное';
      case GearSeason.summer:
        return 'Лето';
      case GearSeason.spring_autumn:
        return 'Межсезонье';
      case GearSeason.winter:
        return 'Зима';
    }
  }

  static GearSeason fromString(String val) {
    switch (val.toLowerCase()) {
      case 'summer':
        return GearSeason.summer;
      case 'spring_autumn':
        return GearSeason.spring_autumn;
      case 'winter':
        return GearSeason.winter;
      case 'all':
      default:
        return GearSeason.all;
    }
  }
}

enum MealSlotType {
  breakfast,
  lunch_snack,
  dinner,
  pocket_food;

  String get displayNameRu {
    switch (this) {
      case MealSlotType.breakfast:
        return 'Завтрак';
      case MealSlotType.lunch_snack:
        return 'Обед / Перекус';
      case MealSlotType.dinner:
        return 'Ужин';
      case MealSlotType.pocket_food:
        return 'Карманное питание';
    }
  }

  double get defaultRatio {
    switch (this) {
      case MealSlotType.breakfast:
        return 0.25;
      case MealSlotType.lunch_snack:
        return 0.30;
      case MealSlotType.dinner:
        return 0.35;
      case MealSlotType.pocket_food:
        return 0.10;
    }
  }
}

enum DietaryRestriction {
  none,
  vegetarian,
  lactose_free,
  gluten_free,
  nut_allergy,
  no_sugar;

  String get displayNameRu {
    switch (this) {
      case DietaryRestriction.none:
        return 'Обычное (без ограничений)';
      case DietaryRestriction.vegetarian:
        return '🥦 Вегетарианство';
      case DietaryRestriction.lactose_free:
        return '🥛 Без лактозы (молока)';
      case DietaryRestriction.gluten_free:
        return '🌾 Без глютена';
      case DietaryRestriction.nut_allergy:
        return '🥜 Аллергия на орехи';
      case DietaryRestriction.no_sugar:
        return '🍬 Без сахара / Диабет';
    }
  }

  String get shortTag {
    switch (this) {
      case DietaryRestriction.none:
        return 'ОБЫЧНОЕ';
      case DietaryRestriction.vegetarian:
        return 'ВЕГАН';
      case DietaryRestriction.lactose_free:
        return 'БЕЗ ЛАКТОЗЫ';
      case DietaryRestriction.gluten_free:
        return 'БЕЗ ГЛЮТЕНА';
      case DietaryRestriction.nut_allergy:
        return 'БЕЗ ОРЕХОВ';
      case DietaryRestriction.no_sugar:
        return 'БЕЗ САХАРА';
    }
  }

  static DietaryRestriction fromString(String val) {
    switch (val.toLowerCase()) {
      case 'vegetarian':
        return DietaryRestriction.vegetarian;
      case 'lactose_free':
        return DietaryRestriction.lactose_free;
      case 'gluten_free':
        return DietaryRestriction.gluten_free;
      case 'nut_allergy':
        return DietaryRestriction.nut_allergy;
      case 'no_sugar':
        return DietaryRestriction.no_sugar;
      case 'none':
      default:
        return DietaryRestriction.none;
    }
  }
}

enum MedicalCondition {
  none,
  asthma,
  joint_pain,
  insect_allergy,
  hypertension,
  gi_issues;

  String get displayNameRu {
    switch (this) {
      case MedicalCondition.none:
        return 'Нет хронических заболеваний';
      case MedicalCondition.asthma:
        return '🫁 Астма / спазмы';
      case MedicalCondition.joint_pain:
        return '🦵 Проблемы с коленями/суставами';
      case MedicalCondition.insect_allergy:
        return '🐝 Аллергия на укусы пчел/насекомых';
      case MedicalCondition.hypertension:
        return '🩺 Гипертония / Давление';
      case MedicalCondition.gi_issues:
        return '💊 Хронический гастрит / ЖКТ';
    }
  }

  static MedicalCondition fromString(String val) {
    switch (val.toLowerCase()) {
      case 'asthma':
        return MedicalCondition.asthma;
      case 'joint_pain':
        return MedicalCondition.joint_pain;
      case 'insect_allergy':
        return MedicalCondition.insect_allergy;
      case 'hypertension':
        return MedicalCondition.hypertension;
      case 'gi_issues':
        return MedicalCondition.gi_issues;
      case 'none':
      default:
        return MedicalCondition.none;
    }
  }
}

enum TripRole {
  leader,
  medic,
  repairMaster,
  foodMaster,
  navigator,
  member;

  String get displayNameRu {
    switch (this) {
      case TripRole.leader:
        return 'Руководитель';
      case TripRole.medic:
        return 'Медик';
      case TripRole.repairMaster:
        return 'Реммастер';
      case TripRole.foodMaster:
        return 'Завпит';
      case TripRole.navigator:
        return 'Штурман';
      case TripRole.member:
        return 'Участник';
    }
  }

  String get emoji {
    switch (this) {
      case TripRole.leader:
        return '👑';
      case TripRole.medic:
        return '🩺';
      case TripRole.repairMaster:
        return '🔧';
      case TripRole.foodMaster:
        return '🥫';
      case TripRole.navigator:
        return '🧭';
      case TripRole.member:
        return '🎒';
    }
  }

  String get badgeTitle => '$emoji $displayNameRu';

  static TripRole fromString(String val) {
    switch (val.toLowerCase()) {
      case 'leader':
        return TripRole.leader;
      case 'medic':
        return TripRole.medic;
      case 'repairmaster':
      case 'repair_master':
        return TripRole.repairMaster;
      case 'foodmaster':
      case 'food_master':
        return TripRole.foodMaster;
      case 'navigator':
        return TripRole.navigator;
      case 'member':
      default:
        return TripRole.member;
    }
  }
}
