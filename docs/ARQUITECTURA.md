# ARQUITECTURA DEL SISTEMA TICKETERO

## 1. VISIÓN GENERAL

Sistema de gestión de tickets con control de tiempos de atención, roles de usuario, dashboard de métricas, puesto físicos por área, configuración de kioskos y pantalla llamador en ventana independiente. Desarrollado con Clean Architecture.

**Stack tecnológico:**
- **Frontend:** Flutter 3.x (Windows) — Provider + ChangeNotifier
- **Backend:** .NET Core 8 / C# (estructura creada, pendiente producción)
- **Base de datos:** SQL Server 2022 (scripts listos)
- **Comunicación:** REST API + WebSocket (SignalR)
- **Ventana secundaria:** `desktop_multi_window` + `WindowMethodChannel`
- **Estado actual:** Funcionando 100% con datos mock (DataStore en memoria + SharedPreferences)

---

## 2. ESTRUCTURA DE CARPETAS

```
sistema_ticketero/
└── lib/
    ├── main.dart                          # Entry point, providers setup, window management
    ├── app.dart                           # Routes + AuthGate (role-based routing)
    │
    ├── core/
    │   ├── cache/                         # In-memory data store for mock/dev mode
    │   │   ├── data_store.dart            # Singleton con datos semilla + CRUD
    │   │   └── models/
    │   │       ├── cached_user.dart
    │   │       ├── cached_area.dart
    │   │       └── cached_ticket.dart
    │   ├── constants/
    │   │   ├── api_constants.dart
    │   │   └── app_constants.dart
    │   ├── enums/
    │   │   ├── ticket_type.dart           # caja, informacion, inscripcion, documentacion
    │   │   ├── ticket_status.dart         # pendiente, llamado, en_atencion, completado, cancelado
    │   │   └── user_role.dart            # administrador, usuario_atencion, usuario_llamador
    │   ├── errors/
    │   │   ├── failures.dart
    │   │   └── exceptions.dart
    │   ├── network/
    │   │   ├── api_client.dart            # Dio singleton with JWT interceptor
    │   │   ├── websocket_service.dart     # SignalR con reconexión exponencial
    │   │   └── network_info.dart
    │   ├── printing/
    │   │   ├── printing_provider.dart
    │   │   ├── esc_pos_commands.dart
    │   │   ├── network_escpos_printer.dart
    │   │   ├── windows_printer_service.dart
    │   │   ├── serial_escpos_printer.dart
    │   │   ├── print_service.dart
    │   │   └── ticket_print_data.dart
    │   ├── theme/
    │   │   ├── app_theme.dart
    │   │   └── app_colors.dart
    │   └── utils/
    │       ├── date_utils.dart
    │       ├── validators.dart
    │       ├── logger.dart
    │       └── area_logo_presets.dart
    │
    ├── data/
    │   ├── datasources/
    │   │   ├── remote/
    │   │   │   ├── ticket_remote_datasource.dart
    │   │   │   ├── user_remote_datasource.dart
    │   │   │   ├── auth_remote_datasource.dart
    │   │   │   ├── area_remote_datasource.dart
    │   │   │   └── dashboard_remote_datasource.dart
    │   │   └── local/
    │   │       ├── auth_local_datasource.dart
    │   │       └── ticket_local_datasource.dart
    │   ├── models/
    │   │   ├── ticket_model.dart
    │   │   ├── user_model.dart
    │   │   ├── area_model.dart
    │   │   ├── attention_log_model.dart
    │   │   ├── auth_response_model.dart
    │   │   └── dashboard_stats_model.dart
    │   └── repositories/
    │       ├── ticket_repository_impl.dart
    │       ├── user_repository_impl.dart
    │       ├── area_repository_impl.dart
    │       ├── auth_repository_impl.dart
    │       └── dashboard_repository_impl.dart
    │
    ├── domain/
    │   ├── entities/
    │   │   ├── ticket.dart
    │   │   ├── user.dart
    │   │   ├── area.dart
    │   │   ├── attention_log.dart
    │   │   ├── dashboard_stats.dart
    │   │   ├── puesto_info.dart           # Puesto físico por área (NUEVO)
    │   │   └── kiosko_location.dart       # Ubicación física de kiosko (NUEVO)
    │   ├── repositories/
    │   │   ├── ticket_repository.dart
    │   │   ├── user_repository.dart
    │   │   ├── area_repository.dart
    │   │   ├── auth_repository.dart
    │   │   └── dashboard_repository.dart
    │   └── usecases/
    │       ├── ticket/
    │       │   ├── create_ticket.dart
    │       │   ├── call_ticket.dart
    │       │   ├── complete_ticket.dart
    │       │   ├── cancel_ticket.dart
    │       │   ├── get_pending_tickets.dart
    │       │   └── get_ticket_stats.dart
    │       ├── user/
    │       │   ├── create_user.dart
    │       │   ├── update_user.dart
    │       │   ├── delete_user.dart
    │       │   └── get_users.dart
    │       ├── auth/
    │       │   ├── login.dart
    │       │   └── logout.dart
    │       └── area/
    │           ├── create_area.dart
    │           ├── update_area.dart
    │           └── get_areas.dart
    │
    └── presentation/
        ├── layout/
        │   ├── app_shell.dart             # Shared layout with Sidebar + TopBar
        │   ├── sidebar.dart
        │   └── topbar.dart
        ├── providers/
        │   ├── auth_provider.dart
        │   ├── ticket_provider.dart
        │   ├── dashboard_provider.dart
        │   ├── area_provider.dart
        │   ├── settings_provider.dart
        │   └── user_management_provider.dart
        └── screens/
            ├── login/login_screen.dart
            ├── ticket_selection/
            │   ├── ticket_selection_screen.dart
            │   └── widgets/
            │       ├── area_selector_card.dart
            │       ├── service_type_card.dart
            │       ├── ticket_display.dart
            │       ├── step_indicator.dart
            │       └── background_video_widget.dart
            ├── kiosko_selection/kiosko_selection_screen.dart  # (NUEVO)
            ├── puesto_selection/puesto_selection_screen.dart   # (NUEVO)
            ├── attention/attention_screen.dart
            ├── caller/caller_screen.dart
            ├── dashboard/dashboard_screen.dart
            ├── gestion/gestion_screen.dart
            ├── admin/admin_screen.dart
            └── settings/
                ├── settings_screen.dart
                └── widgets/
                    ├── user_management_panel.dart
                    ├── area_management_panel.dart
                    ├── kiosko_management_panel.dart   # (NUEVO)
                    ├── video_config_panel.dart
                    ├── printer_config_panel.dart
                    └── system_config_panel.dart

    └── window/
        ├── ticket_channel.dart            # CallerChannel: WindowMethodChannel bridge
        └── caller_app.dart                # Standalone sub-window app for caller display
```

