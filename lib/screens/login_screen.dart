import 'package:flutter/material.dart';
import '../models/center.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final CenterModel center;

  const LoginScreen({super.key, required this.center});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final employeeCode = _employeeCodeController.text.trim();
    final password = _passwordController.text.trim();

    if (employeeCode.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '근무자 코드와 비밀번호를 모두 입력해주세요.';
        _isLoading = false;
      });
      return;
    }

    if (password == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(center: widget.center),
        ),
      );
    } else {
      setState(() {
        _errorMessage = '비밀번호가 틀렸습니다.\n초기 비밀번호는 0000입니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.center.displayName} 로그인'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.lock_outline, size: 80, color: Colors.blue.shade700),
            const SizedBox(height: 24),
            Text(
              '근무자 로그인',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.center.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _employeeCodeController,
              decoration: const InputDecoration(
                labelText: '근무자 코드',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('로그인'),
            ),

            const SizedBox(height: 24),
            const Text(
              '초기 비밀번호는 모두 0000입니다.\n첫 로그인 후 반드시 비밀번호를 변경해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}