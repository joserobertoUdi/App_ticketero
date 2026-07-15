# ANÁLISIS COMPLETO DEL SISTEMA — SISTEMA TICKETERO

> Documento de análisis estructural que mapea todos los datos, flujos, dependencias y estados del sistema.
> Propósito: servir como base para organización, refactorización y toma de decisiones técnicas.

---

## 1. MAPA DE ENTIDADES Y RELACIONES

### 1.1 Entidades de Dominio (Domain Layer)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SISTEMA TICKETERO                            │
│                     Mapa de Entidades y Relaciones                  │
└─────────────────────────────────────────────────────────────────────┘

  ┌─────────────┐         ┌──────────────────┐        ┌───────────────┐
  │    Area     │         │      User        │        │    Ticket     │
  ├─────────────┤         ├──────────────────┤        ├───────────────┤
  │ id: int     │◄────────│ areaId: int?     │        │ id: int       │
  │ nombre: str │  FK     │ nombreUsuario    │        │ codigo: str   │
  │ prefijo:str │         │ nombreCompleto   │        │ tipoTicket    │
  │ logoUrl     │         │ email            │◄───────│ areaId: int   │
  │ activo: bool│         │ rol: UserRole    │  FK    │ status        │
  └──────┬──────┘         │ areasAtencion[]  │        │ prioridad:int │
         │                │ activo: bool     │        │ derivadoDe    │
         │                └──────────────────┘        └───────┬───────┘
         │                                                    │
         │  ┌─────────────────────┐        ┌──────────────────┘
         │  │    PuestoInfo       │        │
         │  ├─────────────────────┤        │
         │  │ id: int             │        │
         │  │ nombre: str         │        │
         │  │ occupiedByUserId    │◄───────┤ (FK opcional → User.id)
         │  └─────────────────────┘        │
         │                                 │
         │  ┌─────────────────────┐        │
         │  │  KioskoLocation     │        │
         │  ├─────────────────────┤        │
         │  │ id: int             │        │
         │  │ nombre: str         │        │
         │  │ areaIds: Set<int>   │────────┤ (FK → Area.id)
         │  └─────────────────────┘        │
         │                                 │
         │  ┌─────────────────────┐        │
         │  │   AttentionLog      │        │
         │  ├─────────────────────┤        │
         │  │ ticketId: int       │────────┤ (FK → Ticket.id)
         │  │ userId: int         │────────┤ (FK → User.id)
         │  │ llamadoAt / ...     │        │
         │  └─────────────────────┘        │
         │                                 │
         │  ┌─────────────────────┐        │
         │  │   DashboardStats    │        │
         │  ├─────────────────────┤        │
         │  │ totalTickets        │        │
         │  │ ... (solo lectura)  │        │
         │  └─────────────────────┘        │
         └─────────────────────────────────┘
```

### 1.2 Cardinalidades

| Desde | Hacia | Tipo | Descripción |
|---|---|---|---|
| Area | User | 1:N | Un área tiene muchos usuarios |
| Area | Ticket | 1:N | Un área tiene muchos tickets |
| Area | PuestoInfo | 1:N | Un área tiene muchos puestos físicos |
| Area | KioskoLocation | N:M | Vía areaIds (Set) |
| User | PuestoInfo | 1:1 | Un usuario ocupa un puesto (occupiedByUserId) |
| Ticket | AttentionLog | 1:1 | Un ticket genera un log de atención |
| User | AttentionLog | 1:N | Un usuario atiende muchos tickets |

---

## 2. MAPA DE PROVIDERS Y DEPENDENCIAS

### 2.1 Grafo de Dependencias

```
main.dart
  ├── AuthProvider ──────────────► SettingsProvider  (attachSettings)
  ├── TicketProvider ────────────► (broadcastToCaller → CallerChannel)
  │     └── SettingsProvider (listener: videoCallerScreen)
  ├── SettingsProvider
  ├── AreaProvider
  ├── DashboardProvider
  ├── PrintingProvider
  ├── UserManagementProvider
  └── WebSocketService (Provider<WebSocketService>)
