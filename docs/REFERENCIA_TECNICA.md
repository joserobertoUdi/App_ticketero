# REFERENCIA TÉCNICA COMPLETA

## SISTEMA TICKETERO - Documentación Técnica Unificada

---

## 1. CONFIGURACIÓN DEL SERVIDOR

### 1.1 Archivo appsettings.json (Backend .NET Core)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=192.168.1.101,1433;Database=TicketeroDB;User Id=ticketero_user;Password=YourStr0ngP@ss;TrustServerCertificate=True;Connection Timeout=30;Max Pool Size=50;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": { "Url": "http://0.0.0.0:5000" },
      "WebSocket": { "Url": "http://0.0.0.0:5001" }
    }
  },
  "JwtSettings": {
    "SecretKey": "YourSuperSecretKeyAtLeast32CharactersLong!",
    "Issuer": "TicketeroAPI",
    "Audience": "TicketeroClient",
    "ExpirationMinutes": 480
  },
  "TicketSettings": {
    "EstimatedWaitMinutes": 5,
    "MaxTicketsPerDay": 500,
    "TicketPrefixFormat": "{0}-{1:D4}"
  },
  "VideoSettings": {
    "StoragePath": "C:\\Ticketero\\Storage\\Videos",
    "MaxFileSizeMb": 100,
    "AllowedFormats": [".mp4", ".avi", ".mov"]
  }
}
```

### 1.2 Configuración Cliente Flutter (pubspec.yaml actual)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  dio: ^5.4.3+1
  dartz: ^0.10.1
  flutter_secure_storage: ^9.2.2
  intl: ^0.19.0
  fl_chart: ^0.69.0
  video_player: ^2.9.1
  video_player_win: ^3.0.0
  shared_preferences: ^2.3.1
  signalr_netcore: ^1.3.6
  file_picker: ^11.0.2
  desktop_multi_window: ^0.3.0
  window_manager: ^0.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## 2. DIAGRAMAS DE FLUJO DETALLADOS

### 2.1 Flujo de Creación de Ticket (Vista Pública)

```
[Usuario se acerca a pantalla]
            │
            ▼
┌──────────────────────────────┐
│  Pantalla Ticket Selection   │
│  - Muestra áreas disponibles │
│  - Video de fondo animado    │
│  - Reloj / fecha             │
└──────────────────────────────┘
            │
            │ (Usuario toca un área)
            ▼
┌──────────────────────────────┐
│  Validar: área activa?       │
└──────┬───────────────────────┘
       │ Sí
       ▼
┌──────────────────────────────┐
│  POST /api/tickets           │
│  { areaId: 1 }               │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Servidor:                   │
│  1. Genera código secuencial │
│  2. Crea Ticket (pendiente)  │
│  3. Broadcast WebSocket:     │
│     "TicketCreated"          │
│  4. Retorna ticket creado    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Pantalla muestra:           │
│  "Ticket CAJA-042 creado"   │
│  "Tiempo estimado: 5 min"   │
│  "Espera en sala"            │
└──────────────────────────────┘
            │
            │ (Timeout 10 seg)
            ▼
┌──────────────────────────────┐
│  Vuelve a pantalla inicial   │
│  (ready para nuevo ticket)   │
└──────────────────────────────┘
```

### 2.2 Flujo de Atención (Vista Agente)

```
[Agente inicia sesión]
         │
         ▼
┌──────────────────────────────┐
│  Login: POST /api/auth/login │
│  - Valida credenciales       │
│  - Retorna JWT + usuario     │
│  - Redirige a AttentionScreen│
└──────────────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  AttentionScreen             │
│  - Conecta WebSocket         │
│  - JoinAreaGroup(areaId)     │
│  - GET /tickets/pending       │
│  - GET /tickets/current(user)│
└──────────────────────────────┘
         │
         │ (Agente presiona "Llamar Siguiente")
         ▼
