import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/app_bootstrap.dart';

void main() async {
  AppBootstrap.configureErrorHandling();

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppBootstrap.configureSystemUI();
    runApp(const StuDeskApp());
  }, (error, stackTrace) {
    debugPrint('StuDesk Uncaught Zone Error: $error');
  });
}
