# PLAN DE IMPLEMENTACIÓN - SISTEMA TICKETERO

**Objetivo:** Implementación progresiva por capas, empezando por la base de datos y backend, luego frontend, integrando tiempo real y dashboard al final.

**Leyenda:** 🟢 Completado | 🟡 En progreso | ⬜ Pendiente | 🔴 Bloqueado

---

## FASE 0: INFRAESTRUCTURA Y ARQUITECTURA (BASE)

| # | Tarea | Estado | Documentación | Dependencias |
|---|---|---|---|---|
| 0.1 | Crear estructura Clean Architecture (frontend + backend) | 🟢 | ARQUITECTURA.md | - |
| 0.2 | Crear script SQL completo (tablas, índices, SPs) | 🟢 | REFERENCIA_TECNICA.md §3 | - |
| 0.3 | Configurar proyecto .NET Core (WebAPI + Capas) | 🟢 | CONFIGURACION_RED.md | 0.1 |
| 0.4 | Configurar Flutter con dependencias (pubspec.yaml) | 🟢 | REFERENCIA_TECNICA.md §1.2 | 0.1 |
| 0.5 | Configurar cadena de conexión y entorno dev | 🟢 | CONFIGURACION_RED.md §4 | 0.3 |

---

## FASE 1: DOMINIO Y BASE DE DATOS (CORE)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 1.1 | Definir entidades de dominio (Ticket, User, Area, AttentionLog) | 🟢 | `domain/entities/*.dart` |
| 1.2 | Definir enumeraciones (TicketType, TicketStatus, UserRole) | 🟢 | `core/enums/*.dart` |
| 1.3 | Definir interfaces de repositorio (contratos) | 🟢 | `domain/repositories/*.dart` |
| 1.4 | Ejecutar script SQL 001-003 (BD + tablas + índices) | ⬜ | `database/scripts/` |
| 1.5 | Ejecutar script SQL 004 (seed data: roles, áreas) | ⬜ | `database/scripts/004_seed_data.sql` |
| 1.6 | Ejecutar script SQL 005 (stored procedures dashboard) | ⬜ | `database/scripts/005_stored_procedures.sql` |
| **1.7** | **Crear entidad PuestoInfo (puesto físico por área)** | 🟢 | `domain/entities/puesto_info.dart` |
| **1.8** | **Crear entidad KioskoLocation (ubicación kiosko)** | 🟢 | `domain/entities/kiosko_location.dart` |

---

## FASE 2: BACKEND - INFRAESTRUCTURA Y API

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 2.1 | Implementar DbContext + Entity Configurations (EF Core) | 🟢 | `Infrastructure/Data/AppDbContext.cs` |
| 2.2 | Implementar repositorios concretos + UnitOfWork | 🟢 | `Infrastructure/Repositories/*.cs` |
| 2.3 | Implementar DTOs y perfiles de mapeo | 🟢 | `Application/DTOs/*.cs` |
| 2.4 | Implementar servicios de aplicación | 🟢 | `Application/Services/*.cs` |
| 2.5 | Implementar controladores API REST | 🟢 | `Api/Controllers/*.cs` |
| 2.6 | Implementar middleware | 🟢 | `Api/Middleware/*.cs` |
| 2.7 | Implementar TicketNotificationService (SignalR) | 🟢 | `Api/Services/TicketNotificationService.cs` |
| 2.8 | Configurar Kestrel, CORS, JWT en Program.cs | 🟢 | `Api/Program.cs`, `Api/appsettings.json` |
| 2.9 | Backend compila (`dotnet build`: 0 errores) | 🟢 | `backend/src/Ticketero.Api/` |
| 2.10 | Probar endpoints con Swagger/Postman | 🟢 | API_ENDPOINTS.md | - |

---

## FASE 3: BACKEND - WEBSOCKET / TIEMPO REAL

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 3.1 | Implementar TicketHub (SignalR) con grupos por área | 🟢 | `Api/Hubs/TicketHub.cs` |
| 3.2 | Implementar ITicketNotificationService | 🟢 | `Application/Interfaces/`, `Api/Services/` |
| 3.3 | Integrar notificaciones en TicketService | 🟢 | `Application/Services/TicketService.cs` |
| 3.4 | Probar conexión WebSocket con cliente de prueba | ⬜ | - |

