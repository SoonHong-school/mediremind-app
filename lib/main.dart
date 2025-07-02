import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    if (sdkInt >= 31) {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize timezone
  tz.initializeTimeZones();

  // Request notification permission (Android 13+)
  await requestNotificationPermission();

  // Init notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MediRemindApp());
}

class MediRemindApp extends StatelessWidget {
  const MediRemindApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
