import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'router.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ErrorScreen(message: e.toString()),
      ),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return MaterialApp(
            title: 'NO, YOU ARE NOT',
            theme: AppTheme.theme,
            debugShowCheckedModeBanner: false,
            home: const LoginScreen(),
          );
        }
        // User is signed in — sync with backend before showing the app.
        final syncAsync = ref.watch(syncedUserProvider);
        return syncAsync.when(
          loading: () => const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _SplashScreen(),
          ),
          error: (e, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _ErrorScreen(message: e.toString()),
          ),
          data: (_) => MaterialApp.router(
            title: 'NO, YOU ARE NOT',
            theme: AppTheme.theme,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppTheme.accent,
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'CONNECTION\nFAILED.',
            style: AppTheme.heading,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