---

## 3. RUTAS (app.dart)

| Ruta | Screen | Acceso | Notas |
|---|---|---|---|
| `/ticket` | `TicketSelectionScreen` | Público | Pantalla autoservicio kiosko (initial route) |
| `/kiosko-selection` | `KioskoSelectionScreen` | caller | Selección de ubicación física del kiosko |
| `/login` | `LoginScreen` | Público | Autenticación de usuarios |
| `/puesto-selection` | `PuestoSelectionScreen` | atencion | Selección de puesto físico post-login |
| `/attention` | `AttentionScreen` | atencion | Panel del agente para llamar/atender tickets |
| `/dashboard` | `DashboardScreen` | admin | Métricas y estadísticas |
| `/caller` | `CallerScreen` | caller | Display público de tickets llamados |
| `/settings` | `SettingsScreen` | admin | Panel de configuración general |
| `/gestion` | `GestionScreen` | admin/caller | Gestión de operadores/usuarios |
| `/admin` | `AdminScreen` | admin | Panel legacy de pruebas |

---

## 4. DIAGRAMAS DE FLUJO

### 4.1 Flujo General del Sistema

```
[Cliente/Kiosko]               [Agente/Atención]              [Llamador/Caller]
      |                               |                              |
      |--(1) Llega al kiosko -->      |                              |
      |--(2) Selecciona área -->      |                              |
      |--(3) Recibe ticket ----       |                              |
      |                               |                              |
      |                      (4) Login agente -->                    |
      |                      (5) Selecciona puesto físico            |
      |                               |                              |
      |                      (6) "Llamar siguiente"                  |
      |                               |--------- (7) Broadcast ----> |
      |<-(8) Monitor/TV muestra ----- |                              |
      |       "Pase a Puesto 1"       |                              |
      |                               |                              |
      |                      (9) Inicia atención                     |
      |                      (10) Finaliza atención                  |
      |                      (11) Log automático:                    |
      |                           - Tiempo inicio                    |
      |                           - Tiempo fin                       |
      |                           - Tiempo total                     |
      |                               |                              |
      |                      (12) Dashboard (admin)                  |
      |                           - Tickets/día                      |
      |                           - Tiempo promedio                  |
      |                           - Por agente                       |
```

