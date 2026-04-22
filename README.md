# GreenPulse

Plataforma móvil para monitoreo agronómico, gestión de proyectos de cultivo y trazabilidad operativa.

GreenPulse integra una aplicación Flutter y una API backend en Dart para registrar variables de campo (temperatura, humedad, pH), gestionar eventos operativos, generar alertas y exponer estadísticas de cultivo.

## Funcionalidades principales

### Gestión de acceso
- Registro y login con JWT.
- Persistencia de sesión local.
- Cierre de sesión y control de rutas protegidas.

### Gestión de proyectos y lotes
- Creación y listado de proyectos activos.
- Visualización de lotes con metadatos agronómicos.
- Desactivación de proyectos.

### Registros agronómicos
- Registro de temperatura, humedad y pH por lote.
- Listado paginado de historial de mediciones.
- Creación de registros desde la app con validaciones.

### Estadísticas y operación
- KPIs diarios y semanales por cultivo.
- Tendencias de variables críticas.
- Próximo riego y eventos operativos pendientes.

### Alertas y sincronización
- Configuración y consulta de alertas por umbrales.
- Marcado de alertas como leídas.
- Endpoints de sincronización push/pull para arquitectura offline-first.

## Stack tecnológico

### Frontend móvil
- Flutter (Dart)
- Arquitectura por capas en `lib/core`, `lib/models`, `lib/services`, `lib/views`
- Cliente HTTP con Dio
- Persistencia local con SharedPreferences y Flutter Secure Storage

### Backend API
- Dart + Shelf + Shelf Router
- MySQL con `mysql1`
- JWT con `dart_jsonwebtoken`
- Hash de contraseñas con `bcrypt`

## Estructura del proyecto

```text
lib/
	app_palette.dart
	main.dart
	core/
		api_client.dart
		constants.dart
	models/
		alerta.dart
		evento_operativo.dart
		lote.dart
		registro_agronomico.dart
		usuario.dart
	services/
		alertas_service.dart
		auth_service.dart
		cultivos_service.dart
		estadisticas_service.dart
		eventos_service.dart
		proyectos_service.dart
	views/
		activity_view.dart
		auth_view.dart
		home_view.dart
		profile_view.dart
		projects_view.dart
		settings_view.dart
	backend/
		app.dart
		server.dart
		config/
		controllers/
		middlewares/
		models/
		routes/
```

## Requisitos

- Flutter SDK 3.10+
- Dart SDK compatible con el proyecto
- MySQL 8+

## Configuración

### 1. Instalar dependencias

```bash
flutter pub get
```


### 2. Base URL del frontend

En emulador Android, la app consume por defecto:

`http://10.0.2.2:3000/api/v1`

Definido en `lib/core/constants.dart`.

## Ejecución

### App Flutter

```bash
flutter run
```

### Backend (desde una entrada Dart que invoque `startBackend()`)

La inicialización del backend está en `lib/backend/server.dart` y expone el arranque vía `startBackend()`.

## Endpoints principales

Base URL: `/api/v1`

### Auth
- `POST /auth/registro`
- `POST /auth/login`
- `POST /auth/refresh`

### Proyectos
- `GET /proyectos`
- `POST /proyectos`
- `GET /proyectos/:id`
- `PUT /proyectos/:id`
- `DELETE /proyectos/:id`

### Cultivos y registros
- `GET /proyectos/:proyecto_id/cultivos`
- `POST /proyectos/:proyecto_id/cultivos`
- `GET /cultivos/:cultivo_id`
- `PUT /cultivos/:cultivo_id`
- `DELETE /cultivos/:cultivo_id`

### Estadísticas
- `GET /cultivos/:cultivo_id/estadisticas`
- `GET /proyectos/:proyecto_id/reporte-mensual`

### Alertas
- `GET /alertas`
- `PATCH /alertas/:alerta_id/leida`

### Eventos
- `GET /eventos`
- `POST /eventos`
- `PATCH /eventos/:evento_id/completar`

### Sincronización
- `POST /sync/push`
- `GET /sync/pull?ultimo_sync=...`

### Health
- `GET /health`

## Estado actual del proyecto

- Pantallas principales conectadas a servicios reales.
- Gestión de sesión funcional con token JWT.
- Módulos backend implementados para autenticación, proyectos, cultivos, estadísticas, alertas, eventos y sincronización.

## Próximos pasos sugeridos

- Incorporar pruebas unitarias y de integración para servicios y controladores.
- Añadir notificaciones locales del sistema para alertas generadas.
- Separar backend en servicio independiente para despliegue productivo.