┌──────────────────────────────┐
│  POST /api/tickets/{id}/call │
│  Servidor:                   │
│  1. Cambia status→"llamado"  │
│  2. Asigna ticket al agente  │
│  3. Broadcast: "TicketCalled"│
│  4. Pantalla pública muestra │
│     "Pase a Ventanilla 1"    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Ticket en pantalla agente:  │
│  "CAJA-042 - Esperando..."   │
│  Botón: "INICIAR ATENCIÓN"   │
└──────┬───────────────────────┘
       │ (Agente presiona "Iniciar")
       ▼
┌──────────────────────────────┐
│  POST /tickets/{id}/start   │
│  Servidor:                   │
│  1. status→"en_atencion"    │
│  2. Registra AttentionLog   │
│     {ticketId, userId,      │
│      llamadoAt, iniciadoAt} │
│  3. Broadcast: "TicketStart"│
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Timer de atención activo   │
│  Muestra: 00:00 → 00:45...  │
└──────┬───────────────────────┘
       │ (Agente presiona "Finalizar")
       ▼
┌──────────────────────────────┐
│  POST /tickets/{id}/complete │
│  Servidor:                   │
│  1. status→"completado"     │
│  2. Actualiza AttentionLog  │
│     {completadoAt,          │
│      tiempSegundos}          │
│  3. Broadcast: "TicketComp"  │
│  4. Retorna tiempo atención  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Muestra resumen breve:      │
│  "CAJA-042 - 4:45 min"       │
│  → Vuelve a pantalla lista   │
│  para llamar siguiente       │
└──────────────────────────────┘
```

### 2.3 Flujo de Dashboard

```
[Admin accede a Dashboard]
         │
         ▼
┌──────────────────────────────┐
│  DashboardScreen             │
│  - Filtro: Hoy/Semana/Mes   │
│  - GET /dashboard/summary   │
│  - GET /dashboard/by-area   │
│  - GET /dashboard/by-user   │
│  - GET /dashboard/hourly    │
└──────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│  Cálculos del servidor (Stored Procedures):      │
│                                                   │
│  Total Tickets = COUNT(id) WHERE fecha BETWEEN   │
│  Tickets Atendidos = COUNT(id) WHERE status='com'│
│  Tiempo Promedio = AVG(tiempo_segundos)           │
│  Tickets por Hora = GROUP BY DATEPART(hour, ...)  │
│  Por Agente = GROUP BY user_id                    │
│  Por Área = GROUP BY area_id                      │
└──────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Renderiza:                  │
│  - 3 tarjetas resumen        │
│  - Gráfico de barras (horas) │
│  - Tabla agentes             │
│  - Tabla áreas               │
└──────────────────────────────┘
```

---

## 3. ESTRUCTURA DE LA BASE DE DATOS

### Diagrama Entidad-Relación

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   Areas     │     │    Users        │     │  Tickets     │
├─────────────┤     ├─────────────────┤     ├──────────────┤
│ PK id       │◄────┤ FK area_id      │     │ PK id        │
│   nombre    │     │   id            │     │   codigo     │
│   prefijo   │     │   nombre_user   │     │ FK area_id   │
│   activo    │     │   nombre_compl  │     │   tipo       │
│   created_at│     │   password_hash │     │   status     │
└─────────────┘     │   rol           │     │   created_at │
                    │   activo        │     └──────┬───────┘
                    │   ultimo_acceso │            │
                    └─────────────────┘            │
                                                   │
                         ┌─────────────────────────┘
                         │
                    ┌────▼──────────────┐    ┌─────────────────┐
                    │  AttentionLogs    │    │  Configurations │
                    ├──────────────────┤    ├─────────────────┤
                    │ PK id            │    │ PK id           │
                    │ FK ticket_id     │    │   clave (uniq)  │
                    │ FK user_id       │    │   valor         │
                    │   llamado_at     │    │   tipo          │
                    │   iniciado_at    │    │   updated_at    │
                    │   completado_at  │    └─────────────────┘
                    │   tiemp_segundos │
                    │   observacion    │
                    └──────────────────┘
```

### 3.1 Tabla: Areas
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT (PK, IDENTITY) | Identificador único |
| nombre | NVARCHAR(100) | Nombre del área (Caja, Info, etc.) |
| prefijo | NVARCHAR(10) | Prefijo para código de ticket (CAJA, INFO) |
| activo | BIT | Si el área está habilitada |
| created_at | DATETIME2 | Fecha de creación |
| updated_at | DATETIME2 | Fecha de última modificación |

