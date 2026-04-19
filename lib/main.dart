import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'admin/admin_dashboard.dart';
import 'screens/center_selection_screen.dart';
import 'models/center.dart';

// ==================== 개발 모드 설정 ====================
const bool DEV_MODE = true;

// 대치본원 UUID (실제 값)
const String DEV_CENTER_ID = 'e72616e1-0830-4fdf-b468-6da4532bcdd9';
// =======================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  await Supabase.initialize(
    url: 'https://yshpdkltiwqwbowjprox.supabase.co',
    anonKey: 'sb_publishable_Ch2An6gV7uZn02Jz5IT6Sg_Z1yZERjA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '댓츠원 스터디랩 ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DEV_MODE 
          ? AdminDashboard(
              center: CenterModel(
                id: DEV_CENTER_ID,
                name: '댓츠원 스터디랩 대치본원',
                displayName: '대치본원',
                centerCode: 'thats1_main',
              ),
            )
          : const CenterSelectionScreen(),
    );
  }
}