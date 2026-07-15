# DOCUMENTACIÓN DE ENDPOINTS API

## 1. CONFIGURACIÓN BASE

```
Base URL: http://{host}:5000/api
WebSocket: http://{host}:5000/ticketHub
Content-Type: application/json
Auth: Bearer {token} (excepto login y ticket público)
```

---

## 2. AUTENTICACIÓN (AuthController)

### `POST /api/auth/login`
Inicia sesión con **correo electrónico** y devuelve token JWT + datos del usuario.

```json
// Request
{
  "correo": "admin@empresa.com",
  "password": "Admin123!"
}

// Response 200
{
  "token": "eyJhbGciOiJI...",
  "refreshToken": "rt_abc123...",
  "usuario": {
    "id": 1,
    "nombreUsuario": "admin",
    "nombreCompleto": "Administrador Sistema",
    "email": "admin@empresa.com",
    "rol": "administrador",
    "areaId": null,
    "areaNombre": null,
    "puesto": null,
    "areaAtencion": [],
    "activo": true,
    "ultimoAcceso": "2026-07-06T07:27:26.559615"
  },
  "expiraEn": "2026-07-06T15:27:26Z"
}

// Response 401
{
  "mensaje": "Credenciales inválidas"
}
```

### `POST /api/auth/refresh`
Renueva el token JWT.

```json
// Request
{
  "refreshToken": "rt_abc123..."
}

// Response 200
{
  "token": "eyJhbGciOiJI...",
  "refreshToken": "rt_def456...",
  "expiraEn": "2026-06-17T06:00:00Z"
}
```

---

## 3. TICKETS (TicketsController)

### `POST /api/tickets`
Crear un nuevo ticket (requiere auth).

```json
// Request
{
  "areaId": 1
}

// Response 201
{
  "id": 2,
  "codigoTicket": "CAJ-000002",
  "tipoTicket": "Incidente",
  "areaId": 1,
  "areaNombre": "Caja",
  "status": "pendiente",
  "llamadoPorUserId": null,
  "llamadoPorUserName": null,
  "creadoEn": "2026-07-06T07:27:10.1561032Z",
  "updatedAt": null,
  "tiempoEsperaSegundos": null,
  "tiempoAtencionSegundos": null,
  "tiempoAtencionFormateado": null,
  "prioridad": 3,
  "derivadoDe": null,
  "derivadoDeNombre": null
}
```

### `GET /api/tickets/pending`
Obtener tickets pendientes.

```json
// Response 200
{
  "tickets": [
    {
      "id": 3, "codigoTicket": "CAJ-000003",
      "status": "pendiente", "creadoEn": "...",
      "tiempoEsperaSegundos": null, "prioridad": 3,
      "areaId": 1, "areaNombre": "Caja",
      "tipoTicket": "Incidente", ...
    }
  ]
}
```

### `POST /api/tickets/{id}/call`
Llamar al siguiente ticket.

```json
// Request { "userId": 1 }
// Response 200 → TicketResponse completo con status "llamado"
{
  "id": 2, "codigoTicket": "CAJ-000002",
  "status": "llamado",
  "llamadoPorUserId": 1,
  "llamadoPorUserName": "Administrador Sistema",
  ...
}
```

### `POST /api/tickets/{id}/start-attention`
Iniciar atención de un ticket.

```json
// Request { "userId": 1 }
// Response 200 → status "en_atencion", tiempoEsperaSegundos calculado
{
  "id": 2, "codigoTicket": "CAJ-000002",
  "status": "en_atencion",
  "tiempoEsperaSegundos": 0,
  ...
}
```

### `POST /api/tickets/{id}/complete`
Completar atención de un ticket.

```json
// Request { "userId": 1, "observacion": "Todo OK" }
// Response 200 → status "completado", tiempos calculados
{
  "id": 2, "codigoTicket": "CAJ-000002",
  "status": "completado",
  "updatedAt": "2026-07-06T07:27:10.5596151Z",
  "tiempoAtencionSegundos": 0,
  "tiempoAtencionFormateado": "00:00",
  ...
}
```

