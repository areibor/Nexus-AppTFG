```mermaid
graph TD
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px,color:#000;
    classDef corporativo fill:#1147BC,stroke:#0d3996,stroke-width:2px,color:#fff;
    classDef proceso fill:#e3f2fd,stroke:#1147BC,stroke-width:1px,color:#000;
    classDef decision fill:#fff9c4,stroke:#fbc02d,stroke-width:1px,color:#000;

    Inicio([Splash Screen / Launch App]) --> Login{¿Usuario Autenticado?}:::decision
    
    Login -- No --> AuthScreen[Auth Screen: Login / Registro]:::proceso
    Login -- Sí --> ValidarRol{Validar Rol en Firestore}:::decision
    
    AuthScreen --> OlvidoPass{¿Olvidó Contraseña?}:::decision
    OlvidoPass -- Sí --> PopUpReset[Pop-up: Confirmar envío de Email]:::proceso
    PopUpReset --> AuthScreen
    
    AuthScreen --> RegistroForm[Formulario Registro: Elegir Rol]:::proceso
    RegistroForm --> ValidarRol
    
    ValidarRol --> |"Rol: Voluntario"| HomeVoluntario[Home Screen: Voluntario]:::corporativo
    ValidarRol --> |"Rol: Organización"| HomeONG[Home Screen: ONG/Particular]:::corporativo

    HomeVoluntario --> DetalleCausaVol[Detalle de la Causa]:::proceso
    DetalleCausaVol --> ListadoTurnos[Visualizar Turnos Disponibles]:::proceso
    ListadoTurnos --> Inscripcion{¿Inscribirse en Turno?}:::decision
    Inscripcion -- Sí --> CheckCupo{¿Hay cupo libre?}:::decision
    CheckCupo -- Sí --> Inscribir[Inscripción en Firestore]:::proceso
    Inscribir --> PerfilVoluntario[Perfil: Ver Mis Turnos]:::proceso
    
    HomeONG --> CrearCausa[Formulario: Publicar Nueva Causa]:::proceso
    CrearCausa --> ConfigurarTurnos[Añadir Turnos y Configurar Cupos]:::proceso
    ConfigurarTurnos --> GuardarFirestore[Guardar Causa en Firestore]:::proceso
    GuardarFirestore --> HomeONG
    
    HomeONG --> DetalleCausaONG[Detalle de Causa Publicada]:::proceso
    DetalleCausaONG --> GestionVoluntarios[Ver Lista de Voluntarios Inscritos]:::proceso

    HomeVoluntario --> CuentaScreen[Configuración de Cuenta]:::proceso
    HomeONG --> CuentaScreen
    CuentaScreen --> CambiarPass[Restablecer Contraseña]:::proceso
    CuentaScreen --> Logout[Cerrar Sesión]:::proceso
    Logout --> AuthScreen