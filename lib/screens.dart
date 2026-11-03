import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data.dart';
import 'forms.dart';
import 'theme.dart';
import 'main.dart' show notify;

const gap = SizedBox(height: Tokens.gap);
Widget panel(Widget child) => Card(
  child: Padding(padding: const EdgeInsets.all(Tokens.padding), child: child),
);
Text heading(String text) => Text(
  text,
  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void open(BuildContext context, bool register) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => AuthScreen(register: register)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('RecipeBox'),
      actions: [
        TextButton(
          onPressed: () => open(context, false),
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: () => open(context, true),
          child: const Text('Register'),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Tokens.padding),
        children: [
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                gap,
                const Text(
                  'RecipeBox',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                gap,
                const Text(
                  'Your personal space for recipes worth keeping.',
                  style: TextStyle(fontSize: 18),
                ),
                gap,
                const Text(
                  'From everyday favorites to your next kitchen adventure. Save a little inspiration for every meal.',
                ),
                gap,
                FilledButton(
                  onPressed: () => open(context, true),
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
          gap,
          for (final feature in [
            (
              Icons.menu_book_rounded,
              'Save your recipes',
              'Keep your kitchen inspiration in one private place.',
            ),
            (
              Icons.schedule_rounded,
              'Sort by cooking time',
              'Find the right meal for the time you have.',
            ),
            (
              Icons.star_border_rounded,
              'Mark your favorites',
              'Come back to the recipes you love.',
            ),
          ]) ...[
            panel(
              Row(
                children: [
                  Icon(
                    feature.$1,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: Tokens.gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(feature.$3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap,
          ],
        ],
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  final bool register;
  const AuthScreen({super.key, required this.register});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool submitted = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      submitted = true;
      error = null;
    });
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      if (widget.register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (widget.register) notify('Registration successful');
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.register ? 'Register' : 'Login')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Tokens.padding),
        child: panel(
          Form(
            key: form,
            autovalidateMode: submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.register
                      ? Icons.person_add_alt_1_rounded
                      : Icons.lock_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                gap,
                heading(
                  widget.register ? 'Make room for good food' : 'Welcome back',
                ),
                gap,
                Text(
                  widget.register
                      ? 'Create your own private recipe collection.'
                      : 'Your recipes are waiting for you.',
                ),
                gap,
                TextFormField(
                  key: const Key('auth-email'),
                  controller: email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Email is required'
                      : !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v.trim())
                      ? 'Please enter a valid email address'
                      : null,
                ),
                gap,
                TextFormField(
                  key: const Key('auth-password'),
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: (_) {
                    if (submitted) form.currentState?.validate();
                  },
                  validator: (v) => v == null || v.isEmpty
                      ? 'Password is required'
                      : widget.register && v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                gap,
                if (widget.register) ...[
                  TextFormField(
                    key: const Key('auth-confirm'),
                    controller: confirm,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Confirm password is required'
                        : v != password.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  gap,
                ],
                FilledButton(
                  key: const Key('auth-submit'),
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.register ? 'Register' : 'Login'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Tokens.gap),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                gap,
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                AuthScreen(register: !widget.register),
                          ),
                        ),
                  child: Text(
                    widget.register
                        ? 'Already registered? Login'
                        : 'New here? Register',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ListScreen extends StatefulWidget {
  final User user;
  const ListScreen({super.key, required this.user});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final Stream<List<Recipe>> stream;
  final search = TextEditingController(), scroll = ScrollController();
  String category = 'All', difficulty = 'All';
  bool favorites = false, adding = false;
  int formVersion = 0;
  @override
  void initState() {
    super.initState();
    stream = Recipes.watch(widget.user.uid);
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  void add() {
    setState(() => adding = true);
    scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void clear() {
    setState(() {
      category = 'All';
      difficulty = 'All';
      favorites = false;
      search.clear();
    });
  }

  Widget filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      'All',
      ...values,
    ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: (v) {
      if (v != null) changed(v);
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('List'),
      actions: [
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          child: const Text('Logout'),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.padding,
          vertical: Tokens.small,
        ),
        child: panel(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: clear,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Recipes'),
              ),
              IconButton.filled(
                tooltip: 'Add a recipe',
                onPressed: add,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Favorites only',
                onPressed: () => setState(() => favorites = !favorites),
                icon: Icon(
                  favorites ? Icons.star : Icons.star_border,
                  color: favorites ? Tokens.gold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: StreamBuilder<List<Recipe>>(
        stream: stream,
        builder: (context, s) {
          if (s.hasError)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Tokens.padding),
                child: Text(errorText(s.error!)),
              ),
            );
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final q = search.text.trim().toLowerCase();
          final rows =
              s.data!
                  .where(
                    (r) =>
                        (category == 'All' || r.category == category) &&
                        (difficulty == 'All' || r.difficulty == difficulty) &&
                        (!favorites || r.favorite) &&
                        (q.isEmpty ||
                            r.name.toLowerCase().contains(q) ||
                            r.notes.toLowerCase().contains(q)),
                  )
                  .toList()
                ..sort((a, b) {
                  final c = a.cookTime.compareTo(b.cookTime);
                  return c != 0
                      ? c
                      : a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });
          return CustomScrollView(
            controller: scroll,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(Tokens.padding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    heading('Your recipe collection'),
                    const SizedBox(height: Tokens.small),
                    Text(widget.user.email ?? '', key: const Key('user-email')),
                    gap,
                    panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Add a recipe',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: adding
                                    ? 'Collapse form'
                                    : 'Expand form',
                                onPressed: () =>
                                    setState(() => adding = !adding),
                                icon: Icon(
                                  adding ? Icons.expand_less : Icons.add,
                                ),
                              ),
                            ],
                          ),
                          if (adding) ...[
                            gap,
                            RecipeForm(
                              key: ValueKey(formVersion),
                              onSaved: (_) {
                                setState(() {
                                  formVersion++;
                                  adding = false;
                                });
                                notify('Recipe added');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    gap,
                    TextField(
                      key: const Key('search'),
                      controller: search,
                      decoration: const InputDecoration(
                        hintText: 'Search recipes',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    gap,
                    filter(
                      'Category filter',
                      category,
                      categories,
                      (v) => setState(() => category = v),
                    ),
                    gap,
                    filter(
                      'Difficulty filter',
                      difficulty,
                      difficulties,
                      (v) => setState(() => difficulty = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Favorites only'),
                            value: favorites,
                            onChanged: (v) => setState(() => favorites = v),
                          ),
                        ),
                        TextButton(
                          onPressed: clear,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    SummaryCard(rows: rows),
                    gap,
                    heading('Your recipes'),
                    gap,
                    if (rows.isEmpty)
                      panel(
                        const Column(
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 48),
                            gap,
                            Text(
                              'No recipes found',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.padding),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.gap),
                    child: RecipeCard(
                      recipe: rows[i],
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(recipe: rows[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Tokens.padding)),
            ],
          );
        },
      ),
    ),
  );
}

class SummaryCard extends StatelessWidget {
  final List<Recipe> rows;
  const SummaryCard({super.key, required this.rows});
  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in rows) {
      counts.update(r.category, (v) => v + 1, ifAbsent: () => 1);
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0
            ? c
            : categories.indexOf(a).compareTo(categories.indexOf(b));
      });
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'At a glance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          gap,
          Wrap(
            spacing: Tokens.gap,
            runSpacing: Tokens.small,
            children: [
              Text('Recipes: ${rows.length}'),
              Text('Favorites: ${rows.where((r) => r.favorite).length}'),
              Text(
                'Total time: ${rows.fold<int>(0, (n, r) => n + r.cookTime)} min',
              ),
            ],
          ),
          for (final c in keys) ...[
            const SizedBox(height: Tokens.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(c), Text('${counts[c]}')],
            ),
          ],
        ],
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  final Recipe recipe;
  const FavoriteButton({super.key, required this.recipe});
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: widget.recipe.favorite
        ? 'Remove from favorites'
        : 'Add to favorites',
    isSelected: widget.recipe.favorite,
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              await Recipes.favorite(widget.recipe);
            } catch (e) {
              notify(errorText(e));
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    icon: Icon(
      widget.recipe.favorite ? Icons.star_rounded : Icons.star_border_rounded,
      color: widget.recipe.favorite ? Tokens.gold : null,
    ),
  );
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onOpen;
  const RecipeCard({super.key, required this.recipe, required this.onOpen});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(Tokens.radius),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gap),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(switch (recipe.category) {
                'Breakfast' => Icons.egg_alt_outlined,
                'Lunch' => Icons.lunch_dining_outlined,
                'Dinner' => Icons.ramen_dining_outlined,
                _ => Icons.cake_outlined,
              }),
            ),
            const SizedBox(width: Tokens.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Tokens.small),
                  Text('${recipe.category} · ${recipe.difficulty}'),
                  Text('${recipe.cookTime} min'),
                ],
              ),
            ),
            FavoriteButton(recipe: recipe),
          ],
        ),
      ),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  final Recipe recipe;
  const DetailScreen({super.key, required this.recipe});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String id;
  bool edit = false, busy = false;
  @override
  void initState() {
    super.initState();
    id = widget.recipe.id;
  }

  Future<void> delete(Recipe r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      await Recipes.delete(r);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      notify(errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null)
      return const Scaffold(body: Center(child: Text('Please Login')));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: SafeArea(
        child: StreamBuilder(
          stream: Recipes.collection.doc(id).snapshots(),
          builder: (context, s) {
            if (s.hasError) return Center(child: Text(errorText(s.error!)));
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            if (!s.data!.exists)
              return const Center(child: Text('Recipe no longer available'));
            final r = Recipe.fromDoc(s.data!);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Tokens.padding),
              child: edit
                  ? panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading('Edit recipe'),
                          gap,
                          RecipeForm(
                            recipe: r,
                            onSaved: (next) {
                              setState(() {
                                id = next.id;
                                edit = false;
                              });
                              notify('Recipe saved');
                            },
                            onCancel: () => setState(() => edit = false),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: heading(r.name)),
                                  FavoriteButton(recipe: r),
                                ],
                              ),
                              gap,
                              Wrap(
                                spacing: Tokens.small,
                                children: [
                                  Chip(label: Text(r.category)),
                                  Chip(label: Text(r.difficulty)),
                                ],
                              ),
                              gap,
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.schedule),
                                title: const Text('Cook time'),
                                subtitle: Text('${r.cookTime} min'),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.people_outline),
                                title: const Text('Servings'),
                                subtitle: Text(
                                  r.servings?.toString() ?? 'Not specified',
                                ),
                              ),
                              gap,
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: Tokens.small),
                              Text(r.notes.isEmpty ? 'No notes' : r.notes),
                            ],
                          ),
                        ),
                        gap,
                        FilledButton.icon(
                          onPressed: busy
                              ? null
                              : () => setState(() => edit = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        gap,
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => delete(r),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(busy ? 'Deleting…' : 'Delete'),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
