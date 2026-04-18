import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/center.dart';
import 'login_screen.dart';

class CenterSelectionScreen extends StatefulWidget {
  const CenterSelectionScreen({super.key});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  List<CenterModel> centers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final response = await Supabase.instance.client
          .from('centers')
          .select()
          .order('display_name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      setState(() {
        centers = data.map((json) => CenterModel.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '센터 정보를 불러오는 중 오류가 발생했습니다.\n$e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('센터 선택'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : centers.isEmpty
                  ? const Center(child: Text('등록된 센터가 없습니다.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '어느 센터로 접속하시겠습니까?',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '센터를 선택해주세요',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 30),
                          Expanded(
                            child: ListView.builder(
                              itemCount: centers.length,
                              itemBuilder: (context, index) {
                                final center = centers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(20),
                                    leading: const Icon(Icons.location_on, size: 40, color: Colors.blue),
                                    title: Text(
                                      center.displayName,
                                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(center.name),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginScreen(center: center),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}