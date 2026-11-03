import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipebox/main.dart' as app;
import 'package:recipebox/data.dart';

void main() {
  final b = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Search detail edit favorites and delete evidence', (t) async {
    b.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await app.main();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'grader.qe190072@example.com',
      password: 'Test1234!',
    );
    await t.pumpAndSettle(const Duration(seconds: 2));
    await b.convertFlutterSurfaceToImage();
    await t.pumpAndSettle();
    Future<void> shot(String s) async {
      await t.pumpAndSettle();
      await b.takeScreenshot(s);
    }

    Future<void> top() async {
      final f = find.byType(CustomScrollView);
      if (f.evaluate().isNotEmpty) {
        t
            .state<ScrollableState>(
              find.descendant(of: f, matching: find.byType(Scrollable)).first,
            )
            .position
            .jumpTo(0);
        await t.pumpAndSettle();
      }
    }

    Future<void> locate(Finder f) async {
      await top();
      await t.scrollUntilVisible(
        f,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await t.pumpAndSettle();
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pumpAndSettle();
    }

    Future<void> text(String k, String v) async {
      await t.ensureVisible(find.byKey(Key(k)));
      await t.enterText(find.byKey(Key(k)), v);
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
    }

    await top();
    await text('search', '  LEMON  ');
    await shot('10_search');
    await locate(find.text('Clear'));
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    expect(
      (await Recipes.collection.doc(recipeId(uid, 'Lemon Rice')).get()).exists,
      false,
    );
    await locate(find.text('Garden Salad'));
    await shot('15_delete_after');
    await top();
    await shot('17_final');
  });
}