### `POST /api/tickets/{id}/cancel`
Cancelar un ticket.

```json
// Request { "motivo": "Cliente se retiró" }
// Response 200 → status "cancelado"
```

### `GET /api/tickets/current/{userId}`
Obtener el ticket actual en atención de un usuario.

```json
// Response 200 → TicketResponse si hay ticket activo, "" si no
```

### `GET /api/tickets/history?areaId={areaId}&pagina=1&tamanoPagina=10`
Historial paginado de tickets de un área.

```json
// Response 200
{
  "tickets": [...],
  "total": 0,
  "fecha": "2026-07-06"
}
```

---

## 4. USUARIOS (UsersController)
*Requiere rol: administrador*

### `GET /api/users`
Listar todos los usuarios.

```json
// Response 200 → Array de UserResponse
[
  {
    "id": 1, "nombreUsuario": "admin", "nombreCompleto": "Administrador Sistema",
    "email": "admin@empresa.com", "rol": "administrador",
    "areaId": null, "areaNombre": null, "puesto": null,
    "areasAtencion": [], "activo": true,
    "ultimoAcceso": "2026-07-06T07:27:26.559615"
  }
]
```

### `POST /api/users`
Crear un nuevo usuario.

```json
// Request
{
  "nombreUsuario": "luis.rojas",
  "nombreCompleto": "Luis Rojas",
  "correo": "luis.rojas@ejemplo.com",
  "password": "Admin123!",
  "rol": "usuario_atencion",
  "areaId": 2
}

// Response 201 → UserResponse
```

### `PUT /api/users/{id}`
Actualizar un usuario.

```json
// Request
{
  "nombreCompleto": "Luis Rojas M.",
  "correo": "luis.rojas@ejemplo.com",
  "password": "NuevoPass123!",
  "rol": "supervisor",
  "areaId": 3
}

// Response 200 → UserResponse
```

### `DELETE /api/users/{id}`
Eliminar (desactivar) un usuario.

```json
// Response 200
{
  "mensaje": "Usuario desactivado correctamente"
}
```

---

## 5. ÁREAS (AreasController)

### `GET /api/areas`
Listar todas las áreas activas.

```json
// Response 200
[
  {"id": 1, "nombre": "Caja", "prefijo": "CAJ", "logoUrl": "", "activo": true},
  {"id": 2, "nombre": "Informes", "prefijo": "INF", "logoUrl": "", "activo": true},
  {"id": 3, "nombre": "Atención al Cliente", "prefijo": "ATE", "logoUrl": "", "activo": true}
]
```

### `POST /api/areas`
Crear una nueva área.

```json
// Request
{
  "nombre": "Pagos",
  "prefijo": "PAG"
}

// Response 201 → AreaResponse
```

### `PUT /api/areas/{id}`
Actualizar un área.

```json
// Request
{
  "nombre": "Pagos Varios",
  "prefijo": "PAGV"
}

// Response 200 → AreaResponse
```

---

## 6. DASHBOARD (DashboardController)
*Requiere rol: administrador*

### `GET /api/dashboard/summary?fechaInicio={yyyy-MM-dd}&fechaFin={yyyy-MM-dd}`
Resumen de métricas del dashboard.

```json
// Response 200
{
  "totalTickets": 2,
  "totalAtendidos": 1,
  "totalPendientes": 1,
  "tiempoPromedioAtencion": 0,
  "tiempoPromedioAtencionFormateado": "00:00",
  "tiempoPromedioEspera": 0,
  "tiempoPromedioEsperaFormateado": "00:00",
  "periodo": {
    "inicio": "2026-07-06T00:00:00Z",
    "fin": "2026-07-06T23:59:59Z"
  }
}
```

### `GET /api/dashboard/by-area?fechaInicio={yyyy-MM-dd}&fechaFin={yyyy-MM-dd}`
Desglose de tickets por área.

```json
// Response 200
{
  "areas": [
    {"area": "Caja", "total": 2, "atendidos": 1, "pendientes": 1, "tiempoPromedio": 0}
  ]
}
```

