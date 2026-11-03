import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens.dart';
import 'theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();
void notify(String message) => messengerKey.currentState?.showSnackBar(
  SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const RecipeBoxApp());
}

class RecipeBoxApp extends StatelessWidget {
  const RecipeBoxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RecipeBox',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messengerKey,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        return s.data == null
            ? const HomeScreen()
            : ListScreen(key: ValueKey(s.data!.uid), user: s.data!);
      },
    ),
  );
}
