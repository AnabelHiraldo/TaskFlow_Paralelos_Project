import 'package:flutter/material.dart';

import 'views/login/login_view.dart';
import 'views/login/register_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'services/api_service.dart';
import 'repositories/auth_repository.dart';

void main() {
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const AuthNavigation(),
    );
  }
}

class AuthNavigation extends StatefulWidget {
  const AuthNavigation({super.key});

  @override
  State<AuthNavigation> createState() => _AuthNavigationState();
}

class _AuthNavigationState extends State<AuthNavigation> {
  bool _showRegister = false;
  bool _isAuthenticated = false;

  final AuthRepository _authRepository =
      AuthRepository(ApiService());

  void _showLogin() {
    setState(() {
      _showRegister = false;
    });
  }

  void _showRegisterPage() {
    setState(() {
      _showRegister = true;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
      _showRegister = false;
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    setState(() {
      _isAuthenticated = false;
      _showRegister = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return DashboardView(onLogout: _logout);
    }

    if (_showRegister) {
      return RegisterView(
        onLoginTap: _showLogin,
        onRegisterSuccess: _showLogin,
      );
    }

    return LoginView(
      onRegisterTap: _showRegisterPage,
      onLoginSuccess: _onLoginSuccess,
    );
  }
}