```

### 2.2 Tabla de Providers

| Provider | Instancia en main | Repositorio | Persistencia | Depende de |
|---|---|---|---|---|
| AuthProvider | Singleton | AuthRepository? (nullable) | Memoria | SettingsProvider |
| TicketProvider | Singleton | TicketRepository? (nullable) | DataStore (memoria) | — |
| SettingsProvider | Singleton | — | SharedPreferences | — |
| AreaProvider | Singleton | AreaRepository? (nullable) | DataStore (memoria) | — |
| DashboardProvider | Singleton | DashboardRepository? (nullable) | DataStore (memoria) | — |
| PrintingProvider | Singleton | — | Memoria | — |
| UserManagementProvider | Singleton | — | DataStore (memoria) | — |
| WebSocketService | Provider.value | — | — | — |

### 2.3 Mecanismos de notificación

| Disparador | Acción | Canal |
|---|---|---|
| TicketProvider.notifyListeners() | broadcastToCaller() | WindowMethodChannel |
| SettingsProvider.notifyListeners() | ticketProvider.setVideoCallerScreen() | addListener (main.dart) |
| AuthProvider.setPuestoSeleccionado() | Actualiza _puestoAreaId, _puestoId | Memoria local |
| AuthProvider.logout() | SettingsProvider.freePuesto() | Llamada directa |

---

## 3. MAPA DE RUTAS Y FLUJO DE NAVEGACIÓN

### 3.1 Árbol de Navegación

```
App (MaterialApp)
  ├── /ticket              → TicketSelectionScreen  (initialRoute)
  │                           └── tras crear ticket → auto-return 8s
  ├── /kiosko-selection    → KioskoSelectionScreen
  │                           └── selecciona kiosko → /ticket
  ├── /login               → LoginScreen
  │                           └── login exitoso → AuthGate decide:
  │                                admin     → /dashboard
  │                                caller    → /kiosko-selection (o /ticket si ya hay kiosko)
  │                                atencion  → /puesto-selection
  ├── /puesto-selection    → PuestoSelectionScreen
  │                           └── confirmar puesto → /attention
  ├── /attention           → AttentionScreen
  ├── /caller              → CallerScreen  (también en sub-ventana)
  ├── /dashboard           → DashboardScreen
  ├── /settings            → SettingsScreen
  │                           └── NavigationRail con 6 paneles
  ├── /gestion             → GestionScreen (AppShell + tabs)
  └── /admin               → AdminScreen (legacy)

AuthGate (widget en app.dart):
  - No autenticado → LoginScreen
  - admin  → DashboardScreen
  - caller → CallerScreen
  - atencion → AttentionScreen
```

### 3.2 Flujo de Autenticación Detallado

```
Usuario ingresa credenciales
  → AuthProvider.login(nombreUsuario, password)
    → ¿AuthRepository existe?
      ├── Sí → authRepository.login(creds) → User + Token
      └── No → _mockLogin()
                ├── ¿Coincide con DataStore.getUserByUsername()?
                │     └── Sí → User
                ├── ¿Coincide con hardcoded?
                │     ├── admin/Admin123! → User(rol: admin)
                │     ├── ana/123 → User(rol: atencion, areaId: 1)
                │     └── carlos/123 → User(rol: caller)
                └── No → null (error)
    → ¿User != null?
      ├── Sí → guarda user + token, notifyListeners()
      │        → AuthGate > Navigator.pushReplacementNamed según rol
      └── No → set errorMessage, return false
```

### 3.3 Flujo de Ticket (Creación → Atención → Completado)

```
Kiosko:
  1. TicketSelectionScreen: selecciona área
  2. TicketProvider.createTicket(areaId)
  3. DataStore.createTicket() → genera código "PREFIJO-NNN"
  4. Ticket agregado a _pendingTickets, ordenado FIFO
  5. notifyListeners() → broadcastToCaller()

Agente (Attention):
  6. callNextTicket(areaId, puesto: puestoSeleccionado)
  7. buildQueueForArea(areaId): 
     - Normales (prioridad=0) primero FIFO
     - Prioritarios (prioridad>0) después, primer prioritario en índice 1
  8. Toma primer ticket de cola → status "llamado"
  9. _lastCalledTicket = ticket, _activeAttention = ticket
  10. Añade a _recentCalls (máx 20)
  11. notifyListeners() → broadcastToCaller()

  12. startAttention(codigoTicket) → status "en_atencion"
  13. Timer _attentionStartedAt inicia

  14. completeAttention(observacion?) → status "completado"
  15. Calcula duración, crea AttentionLog
  16. Limpia _activeAttention, _attentionStartedAt
  17. notifyListeners() → broadcastToCaller()

