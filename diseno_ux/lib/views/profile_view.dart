import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_palette.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  String _nombre = 'Usuario';
  String _correo = '-';
  bool _loading = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _nombre = prefs.getString('usuario_nombre') ?? 'Usuario';
        _correo = prefs.getString('usuario_correo') ?? '-';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cerrarSesion() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFEAF6F0),
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: AppPalette.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _correo,
                        style: TextStyle(color: AppPalette.textSecondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Productor',
                        style: TextStyle(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Editar')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const _ProfileActionTile(
          icon: Icons.badge_outlined,
          title: 'Datos personales',
          subtitle: 'Nombre, correo y teléfono',
        ),
        const SizedBox(height: 8),
        const _ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Seguridad',
          subtitle: 'Contraseña y acceso',
        ),
        const SizedBox(height: 8),
        const _ProfileActionTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notificaciones',
          subtitle: 'Recordatorios y alertas',
        ),
        const SizedBox(height: 8),
        const _ProfileActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Ayuda y soporte',
          subtitle: 'Centro de ayuda',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _loggingOut ? null : _cerrarSesion,
          icon: const Icon(Icons.logout_rounded),
          label: _loggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF6F0),
          child: Icon(icon, color: AppPalette.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
