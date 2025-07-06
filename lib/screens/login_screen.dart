  import 'package:flutter/material.dart';
  import '../services/auth_service.dart';
  import 'register_screen.dart';
  import 'home_screen.dart';

  class LoginScreen extends StatefulWidget {
    const LoginScreen({Key? key}) : super(key: key);

    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    final _authService = AuthService();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String? _errorMessage;

    void _login() async {
      try {
        final user = await _authService.signIn(
            _emailController.text.trim(), _passwordController.text.trim());
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration:
                const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: const Text('Login')),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Register a new account'),
              )
            ],
          ),
        ),
      );
    }
  }
