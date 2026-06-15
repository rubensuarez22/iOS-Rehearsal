# Aplicación Móvil Nativa Rick and Morty (iOS)

Este proyecto consiste en una aplicación nativa para iOS que consume la API pública de Rick and Morty. El diseño e implementación siguen principios de arquitectura limpia (Clean Architecture), patrón de diseño MVVM, persistencia local robusta, seguridad biométrica, integración con mapas y pruebas automatizadas (unitarias y de interfaz).

## Requerimientos y Tecnologías

El proyecto requiere las siguientes herramientas y dependencias:
- Xcode 15.0 o posterior
- iOS 17.6 o posterior
- Swift 5.10 / Swift Concurrency (async/await)
- Combine para programación reactiva en flujos específicos
- CoreData para la persistencia local (offline-first)
- LocalAuthentication para la integración de sensores biométricos (Face ID / Touch ID)
- MapKit para la visualización de ubicaciones
- Swinject para la inyección de dependencias centralizada
- SwiftLint para el análisis estático del código

## Arquitectura del Proyecto

Se ha implementado una arquitectura limpia organizada en tres capas principales con un acoplamiento débil, permitiendo alta testabilidad y escalabilidad del código:

### Capa de Dominio (Domain)
Es una capa pura de Swift sin dependencias de frameworks de persistencia o interfaz de usuario.
- Modelos: Entidades puras de negocio (Character, Episode, LocationModel).
- Repositorios: Definición de contratos (protocolos) para la obtención de datos.
- Casos de Uso: Lógica de negocio específica (GetCharactersUseCase, ToggleFavoriteUseCase, GetEpisodeDetailsUseCase, AuthenticateBiometricsUseCase).

### Capa de Datos (Data)
Implementa los contratos de los repositorios y gestiona la procedencia de la información.
- Repositorios: CharacterRepository gestiona la lógica de sincronización entre la API remota y la base de datos local (CoreData).
- Cliente de Red: APIClient realiza peticiones asíncronas mediante URLSession empleando async/await y decodifica las respuestas DTO.
- Base de Datos Local: Sincronización transparente con CoreData para ofrecer soporte offline y resiliencia ante errores de red o límites de peticiones (Rate Limiting).
- Mapeadores: Convierte los DTOs de red y entidades de CoreData en modelos puros de dominio.

### Capa de Presentación (Presentation)
Implementa la interfaz de usuario con SwiftUI y la gestión de estado con ViewModels.
- Vistas: Pantallas y componentes modulares construidos en SwiftUI. Utiliza técnicas de navegación perezosa (Lazy Navigation) en la resolución de dependencias para evitar fugas de memoria y sobrecargas de rendimiento.
- ViewModels: Clases de estado que se ejecutan en el MainActor para garantizar la seguridad de la concurrencia en el hilo principal de la interfaz gráfica.

## Funcionalidades Implementadas

### Pantalla Principal - Listado de Personajes
- Visualización en lista optimizada de personajes incluyendo nombre, especie, estado y fotografía.
- Paginación automática con scroll infinito optimizado.
- Filtros interactivos por estado (Vivo, Muerto, Desconocido), especie y búsqueda dinámica por nombre.
- Pull to refresh para forzar la sincronización directa con la API de red.
- Gestión visual de estados de carga, vistas vacías y errores de conexión.

### Pantalla de Detalle de Personaje
- Visualización completa de información general, género, especie, estado y ubicación.
- Listado optimizado de los episodios en los que participa el personaje.
- Opción de marcar/desmarcar el personaje como favorito.
- Opción de marcar episodios individuales como vistos, persistiendo este estado de forma local.
- Integración con MapKit a través del botón de visualización en mapa.

### Pantalla de Favoritos
- Listado exclusivo de los personajes almacenados como favoritos.
- Acceso restringido y protegido mediante autenticación biométrica (Face ID o Touch ID).
- Bloqueo manual directo desde la barra de navegación para proteger la privacidad del usuario.

