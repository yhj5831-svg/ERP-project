import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/center_selection_screen.dart';
import 'admin/admin_dashboard.dart';
import 'models/center.dart';

// ==================== 개발 모드 설정 ====================
// true = 개발용 바로 대시보드 진입 (추천)
// false = 정상 흐름 (센터 선택 → 로그인)
const bool DEV_MODE = true;
// 개발용으로 사용할 센터 (DEV_MODE가 true일 때 사용)
const String DEV_CENTER_CODE = 'thats1_main';   // 대치본원
// =========================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yshpdkltiwqwbowjprox.supabase.co',
    anonKey: 'sb_publishable_Ch2An6gV7uZn02Jz5IT6Sg_Z1yZERjA',
  );

  runApp(const AcademyERP());
}

class AcademyERP extends StatelessWidget {
  const AcademyERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '학원 ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DEV_MODE ? const DevSkipScreen() : const CenterSelectionScreen(),
    );
  }
}

// 개발용 바로 대시보드 진입 화면
class DevSkipScreen extends StatelessWidget {
  const DevSkipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DEV_CENTER_CODE에 해당하는 센터를 찾아 대시보드로 바로 이동
    return FutureBuilder(
      future: Supabase.instance.client
          .from('centers')
          .select()
          .eq('center_code', DEV_CENTER_CODE)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final center = CenterModel.fromJson(snapshot.data!);
          return AdminDashboard(center: center);
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('개발 모드 오류: ${snapshot.error}')),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}