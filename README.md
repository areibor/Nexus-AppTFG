# Desarrollo de una aplicación móvil multiplataforma para la mejora de la acción social de proximidad en Valencia

Nexus es una aplicación móvil multiplataforma diseñada para optimizar, centralizar y potenciar la interacción entre la ciudadanía activa (voluntarios) y las organizaciones del tercer sector en la provincia de Valencia. Este repositorio aloja el código fuente completo correspondiente al Trabajo de Fin de Grado (TFG) para el Grado en Tecnología Digital y Multimedia de la Universitat Politècnica de València (UPV).

## 🚀 Características Principales

- **Entorno Bimodal Automatizado:** Interfaz adaptativa según el rol del usuario autenticado (Voluntario u Organización).
- **Georreferenciación en Tiempo Real:** Integración cartográfica avanzada para la localización y proximidad de causas sociales.
- **Gestión Transaccional de Aforos:** Algoritmo dinámico de control de turnos y sincronización de asistencia en lotes (*batches*).
- **Diseño Inclusivo y Accesible:** Interfaz optimizada siguiendo criterios heurísticos de UX y accesibilidad visual.
- **Seguridad y Cumplimiento Normativo:** Infraestructura alineada con el RGPD y protegida mediante reglas estrictas de seguridad perimetral en la nube.

## 🛠️ Stack Tecnológico

- **Frontend / Cliente:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
- **Backend / Infraestructura:** [Firebase](https://firebase.google.com/) (Cloud Firestore NoSQL, Firebase Authentication)
- **Control de Versiones:** Git & GitHub

## 📂 Estructura General del Proyecto

```text
## Estructura General del Proyecto

```text
/lib
  ├── main.dart                                       # Punto de entrada y StreamBuilder de sesión
  ├── firebase_options.dart                           # Credenciales de compilación de las plataformas Android/iOS
  │
  ├── screens/                                        # Capa de Presentación (Interfaces de Usuario)
  │     ├── auth_screen.dart                          # Formulario bimodal de login y recuperación
  │     ├── main_screen.dart                          # Interceptor de seguridad y ruteador bimodal
  │     │
  │     ├── voluntario/                               # Subentorno exclusivo para el Rol Voluntario
  │     │     ├── home_voluntario.dart                # Motor de búsqueda y exploración de voluntariados
  │     │     ├── filtros.dart                        # Hoja flotante de criterios de búsqueda (Chips/Sliders)
  │     │     ├── mapa_screen.dart                    # Instanciación de Google Maps y marcadores GPS
  │     │     ├── detalle_voluntariado.dart           # Ficha extendida, control horario y mapa de turnos
  │     │     └── formulario_inscripcion.dart         # Formulario modular de postulación legal
  │     │
  │     ├── organizacion/                             # Subentorno exclusivo para el Rol Organización
  │     │     ├── mis_publicaciones.dart              # Lista de acciones sociales y control táctil Dismissible
  │     │     ├── formulario_publicar.dart            # Formulario de alta con geocodificación automática
  │     │     └── detalle_publicacion.dart            # Monitor de aforos y gestión transaccional de candidatos
  │     │
  │     └── perfil/                                   # Módulos comunes de gestión de usuario
  │           ├── perfil_screen.dart                  # Avatar, contabilidad de horas y zócalo de navegación
  │           ├── editar_perfil_screen.dart           # Formulario adaptativo de actualización de datos
  │           ├── cuenta_screen.dart                  # Menú de seguridad y blindaje de rutas
  │           ├── notificaciones_screen.dart          # Panel frontend de preferencias de privacidad
  │           ├── filtros_aplicaciones.dart           # Hoja modal de filtrado por estados de postulación
  │           ├── guardados_screen.dart               # Historial dinámico de voluntariados marcados como favoritas
  │           ├── aplicaciones_screen.dart            # Visor de inscripciones agrupadas por código de causa
  │           ├── calendario_screen.dart              # TableCalendar sincronizado con turnos aceptados
  │           └── detalle_inscripcion_voluntario.dart # Ficha técnica de validación de candidatos
  │
  └── widgets/                                            
        └── tarjeta_voluntariado.dart                 # Componente visual reutilizable de tarjeta con feed dinámico
