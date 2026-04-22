import '../repositories/alertas_repository.dart';
import '../repositories/cultivos_repository.dart';
import '../repositories/proyectos_repository.dart';
import '../repositories/registros_repository.dart';
import '../../services/alertas_service.dart';
import '../../services/cultivos_service.dart';
import '../../services/proyectos_service.dart';

/// Sincroniza todos los datos del backend hacia SQLite local.
/// Llama a [sincronizar] después de cada operación exitosa con el backend.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _proyectosService = ProyectosService();
  final _cultivosService  = CultivosService();
  final _alertasService   = AlertasService();

  final _proyectosRepo = ProyectosRepository.instance;
  final _cultivosRepo  = CultivosRepository.instance;
  final _registrosRepo = RegistrosRepository.instance;
  final _alertasRepo   = AlertasRepository.instance;

  bool _sincronizando = false;

  /// Sincroniza todo: proyectos, cultivos, registros y alertas.
  /// Si el backend no responde, no lanza error — simplemente usa lo que
  /// ya está en local.
  Future<void> sincronizar() async {
    if (_sincronizando) return;
    _sincronizando = true;

    try {
      await _sincronizarProyectosYCultivos();
      await _sincronizarAlertas();
    } catch (_) {
      // Silencioso: si falla la sync, los datos locales siguen disponibles
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _sincronizarProyectosYCultivos() async {
    final proyectos = await _proyectosService.getProyectos();
    await _proyectosRepo.guardarProyectos(proyectos);

    for (final proyecto in proyectos) {
      try {
        final cultivos = await _cultivosService.getCultivos(proyecto.id);
        await _cultivosRepo.guardarCultivos(proyecto.id, cultivos);

        // Sincronizar registros de cada cultivo activo (hasta 20 más recientes)
        for (final cultivo in cultivos) {
          if (cultivo.estado == 'activo') {
            try {
              final registros = await _cultivosService.getRegistros(
                cultivo.id,
                limit: 20,
              );
              await _registrosRepo.guardarRegistros(cultivo.id, registros);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _sincronizarAlertas() async {
    final alertas = await _alertasService.getAlertas();
    await _alertasRepo.guardarAlertas(alertas);
  }

  /// Sincroniza solo los registros de un cultivo específico.
  /// Útil después de crear un nuevo registro.
  Future<void> sincronizarRegistros(int cultivoId) async {
    try {
      final registros = await _cultivosService.getRegistros(
        cultivoId,
        limit: 20,
      );
      await _registrosRepo.guardarRegistros(cultivoId, registros);
    } catch (_) {}
  }

  /// Sincroniza solo los cultivos de un proyecto específico.
  Future<void> sincronizarCultivos(int proyectoId) async {
    try {
      final cultivos = await _cultivosService.getCultivos(proyectoId);
      await _cultivosRepo.guardarCultivos(proyectoId, cultivos);
    } catch (_) {}
  }
}