### 3.2 Tabla: Users
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT (PK, IDENTITY) | Identificador único |
| nombre_usuario | NVARCHAR(50) (UNIQUE) | Usuario para login |
| nombre_completo | NVARCHAR(150) | Nombre visible del usuario |
| password_hash | NVARCHAR(255) | Hash BCrypt de la contraseña |
| rol | NVARCHAR(20) | 'administrador' o 'usuario_atencion' |
| area_id | INT (FK → Areas.id) | Área a la que pertenece |
| activo | BIT | Si el usuario está habilitado |
| ultimo_acceso | DATETIME2 | Último inicio de sesión |
| created_at | DATETIME2 | Fecha de creación |

### 3.3 Tabla: Tickets
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT (PK, IDENTITY) | Identificador único |
| codigo_ticket | NVARCHAR(20) (UNIQUE) | Código legible (CAJA-042) |
| tipo_ticket | NVARCHAR(20) | 'caja', 'informacion', 'inscripcion', 'documentacion' |
| area_id | INT (FK → Areas.id) | Área solicitada |
| status | NVARCHAR(20) | 'pendiente', 'llamado', 'en_atencion', 'completado', 'cancelado' |
| llamado_por_user_id | INT (FK → Users.id, NULL) | Quién llamó el ticket |
| created_at | DATETIME2 | Fecha de creación |
| updated_at | DATETIME2 | Última actualización |

### 3.4 Tabla: AttentionLogs
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT (PK, IDENTITY) | Identificador único |
| ticket_id | INT (FK → Tickets.id) | Ticket atendido |
| user_id | INT (FK → Users.id) | Usuario que atendió |
| llamado_at | DATETIME2 | Cuándo se llamó al ticket |
| iniciado_at | DATETIME2 | Cuándo inició la atención |
| completado_at | DATETIME2 (NULL) | Cuándo finalizó |
| tiempo_segundos | INT (NULL) | Duración total en segundos |
| observacion | NVARCHAR(500) (NULL) | Nota opcional |

### 3.5 Tabla: Configurations
| Columna | Tipo | Descripción |
|---|---|---|
| id | INT (PK, IDENTITY) | Identificador único |
| clave | NVARCHAR(100) (UNIQUE) | Clave de configuración |
| valor | NVARCHAR(MAX) | Valor JSON o texto |
| tipo | NVARCHAR(50) | 'int', 'string', 'boolean', 'json' |
| updated_at | DATETIME2 | Última actualización |

---

## 4. GENERACIÓN DE CÓDIGO DE TICKET

```
Formato: {PrefijoArea}-{NúmeroSecuencial:0000}

Ejemplos:
  CAJA-0001, CAJA-0002, ..., CAJA-9999
  INFO-0001, INSC-0001, DOC-0001

Reglas:
  - El número secuencial es POR ÁREA y POR DÍA
  - Se resetea diariamente a 0001
  - Límite: 9999 tickets/día por área
```

### Lógica SQL para generar código:
```sql
DECLARE @prefijo NVARCHAR(10) = 'CAJA';
DECLARE @fecha DATE = CAST(GETDATE() AS DATE);
DECLARE @secuencia INT;

SELECT @secuencia = ISNULL(MAX(CAST(SUBSTRING(codigo_ticket, LEN(@prefijo) + 2, 4) AS INT)), 0) + 1
FROM Tickets
WHERE codigo_ticket LIKE @prefijo + '-%'
  AND CAST(created_at AS DATE) = @fecha;

SET @codigo = @prefijo + '-' + RIGHT('0000' + CAST(@secuencia AS NVARCHAR(4)), 4);
```

---

## 5. CONTROL DE TIEMPOS

### 5.1 Variables de tiempo medidas

