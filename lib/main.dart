import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'splash/splash_screen.dart';

import 'services/transaction_service.dart';

import 'services/currency_service.dart';

import 'theme/theme_controller.dart';

// Accent Color Controller

import 'settings/appearance_screen.dart';
import 'settings/app_lock_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------

  // 1. LOAD SAVED TRANSACTIONS

  // --------------------------------------------------

  await TransactionService.instance.initialize();

  // --------------------------------------------------

  // 2. LOAD SAVED THEME

  // --------------------------------------------------

  // First install defaults to Light Mode.

  await ThemeController.instance.initialize();

  // --------------------------------------------------

  // 3. LOAD SAVED ACCENT COLOR

  // --------------------------------------------------

  await DhanviqAccentController.instance.initialize();

  // --------------------------------------------------

  // 4. LOAD SAVED CURRENCY / REGION SETTINGS

  // --------------------------------------------------

  await CurrencyService.instance.initialize();

  // --------------------------------------------------

  // 5. START APPLICATION

  // --------------------------------------------------

  runApp(const DhanviqApp());

}

// ======================================================

// DHANVIQ APPLICATION

// ======================================================

class DhanviqApp extends StatelessWidget {

  const DhanviqApp({super.key});

  // --------------------------------------------------

  // DEFAULT COLORS

  // --------------------------------------------------

  static const Color navy = Color(0xFF071536);

  static const Color green = Color(0xFF16E0B5);

  static const Color lightBackground = Color(0xFFF7F8FD);

  static const Color darkBackground = Color(0xFF090F20);

  static const Color darkSurface = Color(0xFF141D32);

  // --------------------------------------------------

  // BUILD APPLICATION

  // --------------------------------------------------

  @override

