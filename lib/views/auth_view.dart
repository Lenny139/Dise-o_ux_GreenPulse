import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _loginFormKey = GlobalKey<FormState>();
  final _registroFormKey = GlobalKey<FormState>();

  final _loginCorreoCtrl = TextEditingController();
  final _loginContrasenaCtrl = TextEditingController();

  final _registroNombreCtrl = TextEditingController();
  final _registroCorreoCtrl = TextEditingController();
  final _registroContrasenaCtrl = TextEditingController();

  bool _loadingLogin = false;
  bool _loadingRegistro = false;

  @override
  void dispose() {
    _loginCorreoCtrl.dispose();
    _loginContrasenaCtrl.dispose();
    _registroNombreCtrl.dispose();
    _registroCorreoCtrl.dispose();
    _registroContrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _loadingLogin = true);
    try {
      await _authService.login(
        _loginCorreoCtrl.text.trim(),
        _loginContrasenaCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingLogin = false);
    }
  }

  Future<void> _registro() async {
    if (!_registroFormKey.currentState!.validate()) return;

    setState(() => _loadingRegistro = true);
    try {
      await _authService.registro(
        _registroNombreCtrl.text.trim(),
        _registroCorreoCtrl.text.trim(),
        _registroContrasenaCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Registro exitoso. Ahora inicia sesión.',
              en: 'Registration successful. Please sign in now.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingRegistro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GreenPulse'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildLoginTab(), _buildRegistroTab()]),
      ),
    );
  }

  Widget _buildLoginTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _loginFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _loginCorreoCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(es: 'Correo', en: 'Email'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? AppText.t(es: 'Ingresa tu correo', en: 'Enter your email')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _loginContrasenaCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(es: 'Contraseña', en: 'Password'),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppText.t(
                            es: 'Ingresa tu contraseña',
                            en: 'Enter your password',
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadingLogin ? null : _login,
                      child: _loadingLogin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppText.t(es: 'Iniciar Sesión', en: 'Sign in')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _registroFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _registroNombreCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(es: 'Nombre', en: 'Name'),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? AppText.t(es: 'Ingresa tu nombre', en: 'Enter your name')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registroCorreoCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(es: 'Correo', en: 'Email'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? AppText.t(es: 'Ingresa tu correo', en: 'Enter your email')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registroContrasenaCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(es: 'Contraseña', en: 'Password'),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppText.t(
                            es: 'Ingresa tu contraseña',
                            en: 'Enter your password',
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.secondary,
                      ),
                      onPressed: _loadingRegistro ? null : _registro,
                      child: _loadingRegistro
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppText.t(es: 'Registrarse', en: 'Register')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
