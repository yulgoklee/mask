import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/design_tokens.dart';
import 'core/router/app_router.dart';

class MaskAlertApp extends ConsumerWidget {
  const MaskAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Animate.restartOnHotReload = true;
    return MaterialApp.router(
      title: '마스크 알림',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en')],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: DT.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: DT.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
    );
  }
}