  Widget build(BuildContext context) {

    return ListenableBuilder(

      // Listen to Theme and Accent Color changes.

      listenable: Listenable.merge([

        ThemeController.instance,

        DhanviqAccentController.instance,

      ]),

      builder: (context, child) {

        // ----------------------------------------------

        // SELECTED THEME

        // ----------------------------------------------

        final ThemeMode selectedTheme =

            ThemeController.instance.themeMode;

        // ----------------------------------------------

        // SELECTED ACCENT COLOR

        // ----------------------------------------------

        final Color selectedAccent =

            DhanviqAccentController.instance.accentColor;

        // ----------------------------------------------

        // APPLICATION

        // ----------------------------------------------

        return MaterialApp(

          title: 'DHANVIQ',

          debugShowCheckedModeBanner: false,

          color: navy,

          // ============================================

          // LIGHT THEME

          // ============================================

          theme: ThemeData(

            useMaterial3: true,

            fontFamily: 'Roboto',

            brightness: Brightness.light,

            scaffoldBackgroundColor: lightBackground,

            // Selected accent color is dynamic.

            colorScheme: ColorScheme.fromSeed(

              seedColor: selectedAccent,

              primary: selectedAccent,

              secondary: green,

              surface: lightBackground,

              brightness: Brightness.light,

            ),

            // ------------------------------------------

            // APP BAR

            // ------------------------------------------

            appBarTheme: const AppBarTheme(

              backgroundColor: lightBackground,

              foregroundColor: navy,

              elevation: 0,

              surfaceTintColor: Colors.transparent,

            ),

            // ------------------------------------------

            // FLOATING ACTION BUTTON

            // ------------------------------------------

            floatingActionButtonTheme:

                FloatingActionButtonThemeData(

              backgroundColor: selectedAccent,

              foregroundColor: Colors.white,

              elevation: 4,

            ),

            // ------------------------------------------

            // PROGRESS INDICATOR

            // ------------------------------------------

            progressIndicatorTheme:

                ProgressIndicatorThemeData(

              color: selectedAccent,

            ),

            // ------------------------------------------

            // SWITCH

            // ------------------------------------------

            switchTheme: SwitchThemeData(

              thumbColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent;

                  }

                  return null;

                },

              ),

              trackColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent.withValues(

                      alpha: 0.35,

                    );

                  }

                  return null;

                },

              ),

            ),

            // ------------------------------------------

            // CHECKBOX

            // ------------------------------------------

            checkboxTheme: CheckboxThemeData(

              fillColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent;

                  }

                  return null;

                },

              ),

            ),

            // ------------------------------------------

            // INPUT FIELDS

            // ------------------------------------------

            inputDecorationTheme: InputDecorationTheme(

              focusedBorder: OutlineInputBorder(

                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide(

                  color: selectedAccent,

                  width: 1.5,

                ),

              ),

            ),

          ),

          // ============================================

          // DARK THEME

          // ============================================

          darkTheme: ThemeData(

            useMaterial3: true,

            fontFamily: 'Roboto',

            brightness: Brightness.dark,

            scaffoldBackgroundColor: darkBackground,

            // Selected accent color is dynamic.

            colorScheme: ColorScheme.fromSeed(

              seedColor: selectedAccent,

              primary: selectedAccent,

              secondary: green,

              surface: darkSurface,

              brightness: Brightness.dark,

            ),

            // ------------------------------------------

            // APP BAR

            // ------------------------------------------

            appBarTheme: const AppBarTheme(

              backgroundColor: darkBackground,

              foregroundColor: Colors.white,

              elevation: 0,

              surfaceTintColor: Colors.transparent,

            ),

            // ------------------------------------------

            // FLOATING ACTION BUTTON

            // ------------------------------------------

            floatingActionButtonTheme:

                FloatingActionButtonThemeData(

              backgroundColor: selectedAccent,

              foregroundColor: Colors.white,

              elevation: 4,

            ),

            // ------------------------------------------

            // PROGRESS INDICATOR

            // ------------------------------------------

            progressIndicatorTheme:

                ProgressIndicatorThemeData(

              color: selectedAccent,

            ),

            // ------------------------------------------

            // SWITCH

            // ------------------------------------------

            switchTheme: SwitchThemeData(

              thumbColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent;

                  }

                  return null;

                },

              ),

              trackColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent.withValues(

                      alpha: 0.35,

                    );

                  }

                  return null;

                },

              ),

            ),

            // ------------------------------------------

            // CHECKBOX

            // ------------------------------------------

            checkboxTheme: CheckboxThemeData(

              fillColor:

                  WidgetStateProperty.resolveWith<Color?>(

                (states) {

                  if (states.contains(WidgetState.selected)) {

                    return selectedAccent;

                  }

                  return null;

                },

              ),

            ),

            // ------------------------------------------

            // INPUT FIELDS

            // ------------------------------------------

            inputDecorationTheme: InputDecorationTheme(

              focusedBorder: OutlineInputBorder(

                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide(

                  color: selectedAccent,

                  width: 1.5,

                ),

              ),

            ),

          ),

          // ============================================

          // SELECTED THEME MODE

          // ============================================

          themeMode: selectedTheme,

          // ============================================

          // SYSTEM STATUS BAR AND NAVIGATION BAR

          // ============================================

          builder: (context, child) {

            final bool isDark =

                Theme.of(context).brightness ==

                    Brightness.dark;

            final Color systemBarColor =

                isDark ? darkBackground : navy;

            return AppLockGate(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(

                statusBarColor: systemBarColor,

                statusBarIconBrightness: Brightness.light,

                statusBarBrightness: Brightness.dark,

                systemNavigationBarColor: systemBarColor,

                systemNavigationBarIconBrightness:

                    Brightness.light,

                systemNavigationBarDividerColor:

                    systemBarColor,

              ),
                child: child ?? const SizedBox.shrink(),
              ),
            );

          },

          // ============================================

          // EXISTING SPLASH -> LOGIN -> HOME FLOW

          // ============================================

          home: const SplashScreen(),

        );

      },

    );

  }

}