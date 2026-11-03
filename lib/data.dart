import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
const difficulties = ['Easy', 'Medium', 'Hard'];
String recipeId(String uid, String name) =>
    '${uid}_${base64Encode(utf8.encode(name.trim().toLowerCase())).replaceAll('/', '_').replaceAll('+', '-')}';

class Recipe {
  final String id, userId, name, category, difficulty, notes;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final Timestamp createdAt;
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.notes = '',
    this.favorite = false,
    required this.createdAt,
  });
  factory Recipe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Recipe(
      id: doc.id,
      userId: d['userId'],
      name: d['name'],
      category: d['category'],
      difficulty: d['difficulty'],
      cookTime: d['cookTime'],
      servings: d['servings'],
      notes: d['notes'] ?? '',
      favorite: d['favorite'],
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category,
    'difficulty': difficulty,
    'cookTime': cookTime,
    if (servings != null) 'servings': servings,
    'notes': notes,
    'favorite': favorite,
    'createdAt': createdAt,
  };
}

class Recipes {
  static final collection = FirebaseFirestore.instance.collection('recipes');
  static Stream<List<Recipe>> watch(String uid) => collection
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(Recipe.fromDoc).toList());
  static Future<void> save(Recipe next, {Recipe? previous}) async {
    await FirebaseFirestore.instance
        .runTransaction((tx) async {
          final target = collection.doc(next.id);
          final snapshot = await tx.get(target);
          if (previous?.id != next.id && snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'already-exists',
              message: 'A recipe with this name already exists.',
            );
          }
          if (previous != null) {
            final old = previous.id == next.id
                ? snapshot
                : await tx.get(collection.doc(previous.id));
            if (!old.exists) {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                code: 'not-found',
                message: 'This recipe was deleted.',
              );
            }
            if (previous.id != next.id) tx.delete(collection.doc(previous.id));
          }
          tx.set(target, next.toMap());
        })
        .timeout(const Duration(seconds: 20));
  }

  static Future<void> favorite(Recipe r) => collection
      .doc(r.id)
      .update({'favorite': !r.favorite})
      .timeout(const Duration(seconds: 20));
  static Future<void> delete(Recipe r) =>
      collection.doc(r.id).delete().timeout(const Duration(seconds: 20));
}

String errorText(Object e) {
  if (e is FirebaseAuthException) return e.message ?? e.code;
  if (e is FirebaseException) return e.message ?? e.code;
  return 'Unable to connect. Check your connection and try again.';
}
