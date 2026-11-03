import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data.dart';
import 'theme.dart';

class RecipeForm extends StatefulWidget {
  final Recipe? recipe;
  final void Function(Recipe) onSaved;
  final VoidCallback? onCancel;
  const RecipeForm({
    super.key,
    this.recipe,
    required this.onSaved,
    this.onCancel,
  });
  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, time, servings, notes;
  String? category, difficulty, error;
  bool submitted = false, busy = false;
  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    name = TextEditingController(text: r?.name);
    time = TextEditingController(text: r?.cookTime.toString());
    servings = TextEditingController(text: r?.servings?.toString());
    notes = TextEditingController(text: r?.notes);
    category = r?.category;
    difficulty = r?.difficulty;
  }

  @override
  void dispose() {
    for (final c in [name, time, servings, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? whole(String? value, int max, String label, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? '$label is required' : null;
    final n = int.tryParse(v);
    return !RegExp(r'^\d+$').hasMatch(v) || n == null || n < 1 || n > max
        ? '$label must be a whole number from 1 to $max'
        : null;
  }

  Future<void> save() async {
    setState(() {
      submitted = true;
      error = null;
    });
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final r = Recipe(
      id: recipeId(uid, name.text),
      userId: uid,
      name: name.text.trim(),
      category: category!,
      difficulty: difficulty!,
      cookTime: int.parse(time.text.trim()),
      servings: servings.text.trim().isEmpty
          ? null
          : int.parse(servings.text.trim()),
      notes: notes.text.trim(),
      favorite: widget.recipe?.favorite ?? false,
      createdAt: widget.recipe?.createdAt ?? Timestamp.now(),
    );
    try {
      await Recipes.save(r, previous: widget.recipe);
      if (mounted) widget.onSaved(r);
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('recipe-name'),
          controller: name,
          enabled: !busy,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Creamy Pasta',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Name is required'
              : v.runes.length > 80
              ? 'Name must be at most 80 characters'
              : null,
        ),
        const SizedBox(height: Tokens.gap),
        DropdownButtonFormField<String>(
          key: const Key('recipe-category'),
          initialValue: category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Category'),
          hint: const Text('Choose category'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose category')),
            ...categories.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: busy ? null : (v) => setState(() => category = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please choose a category' : null,
        ),
        const SizedBox(height: Tokens.gap),
        DropdownButtonFormField<String>(
          key: const Key('recipe-difficulty'),
          initialValue: difficulty,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Difficulty'),
          hint: const Text('Choose difficulty'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose difficulty')),
            ...difficulties.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: busy ? null : (v) => setState(() => difficulty = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please choose a difficulty' : null,
        ),
        const SizedBox(height: Tokens.gap),
        TextFormField(
          key: const Key('recipe-time'),
          controller: time,
          enabled: !busy,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cook time (minutes)',
            hintText: 'e.g. 25',
          ),
          validator: (v) => whole(v, 600, 'Cook time', required: true),
        ),
        const SizedBox(height: Tokens.gap),
        TextFormField(
          key: const Key('recipe-servings'),
          controller: servings,
          enabled: !busy,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Servings (optional)',
            hintText: 'e.g. 2',
          ),
          validator: (v) => whole(v, 20, 'Servings'),
        ),
        const SizedBox(height: Tokens.gap),
        TextFormField(
          key: const Key('recipe-notes'),
          controller: notes,
          enabled: !busy,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Add a short note (optional)',
          ),
          validator: (v) => (v?.runes.length ?? 0) > 300
              ? 'Notes must be at most 300 characters'
              : null,
        ),
        const SizedBox(height: Tokens.gap),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.gap),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          key: const Key('recipe-submit'),
          onPressed: busy ? null : save,
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.recipe == null ? 'Add recipe' : 'Save'),
        ),
        if (widget.onCancel != null)
          TextButton(
            onPressed: busy ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
      ],
    ),
  );
}