Derivación:
  18. deriveTicket(codigoTicket, targetAreaId)
  19. DataStore.deriveTicket():
      - Nuevo ticket en área destino con prioridad=1
      - Registra derivadoDe, derivadoDeNombre
  20. Se inserta en posición 2 de la cola destino
```

---

## 4. MAPA DE ESTADOS

### 4.1 Estados de Ticket

```
                  ┌──────────┐
                  │ PENDIENTE│
                  └────┬─────┘
                       │ callNextTicket()
                       ▼
                  ┌──────────┐
           ┌──────│ LLAMADO  │──────┐
           │      └──────────┘      │
           │                        │
    startAttention()          deriveTicket()
           │                        │
           ▼                        ▼
    ┌──────────────┐         ┌────────────┐
    │ EN_ATENCION  │         │ DERIVADO   │
    └──────┬───────┘         └────────────┘
           │
    completeAttention()
           │
           ▼
    ┌──────────────┐
    │ COMPLETADO   │
    └──────────────┘

    (CANCELADO puede ocurrir desde PENDIENTE o LLAMADO)
```

### 4.2 Estados del Agente (AttentionScreen)

```
         ┌───────┐
         │ LIBRE │◄────────────────────────┐
         └───┬───┘                         │
             │ callNextTicket()            │
             ▼                             │
         ┌──────────┐                      │
         │ LLAMANDO │ (ticket llamado,     │
         └───┬──────┘  esperando cliente)  │
             │ startAttention()            │
             ▼                             │
         ┌─────────────┐                   │
         │ EN_ATENCION │                   │
         └──────┬──────┘                   │
             │ completeAttention()         │
             ▼                             │
         ┌──────────┐                      │
         │ COMPLETO │──────────────────────┘
         └──────────┘
```

### 4.3 Estados del Puesto (PuestoInfo)

```
         ┌──────────────┐
         │  DISPONIBLE  │
         │ (userId null)│
         └──────┬───────┘
                │ occupyPuesto(userId)
                ▼
         ┌──────────────┐
         │  OCUPADO     │
         │ (userId set) │
         └──────┬───────┘
                │ freePuesto()
                ▼
         ┌──────────────┐
         │  DISPONIBLE  │
         └──────────────┘
```

---

## 5. PERSISTENCIA Y ALMACENAMIENTO

### 5.1 SharedPreferences (Claves)

| Clave | Tipo | Dónde se usa | Valor ejemplo |
|---|---|---|---|
| `video_ticket` | String? | SettingsProvider | `"C:/videos/fondo.mp4"` |
| `video_caller` | String? | SettingsProvider | `"C:/videos/caller.mp4"` |
| `kiosko_locations` | String(JSON) | SettingsProvider | `[{"id":1,"nombre":"Entrada","areaIds":[1,2]}]` |
| `selected_kiosko_id` | String? | SettingsProvider | `"1"` |
| `puestos_por_area` | String(JSON) | SettingsProvider | `{"1":[{"id":1,"nombre":"Caja 1", "occupiedByUserId":null}]}` |
| `server_url` | String | SettingsProvider | `"http://localhost:5000"` |
| `tiempo_estimado` | int | SettingsProvider | `5` |
| `max_tickets` | int | SettingsProvider | `500` |
| `window_x` | int | WindowCloseHandler | `100` |
| `window_y` | int | WindowCloseHandler | `100` |
| `window_width` | int | WindowCloseHandler | `1280` |
| `window_height` | int | WindowCloseHandler | `720` |

### 5.2 DataStore (Memoria — Mock)

| Colección | Tipo | Seed data |
|---|---|---|
| `_users` | `List<CachedUser>` | admin, ana, carlos |
| `_areas` | `List<CachedArea>` | Caja, Informacion, Inscripcion, Documentacion |
| `_tickets` | `List<CachedTicket>` | Vacío (se crean en ejecución) |

### 5.3 Archivos de Video

Los videos se almacenan como strings de ruta de archivo (path local). No hay un storage centralizado — el administrador selecciona archivos locales cuyo path se guarda en SharedPreferences.

---

## 6. MODELO DE COMUNICACIÓN ENTRE VENTANAS

### 6.1 CallerChannel (WindowMethodChannel)

```
Nombre del canal: "sistema_ticketero/caller"