| Variable | Cálculo | Fórmula |
|---|---|---|
| Tiempo de espera | Desde creación hasta llamado | `llamado_at - created_at` |
| Tiempo de atención | Desde inicio hasta fin | `completado_at - iniciado_at` |
| Tiempo total ciclo | Desde creación hasta fin | `completado_at - created_at` |
| Tiempo promedio diario | Media de tiempos del día | `AVG(tiempo_segundos)` |

### 5.2 Estados del ticket y línea de tiempo

```
CREADO ──► LLAMADO ──► EN_ATENCION ──► COMPLETADO
  │          │              │               │
  │          │              │               │
  ▼          ▼              ▼               ▼
t₀          t₁             t₂              t₃

  Espera = t₁ - t₀
  Atención = t₃ - t₂
  Ciclo total = t₃ - t₀
```

---

## 6. REGLAS DE NEGOCIO (VALIDACIONES)

| Regla | Descripción | Dónde se aplica |
|---|---|---|
| R1 | Un ticket solo puede ser llamado una vez | API - Backend |
| R2 | Un agente solo atiende un ticket a la vez | API + Provider |
| R3 | Solo admin puede crear/modificar usuarios | API - JWT Role |
| R4 | Solo admin puede gestionar áreas | API - JWT Role |
| R5 | Los tickets se crean sin autenticación | API endpoint público |
| R6 | El código de ticket es único por día/área | DB - Unique Index |
| R7 | Un ticket no puede cambiar de área después de creado | API - Validación |
| R8 | El video de fondo debe ser mp4 ≤ 100MB | API - Validación archivo |
| R9 | Dashboard stats se cachean 30 segundos | API - Memory Cache |
| R10 | El login bloquea tras 5 intentos fallidos (15 min) | API - Rate Limit |

---

## 7. MAPA DE NAVEGACIÓN DE PANTALLAS

```
                          (Sin autenticación)
┌──────────────────────┐
│  Ticket Selection    │◄──── Pantalla pública kiosko
│  /ticket             │
└──────────────────────┘

┌──────────────────────┐
│  Kiosko Selection    │◄──── caller login (si no hay kiosko activo)
│  /kiosko-selection   │       luego → /ticket
└──────────────────────┘

              (Autenticación)
┌──────────────┐     
│  Login       │────► Según rol:
│  /login      │        admin     → /dashboard
└──────────────┘        caller    → /kiosko-selection → /ticket
       │                atencion  → /puesto-selection → /attention
       │
       ├─────────────────────────────────────────────────┐
       │ (admin)                                          │
       ▼                                                  ▼
┌──────────────────┐                           ┌──────────────────────┐
│  Puesto Selection│                           │  Settings            │
│  /puesto-selec   │─► /attention              │  /settings           │
└──────────────────┘                           │  ├ Usuarios          │
                                               │  ├ Áreas + Puestos  │
┌──────────────────┐                           │  ├ Kioskos          │
│  Attention       │                           │  ├ Video Fondo      │
│  /attention      │                           │  ├ Impresora        │
└──────────────────┘                           │  └ Sistema          │
                                               └──────────────────────┘
┌──────────────────┐
│  Dashboard       │
│  /dashboard      │
└──────────────────┘

┌──────────────────┐     ┌──────────────────────────────┐
│  Caller Display  │◄──── Ventana secundaria (sub-window)
│  /caller         │     Creada por desktop_multi_window
└──────────────────┘     Comunicación vía WindowMethodChannel
```

---

## 8. ALMACENAMIENTO Y CACHE

| Tipo | Tecnología | Uso |
|---|---|---|
| Sesión JWT | Token en memoria + secure storage | Auth |
| Cache de dashboard | MemoryCache (30s) | Evitar recálculos |
| Video fondo | Archivos en disco (servidor) | Streaming |
| Config local | SharedPreferences | Preferencias UI |
| Token persistente | flutter_secure_storage | Refresh token |

---

## 9. LOGS Y MONITOREO

