import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/cultivo.dart';
import '../models/proyecto.dart';
import '../services/cultivos_service.dart';
import '../services/proyectos_service.dart';

/// Flujo completo del QR:
/// 1. Selecciona proyecto y cultivo destino
/// 2. Escanea el QR (debe contener JSON con temperatura, humedad, ph)
/// 3. Muestra formulario prellenado + observaciones
/// 4. Guarda el registro
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _proyectosService = ProyectosService();
  final _cultivosService  = CultivosService();

  // Paso 1 — selección
  bool _loadingProyectos = true;
  List<Proyecto> _proyectos = const [];
  List<Cultivo>  _cultivos  = const [];
  Proyecto? _proyectoSel;
  Cultivo?  _cultivoSel;

  // Paso 2 — escaneo
  bool _escaneando = false;
  bool _qrLeido    = false;

  // Paso 3 — confirmación
  final _tempCtrl = TextEditingController();
  final _humCtrl  = TextEditingController();
  final _phCtrl   = TextEditingController();
  final _obsCtrl  = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _phCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // ─── Carga datos ───────────────────────────────────────────────────────────

  Future<void> _cargarProyectos() async {
    try {
      final data = await _proyectosService.getProyectos();
      if (!mounted) return;
      setState(() => _proyectos = data);
      if (data.length == 1) await _seleccionarProyecto(data.first);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProyectos = false);
    }
  }

  Future<void> _seleccionarProyecto(Proyecto p) async {
    setState(() {
      _proyectoSel = p;
      _cultivoSel  = null;
      _cultivos    = const [];
    });
    try {
      final cultivos = await _cultivosService.getCultivos(p.id);
      if (!mounted) return;
      setState(() => _cultivos = cultivos);
      if (cultivos.isNotEmpty) {
        final activo = cultivos.firstWhere(
          (c) => c.estado == 'activo',
          orElse: () => cultivos.first,
        );
        setState(() => _cultivoSel = activo);
      }
    } catch (_) {}
  }

  // ─── QR ────────────────────────────────────────────────────────────────────

  void _onQrDetectado(BarcodeCapture capture) {
    if (_qrLeido) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;

      final temp   = _toDouble(map['temperatura'] ?? map['temp'] ?? map['t']);
      final hum    = _toDouble(map['humedad']     ?? map['hum']  ?? map['h']);
      final ph     = _toDouble(map['ph']          ?? map['pH']   ?? map['p']);

      if (temp == null || hum == null || ph == null) {
        _mostrarErrorQr(
          AppText.t(
            es: 'El QR no contiene temperatura, humedad y pH.',
            en: 'QR does not contain temperature, humidity and pH.',
          ),
        );
        return;
      }

      setState(() {
        _qrLeido    = true;
        _escaneando = false;
        _tempCtrl.text = temp.toString();
        _humCtrl.text  = hum.toString();
        _phCtrl.text   = ph.toString();
      });
    } catch (_) {
      _mostrarErrorQr(
        AppText.t(
          es: 'QR inválido. Debe ser un JSON con temperatura, humedad y ph.',
          en: 'Invalid QR. Must be JSON with temperatura, humedad and ph.',
        ),
      );
    }
  }

  void _mostrarErrorQr(String msg) {
    if (!mounted) return;
    setState(() => _escaneando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _reiniciarEscaneo() => setState(() {
        _qrLeido    = false;
        _escaneando = true;
        _tempCtrl.clear();
        _humCtrl.clear();
        _phCtrl.clear();
        _obsCtrl.clear();
      });

  // ─── Guardar registro ──────────────────────────────────────────────────────

  Future<void> _guardarRegistro() async {
    if (_cultivoSel == null) return;

    final temp = double.tryParse(_tempCtrl.text.trim());
    final hum  = double.tryParse(_humCtrl.text.trim());
    final ph   = double.tryParse(_phCtrl.text.trim());

    if (temp == null || hum == null || ph == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Verifica que temperatura, humedad y pH sean números válidos.',
              en: 'Check that temperature, humidity and pH are valid numbers.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await _cultivosService.crearRegistro(
        _cultivoSel!.id,
        {
          'temperatura_celsius': temp,
          'humedad_relativa':    hum,
          'ph_suelo':            ph,
          'observaciones':       _obsCtrl.text.trim(),
          'metodo_ingreso':      'QR',
        },
      );

      if (!mounted) return;

      final alertas = _cultivosService.lastAlertasGeneradas;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alertas > 0
              ? AppText.t(
                  es: '✅ Registro guardado · ⚠️ $alertas alerta(s) generada(s)',
                  en: '✅ Record saved · ⚠️ $alertas alert(s) generated',
                )
              : AppText.t(
                  es: '✅ Registro guardado correctamente',
                  en: '✅ Record saved successfully',
                )),
          backgroundColor: AppPalette.primary,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.t(es: 'Registrar por QR', en: 'Register via QR')),
      ),
      body: _loadingProyectos
          ? const Center(child: CircularProgressIndicator())
          : _proyectos.isEmpty
              ? _SinProyectos()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Paso 1: Selección ──────────────────────────────
                      _StepHeader(
                        numero: '1',
                        titulo: AppText.t(
                          es: 'Selecciona el cultivo destino',
                          en: 'Select target crop',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SelectorCard(
                        icono: Icons.folder_open_rounded,
                        label: AppText.t(es: 'Proyecto', en: 'Project'),
                        valor: _proyectoSel?.nombre ??
                            AppText.t(
                              es: 'Selecciona un proyecto',
                              en: 'Select a project',
                            ),
                        onTap: _proyectos.length > 1
                            ? _mostrarSelectorProyecto
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _SelectorCard(
                        icono: Icons.eco_rounded,
                        label: AppText.t(es: 'Cultivo', en: 'Crop'),
                        valor: _cultivoSel?.displayName ??
                            (_proyectoSel == null
                                ? AppText.t(
                                    es: 'Elige un proyecto primero',
                                    en: 'Choose a project first',
                                  )
                                : _cultivos.isEmpty
                                    ? AppText.t(
                                        es: 'Sin cultivos',
                                        en: 'No crops',
                                      )
                                    : AppText.t(
                                        es: 'Selecciona un cultivo',
                                        en: 'Select a crop',
                                      )),
                        onTap: _cultivos.length > 1
                            ? _mostrarSelectorCultivo
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // ── Paso 2: Escaneo ────────────────────────────────
                      _StepHeader(
                        numero: '2',
                        titulo: AppText.t(
                          es: 'Escanea el código QR',
                          en: 'Scan the QR code',
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (!_escaneando && !_qrLeido)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _cultivoSel == null
                                ? null
                                : () => setState(() => _escaneando = true),
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: Text(
                              AppText.t(
                                es: 'Abrir cámara',
                                en: 'Open camera',
                              ),
                            ),
                          ),
                        ),

                      if (_escaneando) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 280,
                            child: Stack(
                              children: [
                                MobileScanner(
                                  onDetect: _onQrDetectado,
                                ),
                                // Overlay guía
                                Center(
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppPalette.accent,
                                        width: 2.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            AppText.t(
                              es: 'Apunta la cámara al código QR',
                              en: 'Point the camera at the QR code',
                            ),
                            style: TextStyle(
                              color: AppPalette.textSecondaryOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _escaneando = false),
                          child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
                        ),
                      ],

                      if (_qrLeido) ...[
                        Card(
                          color: AppPalette.primary.withValues(alpha: 0.08),
                          child: ListTile(
                            leading: const Icon(
                              Icons.check_circle_rounded,
                              color: AppPalette.primary,
                            ),
                            title: Text(
                              AppText.t(
                                es: 'QR leído correctamente',
                                en: 'QR read successfully',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppPalette.primary,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _reiniciarEscaneo,
                              child: Text(
                                AppText.t(es: 'Re-escanear', en: 'Re-scan'),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Paso 3: Confirmación ───────────────────────
                        _StepHeader(
                          numero: '3',
                          titulo: AppText.t(
                            es: 'Confirma los datos',
                            en: 'Confirm the data',
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _tempCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppText.t(
                              es: 'Temperatura °C',
                              en: 'Temperature °C',
                            ),
                            prefixIcon: const Icon(Icons.thermostat_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _humCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                AppText.t(es: 'Humedad %', en: 'Humidity %'),
                            prefixIcon:
                                const Icon(Icons.water_drop_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'pH',
                            prefixIcon: Icon(Icons.science_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _obsCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: AppText.t(
                              es: 'Observaciones (opcional)',
                              en: 'Notes (optional)',
                            ),
                            prefixIcon: const Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _guardando ? null : _guardarRegistro,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              AppText.t(
                                es: 'Guardar registro',
                                en: 'Save record',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  // ─── Selectores ────────────────────────────────────────────────────────────

  Future<void> _mostrarSelectorProyecto() async {
    final sel = await showModalBottomSheet<Proyecto>(
      context: context,
      builder: (ctx) => _BottomSheetSelector<Proyecto>(
        titulo: AppText.t(es: 'Seleccionar proyecto', en: 'Select project'),
        items: _proyectos,
        labelBuilder: (p) => p.nombre,
        subtitleBuilder: (p) => p.tipo,
        selectedId: _proyectoSel?.id,
        idBuilder: (p) => p.id,
      ),
    );
    if (sel != null && sel.id != _proyectoSel?.id) {
      await _seleccionarProyecto(sel);
    }
  }

  Future<void> _mostrarSelectorCultivo() async {
    final sel = await showModalBottomSheet<Cultivo>(
      context: context,
      builder: (ctx) => _BottomSheetSelector<Cultivo>(
        titulo: AppText.t(es: 'Seleccionar cultivo', en: 'Select crop'),
        items: _cultivos,
        labelBuilder: (c) => c.displayName,
        subtitleBuilder: (c) => c.plantaNombre ?? '',
        selectedId: _cultivoSel?.id,
        idBuilder: (c) => c.id,
      ),
    );
    if (sel != null) setState(() => _cultivoSel = sel);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.numero, required this.titulo});
  final String numero;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppPalette.primary,
          child: Text(
            numero,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.icono,
    required this.label,
    required this.valor,
    required this.onTap,
  });
  final IconData icono;
  final String label;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppPalette.softSurfaceOf(context),
          child: Icon(icono, color: AppPalette.primary, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppPalette.textSecondary),
        ),
        subtitle: Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.expand_more_rounded)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _BottomSheetSelector<T> extends StatelessWidget {
  const _BottomSheetSelector({
    required this.titulo,
    required this.items,
    required this.labelBuilder,
    required this.subtitleBuilder,
    required this.selectedId,
    required this.idBuilder,
  });
  final String titulo;
  final List<T> items;
  final String Function(T) labelBuilder;
  final String Function(T) subtitleBuilder;
  final int? selectedId;
  final int Function(T) idBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final sel = idBuilder(item) == selectedId;
            return ListTile(
              title: Text(labelBuilder(item)),
              subtitle: Text(subtitleBuilder(item)),
              trailing: sel
                  ? const Icon(Icons.check_rounded, color: AppPalette.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, item),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SinProyectos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              AppText.t(
                es: 'No tienes proyectos aún.\nCrea uno en la pestaña Proyectos.',
                en: 'No projects yet.\nCreate one in the Projects tab.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textSecondaryOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