Main Window → Caller Window:
  Método: invokeMethod('ticketState', jsonPayload)
  Payload: CallerTicketState serializado

Caller Window → Main Window:
  No hay comunicación de vuelta (unidireccional)

Trigger: TicketProvider.notifyListeners()
  → broadcastToCaller()
  → toCallerState() arma CallerTicketState
  → CallerChannel.sendState(jsonEncode(state.toJson()))
```

### 6.2 CallerTicketState (Payload)

```dart
{
  "activeCodigo": "CAJA-001",
  "lastCalledCodigo": "CAJA-001",
  "lastCalledArea": "Caja",
  "lastCalledPriority": false,
  "lastCalledDerivadoDe": null,
  "lastCalledDerivadoDeNombre": null,
  "recentCalls": [
    {"codigoTicket": "CAJA-001", "areaNombre": "Caja", ...}
  ],
  "history": [...],
  "historyCodigos": ["CAJA-001", "CAJA-002"],
  "videoCallerScreen": "C:/videos/fondo.mp4"
}
```

### 6.3 Flujo de Ventanas

```
main.dart (proceso principal)
  │
  ├── Ventana principal con MultiProvider
  │   ├── WindowManager (posición, tamaño, cierre)
  │   └── App → rutas normales
  │
  └── DesktopMultiWindow.create(args: 'caller')
      └── CallerWindowApp (MaterialApp independiente)
          ├── Providers: AuthProvider, TicketProvider, SettingsProvider
          ├── CallerChannel escucha cambios
          └── CallerScreen (display público animado)
```

---

## 7. ANÁLISIS DE ROLES Y PERMISOS

### 7.1 Matriz de Acceso por Rol

| Pantalla / Acción | admin | atencion | caller | Anónimo |
|---|---|---|---|---|
| Ticket Selection (kiosko) | — | — | ✅ | ✅ |
| Login | — | — | — | ✅ |
| Puesto Selection | — | ✅ | — | — |
| Atención (F1-F4) | — | ✅ | — | — |
| Caller Display | — | — | ✅ | — |
| Dashboard | ✅ | — | — | — |
| Settings (todos los paneles) | ✅ | — | — | — |
| Gestión (operadores/usuarios) | ✅ | ✅ | ✅ | — |
| Admin (legacy) | ✅ | — | — | — |
| Kiosko Selection | — | — | ✅ | — |

### 7.2 Roles Definidos (UserRole)

| Valor enum | Display | auth_provider getter | Acceso típico |
|---|---|---|---|
| `administrador` | "Administrador" | `isAdmin` | Dashboard + Settings |
| `usuario_atencion` | "Atención" | `isAttentionUser` | PuestoSelection → Attention |
| `usuario_llamador` | "Llamador" | `isCaller` | KioskoSelection → TicketSelection |

---

## 8. CONFIGURACIÓN DEL SISTEMA

### 8.1 Parámetros de Configuración

| Parámetro | Default | Rango | UI | Persistencia |
|---|---|---|---|---|
| `serverUrl` | `http://localhost:5000` | URL válida | SystemConfigPanel (TextField) | SharedPreferences |
| `tiempoEstimadoMinutos` | 5 | 1-999 | SystemConfigPanel (TextField) | SharedPreferences |
| `maxTicketsPorDia` | 500 | 1-9999 | SystemConfigPanel (TextField) | SharedPreferences |
| `videoTicketScreen` | null | Path archivo | VideoConfigPanel (FilePicker) | SharedPreferences |
| `videoCallerScreen` | null | Path archivo | VideoConfigPanel (FilePicker) | SharedPreferences |
| `kioskoLocations` | [] | — | KioskoManagementPanel (CRUD) | SharedPreferences (JSON) |
| `selectedKioskoId` | null | ID existente | KioskoManagementPanel (select) | SharedPreferences |
| `puestosPorArea` | {} | Mapa int→List<PuestoInfo> | AreaManagementPanel (_PuestoLayoutDialog) | SharedPreferences (JSON) |

### 8.2 Connection Test

```
SystemConfigPanel._testConnection()
  → Dio.get('$serverUrl/api/health')
  → Timeout 5s
  → Maneja DioException (timeout, socket, conexión)
  → Muestra resultado: "Conexión exitosa ✓" o mensaje de error
```

---

## 9. MÉTRICAS Y DASHBOARD