### Vista de Ubicación en Mapa
- Mapa interactivo con MapKit.
- Visualización de la última ubicación conocida del personaje (coordenadas simuladas específicas por personaje).
- Marcador personalizado (Pin) con la información básica del personaje al interactuar con él.

## Seguridad y Resiliencia de Datos

### Autenticación Biométrica
Utiliza el framework de LocalAuthentication. El acceso a la sección de favoritos requiere verificación exitosa de Face ID/Touch ID. Si el hardware no está disponible, el sistema informa adecuadamente al usuario.

### Persistencia Offline-First
La app almacena de manera local:
- Listados de personajes y sus detalles.
- Estado de los favoritos.
- Relación de episodios vistos.
Ante problemas de red o límites en el servidor (HTTP 429 Too Many Requests), la aplicación realiza una transición transparente al almacenamiento caché de CoreData sin interrumpir la navegación del usuario.

## Logging Estructurado y Manejo de Errores

### Registro de Logica (Logging)
Se ha implementado la estructura de AppLogger utilizando el framework nativo de Apple unified logging system (os.log). Permite la clasificación de logs en categorías específicas:
- Network
- Database
- Security
- Presentation
- General

### Gestión de Errores
Los errores del cliente de red, del sistema de base de datos local y de la autenticación biométrica están fuertemente tipados a través de enums conformes a LocalizedError. La aplicación cuenta con flujos de recuperación, estados alternativos (fallbacks) y botones de reintento en pantalla para garantizar una experiencia fluida.

## Pruebas y Calidad de Código

### Pruebas Unitarias
Las pruebas cubren la lógica de negocio en la capa de dominio y casos de uso, abstrayendo los servicios externos a través de dobles de prueba (Mocks).
- Pruebas del flujo de paginación y filtros de personajes.
- Pruebas de la lógica de marcación de episodios y favoritos.
- Pruebas de simulación biométrica.

### Pruebas de Interfaz de Usuario (UI Tests)
Se ha implementado una prueba instrumentada completa que simula un flujo completo del usuario en la aplicación de principio a fin.
Para evitar el bloqueo de la ejecución por las alertas nativas del sistema de Face ID en los entornos de integración continua o simuladores, la ejecución del test de UI arranca la app con el argumento `--uitesting`. Esto instruye a la inyección de dependencias a utilizar una versión simulada de autenticación biométrica (`FakeBiometricAuthenticator`) para completar el flujo automáticamente de forma determinista.

### Calidad de Código
El proyecto contiene configuración activa de SwiftLint (`.swiftlint.yml`) para forzar un estilo homogéneo de desarrollo nativo. Asimismo, todas las pantallas soportan orientación vertical, horizontal y adaptabilidad a diversos tamaños de pantallas (iPad e iPhone).

## Instrucciones de Ejecución

Sigue estos pasos para compilar y ejecutar el proyecto en tu máquina local:

1. Clonar el repositorio:
```bash
git clone https://github.com/rubensuarez22/iOS-Rehearsal.git
cd iOS-Rehearsal
```

2. Abrir el proyecto en Xcode:
```bash
open iOS-Rehearsal.xcodeproj
```

3. Resolución de dependencias:
Xcode resolverá de manera automática las dependencias del gestor de paquetes de Swift (Swift Package Manager) especificadas en el proyecto (Swinject). Espera a que finalice la sincronización.

4. Compilación y ejecución:
- Selecciona el simulador deseado (ej. iPhone 16 con iOS 17.6 o superior) o un dispositivo iOS conectado.
- Presiona `Cmd + R` en Xcode para compilar e iniciar la aplicación.

5. Ejecución de Pruebas:
- Presiona `Cmd + U` en Xcode para ejecutar toda la suite de pruebas unitarias y de interfaz.
- Alternativamente, puedes ejecutar las pruebas mediante la terminal usando:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project iOS-Rehearsal.xcodeproj \
  -scheme iOS-Rehearsal \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
```
