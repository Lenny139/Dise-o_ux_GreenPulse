import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_palette.dart';
import '../core/app_language_controller.dart';
import '../core/app_theme_controller.dart';
import '../core/app_text.dart';
import '../backup/sync/sync_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'notifications_view.dart';

class OpcionesScreen extends StatefulWidget {
  const OpcionesScreen({super.key});

  @override
  State<OpcionesScreen> createState() => _OpcionesScreenState();
}

class _OpcionesScreenState extends State<OpcionesScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();

  // Perfil
  String _nombre = 'Usuario';
  String _correo = '-';
  bool _loadingPerfil = true;
  bool _loggingOut = false;

  // Ajustes
  bool _loadingAjustes = true;
  bool _saving = false;
  bool _haciendo_backup = false;
  bool _notificacionesActivas = true;
  bool _sonidosActivos = false;
  String _idioma = 'Español';
  String _tema = 'Claro (GreenPulse)';
  String _privacidadModo = 'Estándar';

  @override
  void initState() {
    super.initState();
    _loadPerfil();
    _loadAjustes();
  }

  // ─── Perfil ────────────────────────────────────────────────────────────────

  Future<void> _loadPerfil() async {
    try {
      await _authService.getPerfil();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _nombre = prefs.getString('usuario_nombre') ?? 'Usuario';
        _correo = prefs.getString('usuario_correo') ?? '-';
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPerfil = false);
    }
  }

  Future<void> _cerrarSesion() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _editarPerfilDialog() async {
    final nombreCtrl = TextEditingController(text: _nombre);
    final correoCtrl = TextEditingController(
      text: _correo == '-' ? '' : _correo,
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppText.t(es: 'Editar perfil', en: 'Edit profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: AppText.t(es: 'Nombre', en: 'Name'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppText.t(es: 'Correo', en: 'Email'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppText.t(es: 'Guardar', en: 'Save')),
          ),
        ],
      ),
    );

    if (save != true) return;

    final nombre = nombreCtrl.text.trim();
    final correo = correoCtrl.text.trim().toLowerCase();
    if (nombre.isEmpty || correo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppText.t(
                es: 'Nombre y correo son obligatorios',
                en: 'Name and email are required',
              ),
            ),
          ),
        );
      }
      return;
    }

    try {
      await _authService.actualizarPerfil(nombre: nombre, correo: correo);
      await _loadPerfil();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(es: 'Perfil actualizado', en: 'Profile updated'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _cambiarContrasenaDialog() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppText.t(es: 'Cambiar contraseña', en: 'Change password'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppText.t(
                  es: 'Contraseña actual',
                  en: 'Current password',
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nuevaCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppText.t(
                  es: 'Nueva contraseña',
                  en: 'New password',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppText.t(es: 'Actualizar', en: 'Update')),
          ),
        ],
      ),
    );

    if (save != true) return;

    if (actualCtrl.text.isEmpty || nuevaCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppText.t(
                es: 'Completa ambas contraseñas',
                en: 'Complete both passwords',
              ),
            ),
          ),
        );
      }
      return;
    }

    try {
      await _authService.cambiarContrasena(
        actualContrasena: actualCtrl.text,
        nuevaContrasena: nuevaCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Contraseña actualizada',
              en: 'Password updated',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ─── Ajustes ───────────────────────────────────────────────────────────────

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final s = value?.toString().trim().toLowerCase();
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return fallback;
  }

  Future<void> _loadAjustes() async {
    try {
      final data = await _settingsService.getAjustes();
      if (!mounted) return;
      setState(() {
        _notificacionesActivas = _asBool(
          data['notificaciones_activas'],
          fallback: true,
        );
        _sonidosActivos = _asBool(data['sonidos_activos'], fallback: false);
        _idioma = (data['idioma'] ?? 'Español').toString();
        _tema = (data['tema'] ?? 'Claro (GreenPulse)').toString();
        _privacidadModo = (data['privacidad_modo'] ?? 'Estándar').toString();
      });
      AppLanguageController.applyLanguageLabel(_idioma);
      AppThemeController.applyThemeLabel(_tema);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAjustes = false);
    }
  }

  Future<bool> _guardarAjuste(Map<String, dynamic> payload) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final data = await _settingsService.updateAjustes(payload);
      if (!mounted) return false;
      setState(() {
        _notificacionesActivas = _asBool(
          data['notificaciones_activas'],
          fallback: _notificacionesActivas,
        );
        _sonidosActivos = _asBool(
          data['sonidos_activos'],
          fallback: _sonidosActivos,
        );
        _idioma = (data['idioma'] ?? 'Español').toString();
        _tema = (data['tema'] ?? 'Claro (GreenPulse)').toString();
        _privacidadModo = (data['privacidad_modo'] ?? 'Estándar').toString();
      });
      AppLanguageController.applyLanguageLabel(_idioma);
      AppThemeController.applyThemeLabel(_tema);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _forzarBackup() async {
    if (_haciendo_backup) return;
    setState(() => _haciendo_backup = true);
    try {
      await SyncService.instance.sincronizar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: ' Backup completado',
              en: ' Backup completed',
            ),
          ),
          backgroundColor: AppPalette.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Error al hacer backup. Verifica tu conexión.',
              en: 'Backup failed. Check your connection.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _haciendo_backup = false);
    }
  }

  Future<void> _selectIdioma() async {
    final options = ['Español', 'English'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppText.t(es: 'Idioma', en: 'Language')),
        children: options
            .map(
              (o) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, o),
                child: Text(o),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == _idioma) return;
    await _guardarAjuste({'idioma': selected});
  }

  Future<void> _selectTema() async {
    final options = ['Claro (GreenPulse)', 'Oscuro'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppText.t(es: 'Tema', en: 'Theme')),
        children: options
            .map(
              (o) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, o),
                child: Text(o),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == _tema) return;
    await _guardarAjuste({'tema': selected});
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          AppText.t(es: 'Opciones', en: 'Options'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),

        // ── PERFIL ──────────────────────────────────────────────────────────
        _SectionHeader(label: AppText.t(es: 'Mi cuenta', en: 'My account')),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingPerfil
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppPalette.softSurfaceOf(context),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
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
                                fontSize: 16,
                                color: AppPalette.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              _correo,
                              style: TextStyle(
                                color: AppPalette.textSecondaryOf(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _editarPerfilDialog,
                        child: Text(AppText.t(es: 'Editar', en: 'Edit')),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: Icons.lock_outline_rounded,
          title: AppText.t(es: 'Cambiar contraseña', en: 'Change password'),
          onTap: _cambiarContrasenaDialog,
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: Icons.notifications_none_rounded,
          title: AppText.t(es: 'Notificaciones', en: 'Notifications'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),

        const SizedBox(height: 20),

        // ── AJUSTES ─────────────────────────────────────────────────────────
        _SectionHeader(label: AppText.t(es: 'Preferencias', en: 'Preferences')),
        const SizedBox(height: 8),
        Card(
          child: _loadingAjustes
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor: AppPalette.softSurfaceOf(context),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppPalette.primary,
                        ),
                      ),
                      title: Text(
                        AppText.t(es: 'Notificaciones', en: 'Notifications'),
                      ),
                      subtitle: Text(
                        AppText.t(
                          es: 'Alertas de riego y eventos',
                          en: 'Irrigation and event alerts',
                        ),
                      ),
                      value: _notificacionesActivas,
                      onChanged: _saving
                          ? null
                          : (v) async {
                              final prev = _notificacionesActivas;
                              setState(() => _notificacionesActivas = v);
                              final ok = await _guardarAjuste(
                                {'notificaciones_activas': v},
                              );
                              if (!ok && mounted) {
                                setState(() => _notificacionesActivas = prev);
                              }
                            },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor: AppPalette.softSurfaceOf(context),
                        child: const Icon(
                          Icons.volume_up_outlined,
                          color: AppPalette.primary,
                        ),
                      ),
                      title: Text(AppText.t(es: 'Sonidos', en: 'Sounds')),
                      subtitle: Text(
                        AppText.t(
                          es: 'Avisos de actividad',
                          en: 'Activity tones',
                        ),
                      ),
                      value: _sonidosActivos,
                      onChanged: _saving
                          ? null
                          : (v) async {
                              final prev = _sonidosActivos;
                              setState(() => _sonidosActivos = v);
                              final ok = await _guardarAjuste(
                                {'sonidos_activos': v},
                              );
                              if (!ok && mounted) {
                                setState(() => _sonidosActivos = prev);
                              }
                            },
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: Icons.language_rounded,
          title: AppText.t(es: 'Idioma', en: 'Language'),
          trailing: _idioma,
          onTap: _selectIdioma,
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: Icons.palette_outlined,
          title: AppText.t(es: 'Tema', en: 'Theme'),
          trailing: _tema,
          onTap: _selectTema,
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _haciendo_backup ? null : _forzarBackup,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppPalette.softSurfaceOf(context),
                    child: _haciendo_backup
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.cloud_download_rounded,
                            color: AppPalette.primary,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.t(
                            es: 'Forzar backup local',
                            en: 'Force local backup',
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          AppText.t(
                            es: 'Descarga todos los datos al dispositivo',
                            en: 'Download all data to device',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppPalette.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── CERRAR SESIÓN ────────────────────────────────────────────────────
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _loggingOut ? null : _cerrarSesion,
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(AppText.t(es: 'Cerrar sesión', en: 'Log out')),
        ),

        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppPalette.textSecondaryOf(context),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
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
        subtitle: trailing != null
            ? Text(
                trailing!,
                style: TextStyle(color: AppPalette.textSecondaryOf(context)),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
