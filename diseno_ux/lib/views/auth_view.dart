import 'package:flutter/material.dart';

import '../app_palette.dart';
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
        const SnackBar(content: Text('Registro exitoso. Ahora inicia sesión.')),
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Iniciar Sesión'),
              Tab(text: 'Registrarse'),
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
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Ingresa tu correo'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _loginContrasenaCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingresa tu contraseña'
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
                          : const Text('Iniciar Sesión'),
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
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registroCorreoCtrl,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Ingresa tu correo'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registroContrasenaCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingresa tu contraseña'
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
                          : const Text('Registrarse'),
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
