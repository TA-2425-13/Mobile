import 'package:flutter/material.dart';

import 'package:app/utils/colors.dart';
import 'package:app/view/chatbot_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChatOnlyApp());
}

class ChatOnlyApp extends StatelessWidget {
  const ChatOnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Levely Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ChatbotScreen(),
    );
  }
}
