import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:salearn/app_state_model.dart';
import 'package:salearn/progress_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(AppStateModel model) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<AppStateModel>.value(
          value: model,
          child: const ProgressTab(),
        ),
      ),
    );
  }

  testWidgets('shows empty state widget when totalAllTimeExercises is 0', (tester) async {
    SharedPreferences.setMockInitialValues({'total_exercises': 0});
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs)..loadFromPrefs();

    await tester.pumpWidget(buildTestableWidget(model));
    await tester.pump();

    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('renders progress charts and LTR daily goal text when totalAllTimeExercises > 0', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'total_exercises': 2,
      'daily_goal_progress': 0,
      'daily_goal_date': isoDate(DateTime.now()),
    });
    final prefs = await SharedPreferences.getInstance();
    final model = AppStateModel(prefs)..loadFromPrefs();

    await tester.pumpWidget(buildTestableWidget(model));
    await tester.pump();

    expect(model.totalAllTimeExercises, 2);
    expect(model.dailyGoalProgress, 0);

    // Verify text widget for daily goal progress has LTR directionality
    final goalTextFinder = find.text('0 / 10');
    expect(goalTextFinder, findsOneWidget);

    final Text goalTextWidget = tester.widget<Text>(goalTextFinder);
    expect(goalTextWidget.textDirection, TextDirection.ltr);
  });
}
