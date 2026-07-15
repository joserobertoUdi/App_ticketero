# Sistema Ticketero

Sistema de gestión de tickets con control de tiempos, roles de usuario, dashboard de métricas y panel de pruebas funcionales.

## Stack tecnológico
- **Frontend:** Flutter 3.x (Windows)
- **Backend:** .NET Core 8 / C# (opcional, funciona en modo simulación)
- **Base de datos:** SQL Server 2022 (opcional, funciona con DataStore en memoria)
- **Comunicación:** REST API + WebSocket (SignalR)
- **Estado:** Provider
- **Video:** `video_player` + `video_player_win` (Windows)

## Inicio rápido

```bash
flutter pub get
flutter run -d windows
```

### Credenciales por defecto (modo simulación)
| Usuario   | Contraseña | Rol       |
|-----------|-----------|-----------|
| admin     | admin     | Admin     |
| llamador  | 1234      | Llamador  |
| atencion  | 1234      | Atención  |
| caja1     | 1234      | Atención  |

## Vistas del Sistema

| Vista       | Ruta        | Descripción                                  |
|-------------|-------------|----------------------------------------------|
| Tickets     | `/ticket`   | Pantalla pública para sacar ticket           |
| Login       | `/login`    | Inicio de sesión de personal                 |
| Atención    | `/attention`| Pantalla del agente para llamar/atender      |
| Llamador    | `/caller`   | Panel de llamado con pantalla completa       |
| Dashboard   | `/dashboard`| Métricas y estadísticas                      |
| Gestión     | `/gestion`  | Administración de usuarios y áreas           |
| Config      | `/settings` | Configuración de videos y sistema            |
| **Pruebas** | `/admin`    | Panel de pruebas con CRUD y simulación       |

## DataStore en Memoria

El sistema incluye un `DataStore` singleton (`lib/core/cache/`) que permite:
- CRUD de usuarios con roles (admin, llamador, atención)
- CRUD de áreas de atención
- Simulación completa del flujo de tickets (crear, llamar, atender)
- Funciona sin backend ni base de datos
- Útil para pruebas funcionales y demostraciones

## Características implementadas

- [x] Selección de área y tipo de servicio
- [x] Generación de tickets con código único por área (CAJA-001, INFO-001, etc.)
- [x] Llamado de tickets (agente → pantalla)
- [x] Atención con control de tiempos (inicio/fin)
- [x] Historial de llamados recientes
- [x] Dashboard con métricas en tiempo real
- [x] Video de fondo configurable por pantalla
- [x] Header auto-ocultable con hover (opción de fijar)
- [x] Pantalla completa en panel llamador
- [x] Autenticación con roles (admin, atención, llamador)
- [x] Cache en memoria con DataStore (funciona sin backend)
- [x] Panel de pruebas funcionales (CRUD + simulación)
- [x] Soporte Windows con video (video_player_win)
- [x] **Derivación de tickets entre áreas** con prioridad (F4 en atención)
- [x] **Prioridad en cola de espera** (ticket derivado = 2° en ser llamado)
- [x] **Asignación de áreas de atención por usuario** (multi-select en CRUD)
- [x] **CRUD completo de usuarios** con roles, áreas de atención, correo electrónico, buscador y agrupación por área
- [x] **Estados visuales en panel llamador** (parpadeo = llamado no atendido, verde = en atención, opaco = completado)
- [x] **API lista para integración con .NET Core** (modelos con fromJson/toJson, repositorios implementados)
