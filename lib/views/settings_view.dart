import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_language_controller.dart';
import '../core/app_theme_controller.dart';
import '../core/app_text.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();

  bool _loading = true;
  bool _saving = false;

  bool _notificacionesActivas = true;
  bool _sonidosActivos = false;
  String _idioma = 'Español';
  String _tema = 'Claro (GreenPulse)';
  String _privacidadModo = 'Estándar';

  @override
  void initState() {
    super.initState();
    _loadAjustes();
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
    return fallback;
  }

  Future<void> _loadAjustes() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAjustes();
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _guardarParcial(Map<String, dynamic> payload) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final data = await _service.updateAjustes(payload);
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
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleNotificaciones(bool value) async {
    if (_saving || value == _notificacionesActivas) return;
    final previous = _notificacionesActivas;
    setState(() => _notificacionesActivas = value);
    final saved = await _guardarParcial({'notificaciones_activas': value});
    if (!saved && mounted) {
      setState(() => _notificacionesActivas = previous);
    }
  }

  Future<void> _toggleSonidos(bool value) async {
    if (_saving || value == _sonidosActivos) return;
    final previous = _sonidosActivos;
    setState(() => _sonidosActivos = value);
    final saved = await _guardarParcial({'sonidos_activos': value});
    if (!saved && mounted) {
      setState(() => _sonidosActivos = previous);
    }
  }

  Future<void> _selectIdioma() async {
    final options = const [
      {'value': 'Español', 'label': 'Español'},
      {'value': 'English', 'label': 'English'},
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppText.t(es: 'Idioma', en: 'Language')),
        children: options
            .map(
              (option) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option['value'] as String),
                child: Text(option['label'] as String),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == _idioma) return;
    await _guardarParcial({'idioma': selected});
  }

  Future<void> _selectTema() async {
    final options = ['Claro (GreenPulse)', 'Oscuro'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tema'),
        children: options
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, value),
                child: Text(value),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == _tema) return;
    await _guardarParcial({'tema': selected});
  }

  Future<void> _selectPrivacidad() async {
    final options = ['Estándar', 'Estricto'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Privacidad'),
        children: options
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, value),
                child: Text(value),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == _privacidadModo) return;
    await _guardarParcial({'privacidad_modo': selected});
  }

  void _openAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'GreenPulse',
      applicationVersion: '1.0.0',
      children: const [
        Text('Aplicación para monitoreo y gestión agronómica.'),
      ],
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
          AppText.t(es: 'Ajustes', en: 'Settings'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppText.t(
            es: 'Configura tus preferencias principales de la aplicación.',
            en: 'Configure your main app preferences.',
          ),
          style: TextStyle(color: AppPalette.textSecondaryOf(context)),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              _SettingSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: AppText.t(es: 'Notificaciones', en: 'Notifications'),
                subtitle: AppText.t(
                  es: 'Alertas de riego y eventos',
                  en: 'Irrigation and event alerts',
                ),
                value: _notificacionesActivas,
                onChanged: _saving ? null : _toggleNotificaciones,
              ),
              const Divider(height: 1),
              _SettingSwitchTile(
                icon: Icons.volume_up_outlined,
                title: AppText.t(es: 'Sonidos', en: 'Sounds'),
                subtitle: AppText.t(
                  es: 'Avisos de actividad y alertas',
                  en: 'Activity and alert tones',
                ),
                value: _sonidosActivos,
                onChanged: _saving ? null : _toggleSonidos,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SettingOptionTile(
          icon: Icons.language_rounded,
          title: AppText.t(es: 'Idioma', en: 'Language'),
          subtitle: _idioma,
          onTap: _selectIdioma,
        ),
        const SizedBox(height: 8),
        _SettingOptionTile(
          icon: Icons.palette_outlined,
          title: AppText.t(es: 'Tema', en: 'Theme'),
          subtitle: _tema,
          onTap: _selectTema,
        ),
        const SizedBox(height: 8),
        _SettingOptionTile(
          icon: Icons.security_rounded,
          title: AppText.t(es: 'Privacidad', en: 'Privacy'),
          subtitle: _privacidadModo,
          onTap: _selectPrivacidad,
        ),
        const SizedBox(height: 8),
        _SettingOptionTile(
          icon: Icons.info_outline_rounded,
          title: AppText.t(es: 'Acerca de', en: 'About'),
          subtitle: AppText.t(es: 'Versión 1.0.0', en: 'Version 1.0.0'),
          onTap: _openAbout,
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

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppPalette.softSurfaceOf(context),
        child: Icon(icon, color: AppPalette.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _SettingOptionTile extends StatelessWidget {
  const _SettingOptionTile({
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
