import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/controller/login_controller.dart';
import 'package:logbook_app_001/features/logbook/view/log_view.dart';
import 'dart:async';

class LoginView extends StatefulWidget{
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() {
    String user = _userController.text;
    String password = _passController.text;
    final userProfile = _controller.login(user, password);

    if (userProfile != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(currentUser: userProfile),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Gagal! Check Username/Password")),
      );
    }
  }

  bool _obscureText = true;
  bool _isButtonDisabled = false;
  int _secondsRemaining = 0;

  void startCooldown() {
    setState(() {
      _isButtonDisabled = true;
      _secondsRemaining = 10;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _isButtonDisabled = false);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonDisabled ? null : _handleLogin,
              child: Text(_isButtonDisabled ? "Tunggu ($_secondsRemaining s)" : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}