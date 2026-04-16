import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/controller/counter_controller.dart';

void main() {
  var actual, expected;

  group('Module 1 - CounterController (Lengkap 10 Test)', () {
    late CounterController controller;
    const username = "admin";

    setUp(() async {
      SharedPreferences.setMockInitialValues({}); 
      controller = CounterController();
      await controller.loadData(username); // Pakai loadData
    });

    // 1. Initial Value
    test('initial value should be 0', () {
      actual = controller.value;
      expected = 0;
      expect(actual, expected);
    });

    // 2. setStep (updatestep)
    test('updatestep should change step value', () {
      controller.updatestep(5.0, username); // Minta double & username
      actual = controller.step;
      expected = 5;
      expect(actual, expected);
    });

    // 3. Ignore Negative Step
    test('updatestep should ignore negative value', () {
      controller.updatestep(3.0, username);
      controller.updatestep(-1.0, username); 
      expect(controller.step, 3);
    });

    // 4. Increment
    test('increment should increase counter based on step', () {
      controller.updatestep(2.0, username);
      controller.increment(username);
      actual = controller.value;
      expected = 2;
      expect(actual, expected);
    });

    // 5. Decrement
    test('decrement should decrease counter based on step', () {
      controller.updatestep(2.0, username);
      controller.increment(username); 
      controller.decrement(username); 
      actual = controller.value;
      expected = 0;
      expect(actual, expected);
    });

    // 6. Decrement Floor (Zero)
    test('decrement should not go below zero', () {
      controller.updatestep(5.0, username);
      controller.decrement(username); 
      expect(controller.value, 0);
    });

    // 7. Reset
    test('reset should set counter to zero', () {
      controller.updatestep(1.0, username);
      controller.increment(username);
      controller.reset(username);
      expect(controller.value, 0);
    });

    // 8. History Record
    test('history should record actions', () {
      controller.updatestep(1.0, username);
      controller.increment(username);
      bool containsAdded = controller.history.any((msg) => msg.contains("ditambah"));
      expect(containsAdded, true);
    });

    // 9. History Limit
    test('history should not exceed 5 items', () {
      for (int i = 0; i < 7; i++) {
        controller.increment(username);
      }
      expect(controller.history.length, 5);
    });

    // 10. Persistence (SharedPreferences)
    test('counter should persist using SharedPreferences', () async {
      controller.updatestep(3.0, username);
      controller.increment(username);

      final newController = CounterController();
      await newController.loadData(username);
      
      expect(newController.value, 3);
    });
  });
}