import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/network/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/couple_connection/bloc/couple_bloc.dart';
import 'features/couple_connection/bloc/couple_event.dart';
import 'features/couple_connection/bloc/couple_state.dart';
import 'features/couple_connection/repositories/couple_repository.dart';
import 'features/couple_connection/screens/couple_onboarding_screen.dart';
import 'features/couple_connection/screens/create_relationship_screen.dart';
import 'features/chat/bloc/chat_bloc.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/navigation/main_navigation_screen.dart';

import 'core/services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auto region & currency detection
  await CurrencyService.init();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing in bundle, fallback gracefully
  }

  // Initialize Supabase backend
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  runApp(const HavenApp());
}

class HavenApp extends StatelessWidget {
  const HavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate repositories
    final authRepository = AuthRepository();
    final coupleRepository = CoupleRepository();
    final chatRepository = ChatRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: coupleRepository),
        RepositoryProvider.value(value: chatRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(authRepository: authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (ctx) => CoupleBloc(coupleRepository: coupleRepository),
          ),
          BlocProvider(
            create: (ctx) => ChatBloc(chatRepository: chatRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Haven',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default to obsidian luxury theme
          scrollBehavior: const HavenScrollBehavior(),
          home: const AppRootGate(),
        ),
      ),
    );
  }
}

class HavenScrollBehavior extends ScrollBehavior {
  const HavenScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Authenticated) {
          context.read<CoupleBloc>().add(CheckCoupleStatusRequested());
        }
      },
      builder: (context, authState) {
        if (authState is Authenticated) {
          return BlocBuilder<CoupleBloc, CoupleState>(
            builder: (context, coupleState) {
              if (coupleState is CouplePaired) {
                return const MainNavigationScreen();
              } else if (coupleState is CoupleNotPaired) {
                if (coupleState.pendingRelationship != null) {
                  return const CreateRelationshipScreen();
                }
                return const CoupleOnboardingScreen();
              }
              // While checking couple status, default to dashboard
              return const MainNavigationScreen();
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