### 4.2 Flujo de Autenticación y Selección de Puesto

```
[Login] --> ¿Rol?
  ├── admin     --> /dashboard
  ├── caller    --> ¿Kiosko seleccionado?
  │                ├── Sí  --> /ticket
  │                └── No  --> /kiosko-selection --> /ticket
  └── atencion  --> /puesto-selection
                   ├── Muestra puestos del área del usuario
                   ├── Usuario selecciona puesto disponible
                   ├── Se marca como ocupado (occupiedByUserId)
                   └── --> /attention
                        Al logout: libera puesto vía SettingsProvider.freePuesto()
```

### 4.3 Flujo de Configuración de Puestos (Admin)

```
Admin → Settings → Áreas → Botón "Puestos"
  └── _PuestoLayoutDialog (responsive Wrap)
       ├── Lista puestos existentes con candado si ocupados
       ├── Botón "Agregar" → diálogo nombre → PuestoInfo(id, nombre)
       ├── Botón eliminar en cada puesto libre
       └── "Guardar" → SettingsProvider.setPuestosForArea() → SharedPreferences
```

### 4.4 Flujo de Configuración del Sistema (Admin)

```
Admin → Settings → Sistema
  ├── Tarjeta "Conexión al Servidor"
  │   ├── Campo URL del servidor API (persistido)
  │   └── Botón "Probar conexión" → GET /api/health (Dio, timeout 5s)
  ├── Tarjeta "Atención al Cliente"
  │   ├── Tiempo estimado de espera (minutos, persistido)
  │   └── Máximo tickets por día (persistido)
  ├── Tarjeta "Información"
  │   └── Versión de la aplicación
  └── Botón "Guardar configuración" → persiste todo
```

### 4.5 Flujo de Kiosko

```
Configuración:
  Admin → Settings → Kioskos
    ├── Lista ubicaciones (KioskoLocation: id, nombre, areaIds)
    ├── Crear/Editar/Eliminar
    └── Seleccionar kiosko activo → setSelectedKioskoId()

Uso:
  caller login → /kiosko-selection
    ├── Muestra lista de ubicaciones configuradas
    ├── Usuario selecciona una → setSelectedKioskoId()
    └── --> /ticket (filtra áreas según kioskoAreaIds)
```

---

## 5. ENTIDADES DEL DOMINIO

### User
| Campo | Tipo | Notas |
|---|---|---|
| id | int | |
| nombreUsuario | String | Login único |
| nombreCompleto | String | Nombre para mostrar |
| email | String | |
| rol | UserRole | administrador / usuario_atencion / usuario_llamador |
| areaId | int? | Área principal |
| areaNombre | String? | |
| puesto | String? | (deprecated, ahora se usa PuestoInfo) |
| areasAtencion | List<int> | IDs de áreas que puede atender |
| activo | bool | |
| ultimoAcceso | DateTime? | |

### Ticket
| Campo | Tipo | Notas |
|---|---|---|
| id | int | |
| codigoTicket | String | Ej: "CAJA-001" |
| tipoTicket | TicketType | |
| areaId | int | |
| areaNombre | String | |
| status | TicketStatus | pendiente/llamado/en_atencion/completado/cancelado |
| llamadoPorUserId | int? | |
| createdAt | DateTime | |
| updatedAt | DateTime? | |
| tiempoEsperaSegundos | int? | |
| tiempoAtencionSegundos | int? | |
| prioridad | int | 0=normal, 1=derivado |
| derivadoDe | String? | Ticket origen si derivado |
| derivadoDeNombre | String? | Área origen |

### Area
| Campo | Tipo |
|---|---|
| id | int |
| nombre | String |
| prefijo | String |
| logoUrl | String |
| activo | bool |

### AttentionLog
| Campo | Tipo |
|---|---|
| id | int |
| ticketId | int |
| userId | int |
| userName | String? |
| codigoTicket | String? |
| areaId | int? |
| areaNombre | String? |
| llamadoAt | DateTime |
| iniciadoAt | DateTime? |
| completadoAt | DateTime? |
| tiempoSegundos | int? |
| observacion | String? |

### PuestoInfo (NUEVO)
| Campo | Tipo | Notas |
|---|---|---|
| id | int | ID único por área |
| nombre | String | Ej: "Caja 1", "Mesa 3" |
| occupiedByUserId | int? | null = disponible |