### 9.1 DashboardProvider: Métricas disponibles

| Métrica | Tipo | Cómo se calcula (mock) |
|---|---|---|
| totalTickets | int | 142 |
| totalAtendidos | int | 130 |
| totalPendientes | int | 12 |
| tiempoPromedioAtencionSegundos | int | 272 (~4:32 min) |
| tiempoPromedioEsperaSegundos | int | 185 (~3:05 min) |
| areaStats | `List<AreaStats>` | Por área (Caja:60, Info:35, Insc:25, Doc:30) |
| userStats | `List<UserStats>` | Por agente (Ana, Luis, Juan) |
| hourlyBreakdown | `List<HourlyBreakdown>` | Tickets por hora (simulado) |
| selectedPeriod | DashboardPeriod | hoy / semana / mes |

### 9.2 DashboardPeriod

| Valor | Descripción |
|---|---|
| `hoy` | Datos del día actual |
| `semana` | Datos de los últimos 7 días |
| `mes` | Datos del mes actual |

---

## 10. ANÁLISIS DE RIESGOS Y DEUDA TÉCNICA

### 10.1 Riesgos Identificados

| # | Riesgo | Impacto | Probabilidad | Mitigación |
|---|---|---|---|---|
| R1 | SharedPreferences sin migración (cambio de estructura JSON) | Medio | Alta | Versionar claves o migrar a SQLite |
| R2 | DataStore en memoria → pérdida de datos al reiniciar | Alto | Alta | Ya es intencional (modo dev) |
| R3 | Provider notifica a caller window aunque no exista | Bajo | Media | Verificar existencia del canal antes de broadcast |
| R4 | Ocupación de puesto no se libera si la app se cierra abruptamente | Medio | Media | heartbeat/keepalive o timeout de ocupación |
| R5 | CallerTicketState crece con historyCodigos ilimitado | Bajo | Baja | Cap en TicketProvider (historial acotado) |
| R6 | Sistema sin autenticación real (mock) expuesto | Alto | Alta | Sólo en desarrollo; producción requiere backend |

### 10.2 Deuda Técnica

| # | Item | Prioridad | Estimado |
|---|---|---|---|
| DT1 | `_PuestoLayoutDialog` usa `Provider.of` sin `listen: false` en initState | Baja | 15 min |
| DT2 | AdminScreen es legacy duplicado de Settings + Gestion | Media | 2 h (eliminar) |
| DT3 | Sistema de logging subutilizado (logger.dart importado pero no usado) | Baja | 1 h |
| DT4 | Falta manejo de errores en SettingsProvider.loadSettings() catch genérico | Media | 30 min |
| DT5 | Variables de entorno/compilación para URL de API (ahora hardcodeada) | Alta | 2 h |

---

## 11. GLOSARIO DE TÉRMINOS

| Término | Definición |
|---|---|
| Ticket | Solicitud de servicio generada en kiosko con código único |
| Puesto | Estación física de atención (Caja 1, Mesa 3, etc.) |
| Atención | Proceso de llamar, iniciar y completar un ticket |
| Derivación | Redirección de un ticket de un área a otra |
| Área | Departamento de servicio (Caja, Información, etc.) |
| Kiosko | Ubicación física del terminal de autoservicio |
| Caller Display | Pantalla pública que muestra tickets llamados |
| Puesto Selection | Pantalla post-login donde el agente elige su estación |
| Provider | ChangeNotifier que gestiona estado global (patrón Provider) |
| DataStore | Singleton en memoria con datos semilla para modo desarrollo |
| SharedPreferences | Almacenamiento local clave-valor para config persistente |
| WindowMethodChannel | Puente de comunicación entre ventanas Flutter |
| AuthGate | Widget que redirige según rol autenticado |

---

## 12. ESTADÍSTICAS DEL PROYECTO

| Métrica | Valor |
|---|---|
| Total archivos Dart | ~90 |
| Líneas de código (aproximado) | ~15,000 |
| Providers | 7 |
| Screens | 10 |
| Entities | 7 |
| Widgets reutilizables | ~20 |
| Rutas | 9 |
| Dependencias pubspec | 14 |
| Errores flutter analyze | 0 |
| Ventanas (main + sub) | 2 |

---

*Documento generado el 25/06/2026 — Próxima revisión sugerida: cada 2 semanas o tras cambios estructurales significativos.*
