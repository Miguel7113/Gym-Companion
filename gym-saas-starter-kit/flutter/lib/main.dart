import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/main_navigation.dart';
import 'features/auth/screens/gym_selection_screen.dart';

const bool SKIP_LOGIN_FOR_TESTING = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateStreamProvider);

    return MaterialApp(
      title: 'Gym Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: authAsync.when(
        data: (state) {
          if (SKIP_LOGIN_FOR_TESTING) return const MainNavigation();
          if (state.member != null) return const MainNavigation();
          return const GymSelectionScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const GymSelectionScreen(),
      ),
    );
  }
}