### KioskoLocation (NUEVO)
| Campo | Tipo | Notas |
|---|---|---|
| id | int | |
| nombre | String | Nombre de ubicación |
| areaIds | Set<int> | IDs de áreas que ofrece este kiosko |

### DashboardStats
| Campo | Tipo |
|---|---|
| totalTickets | int |
| totalAtendidos | int |
| totalPendientes | int |
| tiempoPromedioAtencionSegundos | int |
| tiempoPromedioEsperaSegundos | int |
| periodoInicio | DateTime |
| periodoFin | DateTime |

---

## 6. PROVIDERS (ESTADO GLOBAL)

| Provider | Responsabilidad | Persistencia |
|---|---|---|
| AuthProvider | Sesión, autenticación, puesto seleccionado | Memoria |
| TicketProvider | Ciclo de vida de tickets, cola, atención | DataStore (memoria) |
| SettingsProvider | Configuración general, videos, kioskos, puestos | SharedPreferences |
| AreaProvider | CRUD de áreas | DataStore (memoria) |
| UserManagementProvider | CRUD de usuarios | DataStore (memoria) |
| DashboardProvider | Estadísticas del dashboard | DataStore (memoria) |
| PrintingProvider | Configuración de impresora | Memoria |

### Conexiones entre providers
- `AuthProvider.attachSettings(SettingsProvider)` → llamado en main.dart
- `SettingsProvider.addListener(() => ticketProvider.setVideoCallerScreen(...))` → main.dart
- `TicketProvider.broadcastToCaller()` → envía estado a ventana secundaria vía WindowMethodChannel

---

## 7. PERSISTENCIA (SharedPreferences)

| Clave | Tipo | Descripción |
|---|---|---|
| `video_ticket` | String? | URL video pantalla ticket |
| `video_caller` | String? | URL video pantalla caller |
| `kiosko_locations` | String (JSON) | Lista de KioskoLocation |
| `selected_kiosko_id` | String? | ID del kiosko seleccionado |
| `puestos_por_area` | String (JSON) | Mapa areaId → List<PuestoInfo> |
| `server_url` | String | URL del servidor API |
| `tiempo_estimado` | int | Minutos estimados de espera |
| `max_tickets` | int | Máximo tickets por día |
| `window_x/y/width/height` | int | Posición/tamaño de ventana |

---

## 8. VENTANA SECUNDARIA (CALLER DISPLAY)

- **Paquete:** `desktop_multi_window`
- **Comunicación:** `WindowMethodChannel` (`sistema_ticketero/caller`)
- **Flujo:**
  1. Caller login → verifica si ya existe ventana caller
  2. Si no existe → `WindowController.create(args: 'caller')`
  3. `CallerWindowApp` corre como `MaterialApp` independiente
  4. `TicketProvider.notifyListeners()` → `broadcastToCaller()` → `CallerChannel.sendState(json)`
  5. Ventana caller recibe vía `CallerChannel.setHandler()` → `TicketProvider.updateFromChannel()`

---

## 9. REGLAS DE NEGOCIO

1. Ticket se crea siempre con status `pendiente`
2. Solo un ticket `en_atencion` por usuario a la vez
3. Tiempo atención = `completado_at - iniciado_at`
4. Tiempo espera = `llamado_at - created_at`
5. Admin ve todos los tickets; agente solo los de su área
6. Prefijo ticket: `[PrefijoArea]-[NúmeroSecuencial]`
7. Derivación: ticket derivado obtiene `prioridad=1`, se inserta en 2ª posición de la cola
8. buildQueueForArea: normales primero (FIFO), luego prioritarios (FIFO)
9. Puesto físico se marca ocupado al seleccionar, se libera al logout
10. Un puesto ocupado no es seleccionable por otro usuario
11. Si se elimina un área, su layout de puestos también se elimina
12. KioskoLocation filtra qué áreas están disponibles en cada ubicación
13. El DataStore contiene datos semilla que permiten funcionar sin backend

---

## 10. REFERENCIA DE TECLAS (ATENCIÓN)

| Tecla | Acción |
|---|---|
| F1 | Llamar siguiente ticket |
| F2 | Iniciar atención |
| F3 | Finalizar atención |
| F4 | Derivar ticket a otra área |

---

## 11. ENUMERACIONES

```dart
enum UserRole { administrador, usuario_atencion, usuario_llamador }
enum TicketStatus { pendiente, llamado, en_atencion, completado, cancelado }
enum TicketType { caja, informacion, inscripcion, documentacion }
enum AgentState { libre, enAtencion, pausa }  // Atención local
enum DashboardPeriod { hoy, semana, mes }
```