---

## FASE 4: FRONTEND - CORE (CAPA COMPARTIDA)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 4.1 | Implementar ApiClient (Dio con interceptors JWT) | 🟢 | `core/network/api_client.dart` |
| 4.2 | Implementar WebSocketService (SignalR) | 🟢 | `core/network/websocket_service.dart` |
| 4.3 | Implementar NetworkInfo | 🟢 | `core/network/network_info.dart` |
| 4.4 | Definir constantes | 🟢 | `core/constants/*.dart` |
| 4.5 | Implementar tema visual | 🟢 | `core/theme/*.dart` |
| 4.6 | Implementar utilidades | 🟢 | `core/utils/*.dart` |
| 4.7 | Implementar manejo de errores | 🟢 | `core/errors/*.dart` |

---

## FASE 5: FRONTEND - DATA LAYER

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 5.1 | Implementar modelos con fromJson/toJson | 🟢 | `data/models/*.dart` |
| 5.2 | Implementar RemoteDataSources | 🟢 | `data/datasources/remote/*.dart` |
| 5.3 | Implementar LocalDataSources | 🟢 | `data/datasources/local/*.dart` |
| 5.4 | Implementar repositorios concretos | 🟢 | `data/repositories/*.dart` |

---

## FASE 6: FRONTEND - DOMAIN LAYER (USE CASES)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 6.1 | Implementar casos de uso de Ticket | 🟢 | `domain/usecases/ticket/*.dart` |
| 6.2 | Implementar casos de uso de User | 🟢 | `domain/usecases/user/*.dart` |
| 6.3 | Implementar casos de uso de Auth | 🟢 | `domain/usecases/auth/*.dart` |
| 6.4 | Implementar casos de uso de Area | 🟢 | `domain/usecases/area/*.dart` |

---

## FASE 7: FRONTEND - PANTALLA DE SELECCIÓN DE TICKETS (PÚBLICA)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 7.1 | Implementar TicketSelectionScreen | 🟢 | `presentation/screens/ticket_selection/` |
| 7.2 | Implementar widgets (AreaSelectorCard, TicketDisplay, etc.) | 🟢 | `presentation/screens/ticket_selection/widgets/` |
| 7.3 | Implementar auto-retorno 8s + integración impresión | 🟢 | `ticket_selection_screen.dart` |

---

## FASE 8: FRONTEND - PANTALLA DE ATENCIÓN (AGENTE)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 8.1 | Implementar LoginScreen + AuthProvider | 🟢 | `presentation/screens/login/`, `providers/` |
| 8.2 | Implementar AttentionScreen (panel del agente + timer) | 🟢 | `presentation/screens/attention/` |
| 8.3 | Implementar estados del agente (Libre/En Atención/Pausa) | 🟢 | `attention_screen.dart` |
| 8.4 | Implementar teclas de atajo (F1:Llamar, F2:Iniciar, F3:Finalizar, F4:Derivar) | 🟢 | `attention_screen.dart` |
| **8.5** | **Implementar PuestoSelectionScreen (selección post-login)** | 🟢 | `presentation/screens/puesto_selection/` |
| **8.6** | **Rediseñar PuestoSelectionScreen con Wrap responsive** | 🟢 | `puesto_selection_screen.dart` |
| 8.7 | Integrar WebSocket para recibir nuevos tickets en vivo | ⬜ | - |

---

## FASE 9: FRONTEND - DASHBOARD

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 9.1 | Implementar DashboardScreen (layout con filtros) | 🟢 | `presentation/screens/dashboard/` |
| 9.2 | Implementar StatsSummaryCard | 🟢 | inline en dashboard |
| 9.3 | Implementar gràfico de barras horario (fl_chart) | 🟢 | `presentation/screens/dashboard/widgets/hourly_bar_chart.dart` |
| 9.4 | Implementar desglose por agente/área | 🟢 | inline en dashboard |
| 9.5 | Implementar DashboardProvider | 🟢 | `providers/dashboard_provider.dart` |

