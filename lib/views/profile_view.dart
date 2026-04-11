import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_palette.dart';
import '../services/auth_service.dart';
import 'notifications_view.dart';

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
      await _authService.getPerfil();
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

  Future<void> _editarPerfilDialog() async {
    final nombreCtrl = TextEditingController(text: _nombre);
    final correoCtrl = TextEditingController(text: _correo == '-' ? '' : _correo);

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (save != true) return;

    final nombre = nombreCtrl.text.trim();
    final correo = correoCtrl.text.trim().toLowerCase();
    if (nombre.isEmpty || correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y correo son obligatorios')),
      );
      return;
    }

    try {
      await _authService.actualizarPerfil(nombre: nombre, correo: correo);
      await _loadPerfil();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _cambiarContrasenaDialog() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            TextField(
              controller: nuevaCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (save != true) return;

    final actualContrasena = actualCtrl.text;
    final nuevaContrasena = nuevaCtrl.text;

    if (actualContrasena.isEmpty || nuevaContrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ambas contraseñas')),
      );
      return;
    }

    try {
      await _authService.cambiarContrasena(
        actualContrasena: actualContrasena,
        nuevaContrasena: nuevaContrasena,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _openHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda y soporte'),
        content: const Text(
          'Si tienes problemas, escríbenos a soporte@greenpulse.app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppPalette.softSurfaceOf(context),
                  child: const Icon(
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
                          color: AppPalette.textPrimaryOf(context),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _correo,
                        style: TextStyle(
                          color: AppPalette.textSecondaryOf(context),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Productor',
                        style: TextStyle(
                          color: AppPalette.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _editarPerfilDialog,
                  child: const Text('Editar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 10),
        _ProfileActionTile(
          icon: Icons.badge_outlined,
          title: 'Datos personales',
          subtitle: 'Nombre, correo y teléfono',
          onTap: _editarPerfilDialog,
        ),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Seguridad',
          subtitle: 'Contraseña y acceso',
          onTap: _cambiarContrasenaDialog,
        ),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notificaciones',
          subtitle: 'Recordatorios y alertas',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Ayuda y soporte',
          subtitle: 'Centro de ayuda',
          onTap: _openHelp,
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppPalette.softSurfaceOf(context),
          child: Icon(icon, color: AppPalette.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
