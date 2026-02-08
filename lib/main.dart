import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Set up background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// 🔔 Background message handler (must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔕 Background Message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseMessaging _messaging;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://shelf-life-management.netlify.app'));
  }

  void _initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // ✅ Ask for permission (important for iOS)
    NotificationSettings settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission granted');

      // 🔑 Get the FCM token
      String? token = await _messaging.getToken();
      print('📲 FCM Token: $token'); // <-- THIS is what you’ll copy for Firebase Console

      // 💬 Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📥 Foreground Message: ${message.notification?.title}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? 'New Notification'),
          ),
        );
      });

      // 🚪 Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🟢 Notification Clicked: ${message.notification?.title}');
      });
    } else {
      print('❌ Permission not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Shelf Life App')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