---

## FASE 10: FRONTEND - MONITOR DE SALA (TV)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 10.1 | Crear MonitorScreen (split 65/35: video + cola) | 🟢 | `presentation/screens/monitor/monitor_screen.dart` |
| 10.2 | Implementar alerta visual de nuevo llamado (banner 4s) | 🟢 | `monitor_screen.dart` |
| 10.3 | Integrar WebSocket para TicketCalled en vivo | 🟢 | `monitor_screen.dart` |

---

## FASE 11: FRONTEND - CONFIGURACIÓN (ADMIN)

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 11.1 | Implementar SettingsScreen (navegación entre paneles) | 🟢 | `presentation/screens/settings/` |
| 11.2 | Implementar UserManagementPanel (CRUD usuarios) | 🟢 | `presentation/screens/settings/widgets/` |
| 11.3 | Implementar AreaManagementPanel (CRUD áreas) | 🟢 | `presentation/screens/settings/widgets/` |
| **11.4** | **Agregar _PuestoLayoutDialog a AreaManagementPanel** | 🟢 | `area_management_panel.dart` |
| 11.5 | Implementar VideoConfigPanel | 🟢 | `presentation/screens/settings/widgets/` |
| 11.6 | Implementar PrinterConfigPanel | 🟢 | `presentation/screens/settings/widgets/` |
| **11.7** | **Rediseñar SystemConfigPanel (reactivo, persistente, test conexión)** | 🟢 | `presentation/screens/settings/widgets/` |
| **11.8** | **Implementar KioskoManagementPanel** | 🟢 | `presentation/screens/settings/widgets/` |
| **11.9** | **Agregar serverUrl + persistencia a SettingsProvider** | 🟢 | `providers/settings_provider.dart` |
| **11.10** | **Agregar persistencia de tiempoEstimado y maxTickets** | 🟢 | `providers/settings_provider.dart` |
| 11.11 | Implementar SettingsProvider | 🟢 | `providers/settings_provider.dart` |

---

## FASE 12: MÓDULO DE IMPRESIÓN

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 12.1 | ESC/POS builder compacto (~6cm, 80mm) | 🟢 | `core/printing/esc_pos_commands.dart` |
| 12.2 | Network printer (TCP socket puerto 9100) | 🟢 | `core/printing/network_escpos_printer.dart` |
| 12.3 | Windows printer (Write-Printer + winspool.drv fallback) | 🟢 | `core/printing/windows_printer_service.dart` |
| 12.4 | PrintingProvider (config + estado) | 🟢 | `core/printing/printing_provider.dart` |

---

## FASE 13: MULTI-VENTANA Y CALLER DISPLAY

| # | Tarea | Estado | Archivos clave |
|---|---|---|---|
| 13.1 | Implementar CallerChannel (WindowMethodChannel) | 🟢 | `window/ticket_channel.dart` |
| 13.2 | Implementar CallerWindowApp (sub-ventana independiente) | 🟢 | `window/caller_app.dart` |
| 13.3 | Sincronizar estado TicketProvider → ventana caller | 🟢 | `ticket_provider.dart` broadcastToCaller() |
| 13.4 | Implementar CallerScreen (display público animado) | 🟢 | `presentation/screens/caller/caller_screen.dart` |

---

## FASE 14: INTEGRACIÓN Y PRUEBAS

| # | Tarea | Estado | Dependencias |
|---|---|---|---|
| 14.1 | flutter analyze: 0 errores, 0 warnings | 🟢 | Todas las fases |
| 14.2 | Pruebas de integración: flujo completo | 🟡 | Backend verificado, falta Flutter | Fases 7 + 8 |
| 14.3 | Pruebas de tiempo real: WebSocket múltiples clientes | ⬜ | - | Fase 3 |
| 14.4 | Pruebas de roles: admin vs caller vs atencion | ⬜ | - | Fase 8 + 11 |
| 14.5 | Pruebas de concurrencia: tickets simultáneos | ⬜ | - | Fase 7 + 8 |
| 14.6 | Pruebas de video: reproducción y cambio de fondo | ⬜ | Fase 7 + 11 |
| 14.7 | Pruebas de impresión (ESC/POS network + Windows) | ⬜ | Fase 12 |
| 14.8 | Pruebas de puesto: ocupación, liberación, bloqueo | 🟢 | Verificada |

