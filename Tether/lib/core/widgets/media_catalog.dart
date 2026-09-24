/// Stable local media paths used throughout the app.
///
/// Keeping these paths in one place makes it safe to replace artwork without
/// coupling feature screens to a particular file name or remote URL.
abstract final class AppMedia {
  static const homeHero = 'assets/images/home_hero.jpg';
  static const homeWorkout = 'assets/images/home_workout.jpg';
  static const homeStats = 'assets/images/home_stats.jpg';
  static const homeTrainer = 'assets/images/home_trainer.jpg';

  static const _bodyPartAssets = <String, String>{
    'chest': 'assets/body_parts/chest.png',
    'back': 'assets/body_parts/back.png',
    'shoulders': 'assets/body_parts/shoulders.png',
    'upper arms': 'assets/body_parts/upper_arms.png',
    'lower arms': 'assets/body_parts/upper_arms.png',
    'waist': 'assets/body_parts/waist.png',
    'upper legs': 'assets/body_parts/upper_legs.png',
    'lower legs': 'assets/body_parts/lower_legs.png',
    'lower back': 'assets/body_parts/back.png',
    'neck': 'assets/body_parts/shoulders.png',
    'full body': 'assets/body_parts/cardio.png',
    'cardio': 'assets/body_parts/cardio.png',
  };

  static String bodyPart(String name) =>
      _bodyPartAssets[name.trim().toLowerCase()] ??
      'assets/body_parts/cardio.png';
}
