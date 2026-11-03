import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipebox/main.dart' as app;
import 'package:recipebox/data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('RecipeBox complete device acceptance and report evidence', (
    t,
  ) async {
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await app.main();
    await t.pumpAndSettle();
    await FirebaseAuth.instance.signOut();
    await t.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await t.pumpAndSettle();
    Future<void> shot(String name) async {
      await t.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pumpAndSettle();
    }

    Future<void> text(String key, String value) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.enterText(f, value);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
    }

    Future<void> top() async {
      final s = find.byType(CustomScrollView);
      if (s.evaluate().isNotEmpty) {
        final state = t.state<ScrollableState>(
          find.descendant(of: s, matching: find.byType(Scrollable)).first,
        );
        state.position.jumpTo(0);
        await t.pumpAndSettle();
      }
    }

    Future<void> locate(Finder f) async {
      await top();
      await t.scrollUntilVisible(
        f,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await t.pumpAndSettle();
    }

    Future<void> dropdown(String key, String value) async {
      await tap(find.byKey(Key(key)));
      await tap(find.text(value).last);
    }

    await shot('00_home');
    await tap(find.text('Register').first);
    await tap(find.byKey(const Key('auth-submit')));
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    await shot('04_register_validation');
    final fresh =
        'empty.qe190072.${DateTime.now().millisecondsSinceEpoch}@example.com';
    await text('auth-email', fresh);
    await text('auth-password', 'Test1234!');
    await text('auth-confirm', 'Test1234!');
    await tap(find.byKey(const Key('auth-submit')));
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    await shot('05_register_success');
    await locate(find.text('No recipes found'));
    await shot('16_empty');
    await top();
    await tap(find.text('Logout'));
    await tap(find.text('Login').first);
    await shot('06_login');
    await text('auth-email', 'grader.qe190072@example.com');
    await text('auth-password', 'Test1234!');
    await tap(find.byKey(const Key('auth-submit')));
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(
      FirebaseAuth.instance.currentUser!.email,
      'grader.qe190072@example.com',
    );
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final pending = await Recipes.collection.doc(recipeId(uid, 'Lemon Rice')).get();
    if (pending.exists) await Recipes.collection.doc(pending.id).delete();
    final samples = [
      (
        'Avocado Toast',
        'Breakfast',
        'Easy',
        10,
        2,
        true,
        'Fresh avocado and wholegrain toast.',
      ),
      (
        'Berry Yogurt',
        'Breakfast',
        'Easy',
        5,
        1,
        false,
        'Greek yogurt with seasonal berries.',
      ),
      (
        'Creamy Pasta',
        'Dinner',
        'Medium',
        25,
        3,
        true,
        'A comforting parmesan pasta.',
      ),
      (
        'Garden Salad',
        'Lunch',
        'Easy',
        15,
        2,
        false,
        'Crisp greens and a lemon dressing.',
      ),
      (
        'Chocolate Cake',
        'Dessert',
        'Hard',
        50,
        6,
        false,
        'Serve with fresh strawberries.',
      ),
    ];
    for (final v in samples) {
      final r = Recipe(
        id: recipeId(uid, v.$1),
        userId: uid,
        name: v.$1,
        category: v.$2,
        difficulty: v.$3,
        cookTime: v.$4,
        servings: v.$5,
        favorite: v.$6,
        notes: v.$7,
        createdAt: Timestamp.now(),
      );
      final old = await Recipes.collection.doc(r.id).get();
      if (!old.exists) await Recipes.save(r);
    }
    await t.pumpAndSettle(const Duration(seconds: 2));
    await locate(find.text('Berry Yogurt'));
    await shot('07_list_recipes');
    await top();
    await shot('07_list_header');
    await tap(find.byTooltip('Expand form'));
    await tap(find.byKey(const Key('recipe-submit')));
    expect(find.text('Name is required'), findsOneWidget);
    await t.ensureVisible(find.text('Name is required'));
    await shot('08_add_validation_top');
    await t.ensureVisible(find.text('Cook time is required'));
    await shot('08_add_validation_bottom');
    await text('recipe-name', 'Lemon Rice');
    await dropdown('recipe-category', 'Lunch');
    await dropdown('recipe-difficulty', 'Easy');
    await text('recipe-time', '20');
    await text('recipe-servings', '2');
    await text('recipe-notes', 'Bright lemon rice for a quick lunch.');
    await tap(find.byKey(const Key('recipe-submit')));
    await t.pumpAndSettle(const Duration(seconds: 2));
    await locate(find.text('Lemon Rice'));
    await shot('09_add_success');
    await top();
    await tap(find.byKey(const ValueKey('Category filter-All')));
    await tap(find.text('Breakfast').last);
    await locate(find.text('Recipes: 2'));
    await shot('10_filter_category');
    await tap(find.text('Clear'));
    await tap(find.byKey(const ValueKey('Difficulty filter-All')));
    await tap(find.text('Medium').last);
    await locate(find.text('Recipes: 1'));
    await shot('10_filter_difficulty');
    await tap(find.text('Clear'));
    await tap(find.byType(Switch).first);
    await locate(find.text('Favorites: 2'));
    await shot('10_filter_favorites');
    await tap(find.text('Clear'));
    await top();
    await text('search', '  LEMON  ');
    await locate(find.text('Recipes: 2'));
    await shot('10_search');
    await tap(find.text('Clear'));
    await locate(find.text('At a glance'));
    await shot('11_summary');
    await locate(find.text('Creamy Pasta'));
    await tap(find.text('Creamy Pasta'));
    await shot('12_detail');
    await tap(find.text('Edit'));
    await text('recipe-name', '');
    await text('recipe-time', '0');
    await tap(find.text('Save'));
    await t.ensureVisible(find.text('Name is required'));
    await shot('13_edit_validation_top');
    await t.ensureVisible(
      find.text('Cook time must be a whole number from 1 to 600'),
    );
    await shot('13_edit_validation_bottom');
    await text('recipe-name', 'Creamy Pasta');
    await text('recipe-time', '12');
    await text(
      'recipe-notes',
      'Updated: quick parmesan pasta with fresh herbs.',
    );
    await tap(find.text('Save'));
    await shot('14_detail_saved');
    await shot('15_favorite_before');
    await tap(find.byTooltip('Remove from favorites'));
    await t.pumpAndSettle(const Duration(seconds: 1));
    await shot('15_favorite_after');
    await tap(find.byTooltip('Add to favorites'));
    await tap(find.byTooltip('Back'));
    await locate(find.text('Lemon Rice'));
    await shot('15_delete_before');
    await tap(find.text('Lemon Rice'));
    await tap(find.text('Delete'));
    await shot('15_delete_confirm');
    await tap(find.text('Delete').last);
    await t.pumpAndSettle(const Duration(seconds: 1));
    expect(
      (await Recipes.collection.doc(recipeId(uid, 'Lemon Rice')).get()).exists,
      false,
    );
    await locate(find.text('Garden Salad'));
    await shot('15_delete_after');
    // Direct client writes exercise published Rules, independent of form validation.
    final base = Recipe(
      id: recipeId(uid, 'Rules Probe'),
      userId: uid,
      name: 'Rules Probe',
      category: 'Lunch',
      difficulty: 'Easy',
      cookTime: 10,
      createdAt: Timestamp.now(),
    ).toMap();
    Future<void> denied(Map<String, dynamic> data, {String? id}) async {
      bool rejected = false;
      try {
        await Recipes.collection.doc(id ?? base['id']).set(data);
      } on FirebaseException catch (e) {
        rejected = e.code == 'permission-denied';
      }
      expect(rejected, true, reason: 'Rules must reject $data');
    }

    for (final bad in [
      {'name': ' '},
      {'name': 'x' * 81},
      {'category': 'Invalid'},
      {'difficulty': 'Invalid'},
      {'cookTime': 0},
      {'cookTime': 601},
      {'cookTime': 1.5},
      {'cookTime': '10'},
      {'servings': 0},
      {'servings': 21},
      {'servings': 1.5},
      {'notes': 'x' * 301},
      {'userId': 'someone-else'},
      {'favorite': 'yes'},
    ]) {
      await denied({...base, ...bad});
    }
    final original = await Recipes.collection
        .doc(recipeId(uid, 'Avocado Toast'))
        .get();
    await denied({
      ...original.data()!,
      'id': 'random-duplicate',
      'name': 'AVOCADO TOAST',
    }, id: 'random-duplicate');
    await Recipes.collection.doc(base['id']).set(base);
    await Recipes.collection.doc(base['id']).delete();
    await FirebaseAuth.instance.signOut();
    await t.pumpAndSettle();
    bool anonymousDenied = false;
    try {
      await Recipes.collection.get();
    } on FirebaseException catch (e) {
      anonymousDenied = e.code == 'permission-denied';
    }
    expect(anonymousDenied, true);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: fresh,
      password: 'Test1234!',
    );
    expect(
      (await Recipes.collection
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get())
          .docs,
      isEmpty,
    );
    bool otherDenied = false;
    try {
      await Recipes.collection.doc(original.id).get();
    } on FirebaseException catch (e) {
      otherDenied = e.code == 'permission-denied';
    }
    expect(otherDenied, true);
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'grader.qe190072@example.com',
      password: 'Test1234!',
    );
    await t.pumpAndSettle();
    expect(
      (await Recipes.collection.doc(recipeId(uid, 'Creamy Pasta')).get())
          .data()!['cookTime'],
      12,
    );
    await top();
    await shot('17_final');
  });
}