---

## FASE 15: DESPLIEGUE Y DOCUMENTACIÓN FINAL

| # | Tarea | Estado | Descripción |
|---|---|---|---|
| 15.1 | Instalar Visual Studio con toolchain C++ | ⬜ | `flutter build windows` requiere VS Build Tools |
| 15.2 | Configurar entorno de producción | ⬜ | Firewall, HTTPS, certificados |
| 15.3 | Compilar Flutter para Windows (.exe) | ⬜ | `flutter build windows` |
| 15.4 | Actualizar documentación con cambios recientes | 🟢 | docs/*.md actualizados |

---

## RESUMEN DE PRIORIDADES

```
Completado (reciente):
  • Backend C#/.NET completo con Clean Architecture (Domain, Application, Infrastructure, API)
  • Login con correo electrónico en lugar de nombreUsuario
  • Roles BD normalizados: Administrador(1), Supervisor(2), Operador(3), Recepcion(4), Consulta(5), Llamador(6)
  • Área de usuario solo vía tabla UsuariosArea (muchos-a-muchos)
  • Multimedia: solo almacenar ruta, backend no sirve archivos
  • CRUD completo de usuarios con endpoint POST/PUT/DELETE
  • Ticket lifecycle completo: crear → llamar → iniciar atención → completar → cancelar
  • Dashboard con summary, by-area, by-user, hourly-breakdown
  • SignalR TicketHub en mismo puerto (5000/ticketHub)
  • Seeder con 6 usuarios de prueba, 3 áreas, Kioskos, Puestos
  • Migraciones EF Core (InitialCreate + FixAtencionCascade)
  • JWT Authentication + Refresh Tokens
  • Mapeo BD ↔ Frontend (MappingService)
  • API probada y funcionando en http://localhost:5000

Corregido (brechas encontradas en auditoría):
  • [Backend] Gap #1: POST /api/kioskos-fisicos (Crear) no aceptaba LogoUrl/VideoUrl
    → Agregados campos al DTO KioskoFisicoCreateRequest + handler multimedia en Crear()
    → Antes: solo Actualizar() manejaba multimedia. Ahora Crear() también.
  • [Backend] Gap #2: Se verificó que NO existe duplicación — el backend es la única
    fuente de verdad para la numeración de tickets (CrearTicketUseCase).
  • [Frontend] SettingsProvider: ahora persiste _selectedKioskoAreaIds, logoUrl, videoUrl
    en SharedPreferences y el getter selectedKiosko crea un KioskoMedia virtual como fallback.
  • [Frontend] CallerWindowApp: ahora tiene KioskoFisicoProvider + ApiClient en provider tree;
    _loadSettings() hace fetch a GET /api/kioskos-fisicos y actualiza SettingsProvider.

Pendiente Alta:
  • Ejecutar Flutter (`flutter run -d windows`) y conectar a backend real
  • Probar flujo completo desde la UI: login → atención → dashboard

Pendiente Media:
  • Probar WebSocket desde Flutter a /ticketHub
  • Probar multi-dispositivo (cambiar ApiConstants.baseUrl a IP local)
  • Agregar más roles frontend: supervisor, recepcion, consulta

Pendiente Baja:
  • Build Windows (.exe) para distribución
```

## NOTAS

- El proyecto funciona en **modo desarrollo con datos mock**. Los providers usan `DataStore` cuando no hay repositorio real.
- `flutter analyze` pasa con **0 errores**.
- Para buildear Windows se requiere **Visual Studio 2022** con carga de trabajo "Desarrollo para escritorio con C++".
- Toda nueva implementación debe actualizar esta documentación.
