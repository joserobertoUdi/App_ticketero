# CONFIGURACIÓN DE RED Y SERVIDORES

## 1. TOPOLOGÍA DE RED

```
                    ┌─────────────────────┐
                    │    RED LOCAL        │
                    │  192.168.1.0/24     │
                    └─────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Servidor API   │  │  SQL Server     │  │  Estaciones     │
│  .NET Core      │  │  Express        │  │  Cliente Flutter│
│  192.168.1.X    │  │  .\SQLEXPRESS   │  │  192.168.1.50-80│
│  Puerto: 5000   │  │  Puerto: 1433   │  └─────────────────┘
│  WS: mismo 5000 │  └─────────────────┘
└─────────────────┘
```

---

## 2. REQUISITOS DE SERVIDOR

### 2.1 Servidor API (.NET Core)
| Especificación | Mínimo | Recomendado |
|---|---|---|
| CPU | 2 núcleos | 4 núcleos |
| RAM | 2 GB | 4 GB |
| Disco | 20 GB SSD | 40 GB SSD |
| SO | Windows Server 2019+ | Windows Server 2022 |
| Runtime | .NET 8 Runtime | .NET 8 SDK |

### 2.2 Servidor Base de Datos (SQL Server)
| Especificación | Mínimo | Recomendado |
|---|---|---|
| CPU | 2 núcleos | 4 núcleos |
| RAM | 4 GB | 8 GB |
| Disco | 50 GB SSD | 100 GB SSD |
| SO | Windows Server 2019+ | Windows Server 2022 |
| SQL Server | 2019 Express | 2022 Standard |

---

## 3. PUERTOS Y PROTOCOLOS

| Puerto | Protocolo | Servicio | Descripción |
|---|---|---|---|
| 5000 | HTTP | API REST + WebSocket SignalR | Endpoints CRUD y tiempo real (mismo puerto) |
| 1433 | TCP | SQL Server | Base de datos |
| 443 | HTTPS | API (prod) | Cifrado en producción |

### Reglas de Firewall (Windows Defender)
```powershell
# Puerto API REST + WebSocket (mismo puerto)
New-NetFirewallRule -DisplayName "Ticketero API - 5000" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow

# Puerto SQL Server
New-NetFirewallRule -DisplayName "SQL Server - 1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

---

## 4. CADENA DE CONEXIÓN SQL SERVER

### Desarrollo (appsettings.Development.json)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=DBTicketero_Dev;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
  }
}
```

### Producción (appsettings.Production.json)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=DBTicketero;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
  }
}
```

---

## 5. CONFIGURACIÓN DEL CLIENTE FLUTTER

### lib/core/constants/api_constants.dart
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:5000';
  static const String websocketUrl = 'http://localhost:5000/ticketHub'; // Mismo puerto
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
}
```

---

## 6. CONFIGURACIÓN DE LA API (.NET)

### appsettings.json (configuración actual del backend)
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=DBTicketero;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
  },
  "Jwt": {
    "SecretKey": "YourSuperSecretKeyAtLeast32CharactersLong!",
    "Issuer": "TicketeroAPI",
    "Audience": "TicketeroClient",
    "ExpirationInMinutes": 480,
    "RefreshTokenExpirationInDays": 7
  },
  "CorsSettings": {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    "AllowedHeaders": ["*"]
  }
}
```

---

## 7. VARIABLES DE ENTORNO (PRODUCCIÓN)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `DB_CONNECTION` | Cadena de conexión SQL Server | `Server=...;` |
| `JWT_SECRET` | Clave secreta JWT | `min-32-caracteres` |
| `API_PORT` | Puerto HTTP | `5000` |
| `WS_PORT` | Puerto WebSocket | `5001` |
| `LOG_LEVEL` | Nivel de logging | `Information` |
| `STORAGE_PATH` | Ruta para archivos (videos) | `C:\Ticketero\Storage` |

---

## 8. ALMACENAMIENTO DE ARCHIVOS (VIDEOS)

Los videos de fondo se almacenan en el servidor API:
```
C:\Ticketero\Storage\Videos\
  ├── fondo_default.mp4
  └── fondo_personalizado.mp4
```

Endpoint para subida/descarga:
- `POST /api/configuration/video` - Subir nuevo video
- `GET /api/configuration/video/current` - Obtener video actual
- `GET /api/configuration/video/stream` - Streaming del video

---

## 9. REQUISITOS DE RED PARA ESTACIONES

- **Latencia máxima:** < 50ms entre estación y servidor API
- **Ancho de banda:** > 10 Mbps (para video streaming)
- **Protocolo:** TCP/IP con IPv4
- **DNS:** No requerido (IP fija recomendada)
- **Proxy:** No soportado inicialmente

---

## 9. REQUISITOS PARA COMPILAR EN WINDOWS

Para `flutter build windows` se requiere:
- **Visual Studio 2022** con la carga de trabajo "Desarrollo para escritorio con C++"
- SDK de Windows 10/11 (viene incluido con VS2022)
- Comando: `flutter build windows` (o `--debug` para pruebas)

---

## 10. SEGURIDAD

### Autenticación
- JWT Bearer Token con expiración de 8 horas
- Refresh token rotativo
- HTTPS obligatorio en producción

### Base de Datos
- Usuario SQL con permisos mínimos (db_datareader, db_datawriter)
- Conexión cifrada (TrustServerCertificate=True solo en desarrollo)
- Passwords hasheadas con BCrypt

### API
- Rate limiting: 100 requests/min por IP
- CORS configurado con orígenes específicos en producción
- Validación de entrada en todos los endpoints
