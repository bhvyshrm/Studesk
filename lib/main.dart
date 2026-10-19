import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/app_bootstrap.dart';

import 'core/theme/theme_controller.dart';

void main() async {
  AppBootstrap.configureErrorHandling();

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppBootstrap.configureSystemUI();
    await ThemeController.instance.init();
    runApp(const StuDeskApp());
  }, (error, stackTrace) {
    debugPrint('StuDesk Uncaught Zone Error: $error');
  });
}
