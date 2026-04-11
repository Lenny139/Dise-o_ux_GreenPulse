import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/lote.dart';
import '../services/proyectos_service.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key, required this.loteId});

  final int loteId;

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  final _service = ProyectosService();
  final _nombreCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Lote? _lote;

  @override
  void initState() {
    super.initState();
    _loadProyecto();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _tipoCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProyecto() async {
    setState(() => _loading = true);
    try {
      final lote = await _service.getProyecto(widget.loteId);
      if (!mounted) return;

      _nombreCtrl.text = lote.nombre;
      _tipoCtrl.text = lote.tipoCultivo ?? '';
      _areaCtrl.text = lote.areaM2?.toString() ?? '';
      setState(() => _lote = lote);
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

  Future<void> _guardarCambios() async {
    if (_saving) return;

    final nombre = _nombreCtrl.text.trim();
    final tipoCultivo = _tipoCtrl.text.trim();
    final areaText = _areaCtrl.text.trim();
    final areaM2 = areaText.isEmpty ? null : double.tryParse(areaText);

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    if (areaText.isNotEmpty && areaM2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El área debe ser un número válido')),
      );
      return;
    }

    final data = <String, dynamic>{
      'nombre': nombre,
      'tipo_cultivo': tipoCultivo,
    };
    if (areaM2 != null) {
      data['area_m2'] = areaM2;
    }

    setState(() => _saving = true);
    try {
      final updated = await _service.actualizarProyecto(widget.loteId, data);
      if (!mounted) return;
      setState(() => _lote = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proyecto actualizado')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar proyecto')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_lote != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'ID: lote_${_lote!.loteId} · Estado: ${_lote!.activo == 1 ? 'Activo' : 'Inactivo'}',
                        style: TextStyle(
                          color: AppPalette.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tipoCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo de cultivo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _areaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Área m²'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _guardarCambios,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
    );
  }
}