### Estructura de logging
```
Timestamp | Nivel | Componente | Mensaje | Contexto
─────────────────────────────────────────────────────
2026-06-16 14:30:00 | INFO | TicketService | Ticket CAJA-042 creado | areaId=1
2026-06-16 14:32:00 | INFO | TicketService | Ticket CAJA-042 llamado | userId=1
2026-06-16 14:32:30 | INFO | TicketService | Ticket CAJA-042 atención iniciada | userId=1
2026-06-16 14:37:15 | INFO | TicketService | Ticket CAJA-042 completado | tiempo=285s
2026-06-16 14:37:15 | WARN | AuthService | Intento fallido login | user=admin IP=192.168.1.50
```

### Endpoints de health check
- `GET /health` - Estado del servidor
- `GET /health/database` - Estado de conexión a BD
- `GET /health/websocket` - Estado de SignalR

---

## 9.5 MODO DESARROLLO (MOCK DATA)

Actualmente el frontend funciona en **modo desarrollo** sin backend. Los providers incluyen datos mock internos:

| Provider | Mock activo? | Credenciales / datos mock |
|---|---|---|
| `AuthProvider` | ✅ | `admin / Admin123!` (rol admin), `ana / 123` (rol atención - área Caja), `carlos / 123` (rol caller) |
| `TicketProvider` | ✅ | Genera tickets con prefijo `TEST-XXXX`, cola FIFO + prioridad |
| `DashboardProvider` | ✅ | Datos estáticos (142 tickets, 4 áreas, 3 agentes) |
| `AreaProvider` | ✅ | 4 áreas predefinidas (Caja, Info, Insc, Doc) con logos preset |
| `SettingsProvider` | ✅ | Config por defecto editable, persistida en SharedPreferences |
| `UserManagementProvider` | ✅ | CRUD sobre DataStore (usuarios mock + nuevos) |

### Persistencia mock (SharedPreferences)

| Clave | Tipo | Valor por defecto |
|---|---|---|
| `server_url` | String | `http://localhost:5000` |
| `tiempo_estimado` | int | `5` (minutos) |
| `max_tickets` | int | `500` |
| `video_ticket` | String? | `null` |
| `video_caller` | String? | `null` |
| `kiosko_locations` | String (JSON) | `[]` |
| `selected_kiosko_id` | String? | `null` |
| `puestos_por_area` | String (JSON) | `{}` |

Los modelos (`data/models/`) y casos de uso (`domain/usecases/`) están preparados para interactuar con el backend real cuando esté disponible. Cada provider verifica si tiene un repositorio inyectado; si no, usa datos mock.

---

## 10. REQUISITOS PARA BUILD WINDOWS

Para compilar la aplicación Flutter para Windows se requiere:

1. **Visual Studio 2022** (no VS Code) con la carga de trabajo:
   - "Desarrollo para escritorio con C++"
2. **Windows SDK** (incluido con Visual Studio)
3. Ejecutar: `flutter build windows`

El análisis Dart (`flutter analyze`) pasa con 0 errores.

> **Nota:** El proyecto usa `desktop_multi_window` para la ventana secundaria del caller display y `window_manager` para control de posición/tamaño de ventana principal. Ambas dependen de APIs nativas de Windows.

---

## 11. PRÓXIMAS FASES Y ESCALABILIDAD

| Fase | Descripción | Prioridad | Estado |
|---|---|---|---|
| 1 | Core: Tickets + Atención CRUD | Inmediata | 🟢 |
| 2 | WebSocket + Tiempo real | Inmediata | 🟡 (backend listo, frontend pendiente) |
| 3 | Dashboard + Estadísticas | Alta | 🟢 |
| 4 | Configuración + Video fondo | Alta | 🟢 |
| 5 | Puestos físicos por área + ocupación | Media | 🟢 |
| 6 | Kiosko locations + selección | Media | 🟢 |
| 7 | Multi-ventana (caller display independiente) | Media | 🟢 |
| 8 | Pantalla TV (monitor sala) | Media | 🟢 |
| 9 | Reportes exportables (PDF/Excel) | Baja | ⬜ |
| 10 | Notificaciones sonoras | Baja | ⬜ |
| 11 | App móvil para clientes (consulta en fila) | Futuro | ⬜ |
| 12 | Kiosko con impresora de tickets | Futuro | 🟢 (impresión lista) |

**Leyenda:** 🟢 Completado | 🟡 En progreso | ⬜ Pendiente