### `GET /api/dashboard/by-user?fechaInicio={yyyy-MM-dd}&fechaFin={yyyy-MM-dd}`
Rendimiento por usuario/agente.

```json
// Response 200
{
  "usuarios": [
    {"nombre": "Administrador Sistema", "totalAtendidos": 1, "tiempoPromedio": 0, "area": "Caja"}
  ]
}
```

### `GET /api/dashboard/hourly-breakdown?fecha={yyyy-MM-dd}`
Desglose horario de atenciones.

```json
// Response 200
{
  "horas": [
    {"hora": 7, "total": 1}
  ]
}
```

---

## 7. CONFIGURACIÓN (ConfigurationController)
*Requiere rol: administrador*

### `GET /api/configuration`
Obtener configuración del sistema.

```json
// Response 200
{
  "tiempoEstimadoMinutos": 5,
  "prefijoFormato": "{0}-{1:D4}",
  "videoActual": "fondo_personalizado.mp4",
  "maxTicketsPorDia": 500
}
```

### `PUT /api/configuration`
Actualizar configuración del sistema.

```json
// Request
{
  "tiempoEstimadoMinutos": 10,
  "maxTicketsPorDia": 1000
}

// Response 200
{
  "mensaje": "Configuración actualizada"
}
```

### `POST /api/configuration/video`
Subir video de fondo (multipart/form-data).

```
POST /api/configuration/video
Content-Type: multipart/form-data

file: [archivo.mp4]
```

```json
// Response 200
{
  "mensaje": "Video actualizado correctamente",
  "nombreArchivo": "fondo_20260616.mp4",
  "url": "/api/configuration/video/stream"
}
```

### `GET /api/configuration/video/stream`
Streaming del video de fondo actual.

```
Response 200: video/mp4 (streaming)
```

---

## 8. WEBSOCKET (SignalR - TicketHub)

### Conexión
```
ws://{host}:5000/ticketHub
```
**Nota:** SignalR corre en el MISMO puerto que la API REST (5000), no en puerto separado.

### Eventos que emite el Servidor

| Evento | Descripción | Payload |
|---|---|---|
| `TicketCreated` | Nuevo ticket creado | `{ id, codigoTicket, areaId, status }` |
| `TicketCalled` | Ticket llamado a ventanilla | `{ id, codigoTicket, llamadoPorUserId }` |
| `TicketStarted` | Atención iniciada | `{ id, codigoTicket, userId }` |
| `TicketCompleted` | Ticket completado | `{ id, codigoTicket, tiempoAtencion }` |
| `TicketCancelled` | Ticket cancelado | `{ id, codigoTicket }` |
| `QueueUpdated` | Cola de espera actualizada | `{ areaId, pendientes }` |

### Métodos que recibe el Cliente

| Método | Descripción | Parámetros |
|---|---|---|
| `JoinAreaGroup` | Unirse a grupo de área específica | `areaId: number` |
| `LeaveAreaGroup` | Salir del grupo de área | `areaId: number` |
| `RequestQueueStatus` | Solicitar estado actual de colas | (ninguno) |

### Ejemplo de uso (Flutter)
```dart
// Conectar al hub
await websocketService.connect();

// Escuchar nuevos tickets
websocketService.on('TicketCreated', (data) {
  // Actualizar UI con nuevo ticket
  ticketProvider.addTicket(data);
});

// Unirse a grupo de Caja (áreaId=1)
await websocketService.invoke('JoinAreaGroup', args: [1]);
```

---

## 9. CÓDIGOS DE RESPUESTA

| Código | Significado | Uso |
|---|---|---|
| 200 | OK | Éxito en GET/PUT |
| 201 | Created | Éxito en POST |
| 204 | No Content | Sin datos (sin ticket activo) |
| 400 | Bad Request | Error de validación |
| 401 | Unauthorized | Token inválido/expirado |
| 403 | Forbidden | Sin permisos suficientes |
| 404 | Not Found | Recurso no existe |
| 409 | Conflict | Conflicto (ej: ticket ya en atención) |
| 429 | Too Many Requests | Rate limit excedido |
| 500 | Server Error | Error interno |
