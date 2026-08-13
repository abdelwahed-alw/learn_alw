import 'package:flutter_test/flutter_test.dart';
import 'package:salearn/app_state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps daily goal progress when opened again on the same day', () async {
    SharedPreferences.setMockInitialValues({
      'daily_goal_progress': 5,
      'daily_goal_date': isoDate(DateTime.now()),
      'total_exercises': 19,
      'progress_categories': '{"grammar":8}',
    });
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs);
    model.loadFromPrefs();

    expect(model.dailyGoalProgress, 5);
    expect(model.totalExercisesDone, 19);
    expect(model.grammarProgress, 0.8);
  });

  test('resets daily metrics when a new day has started', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'daily_goal_progress': 7,
      'daily_goal_date': isoDate(yesterday),
      'total_exercises': 19,
      'progress_categories': '{"grammar":8}',
      'beginner_vocabulary_en':
          '[{"word":"eat","meaning":"to consume food"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs);
    model.loadFromPrefs();

    expect(model.dailyGoalProgress, 0);
    expect(model.grammarProgress, 0);
    expect(model.totalExercisesDone, 19);
    expect(model.beginnerVocabulary.length, 1);
  });

  test('category exercises count toward total exercises done', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs);
    model.loadFromPrefs();

    model.incrementCategoryProgress('grammar');

    expect(model.totalExercisesDone, 1);
    expect(model.totalAllTimeExercises, 1);
    expect(model.dailyGoalProgress, 1);
    expect(model.grammarProgress, 0.1);
  });

  test('totalAllTimeExercises reflects lifetime total exercises when daily goal resets', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'daily_goal_progress': 5,
      'daily_goal_date': isoDate(yesterday),
      'total_exercises': 2,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs);
    model.loadFromPrefs();

    expect(model.dailyGoalProgress, 0);
    expect(model.totalAllTimeExercises, 2);
  });
}
