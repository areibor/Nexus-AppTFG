import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_perfil_screen.dart';
import 'notificaciones_screen.dart';

class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});

  @override
  State<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Color corporativo unificado de tu app
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  void _cambiarPassword() {
    if (user?.email == null) return;

    // 🌟 1. POP-UP DE CONFIRMACIÓN PREVIA (Evita envíos accidentales)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "¿Restablecer contraseña?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Se enviará un enlace de recuperación al correo electrónico asociado a esta cuenta:\n\n${user!.email}\n\n¿Deseas continuar?",
          ),
          actions: [
            // Botón Cancelar
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Cierra el pop-up sin hacer nada
              child: const Text(
                "CANCELAR",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Botón Confirmar
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el pop-up de confirmación
                _ejecutarEnvioCorreo(); // Ejecuta la lógica asíncrona de Firebase
              },
              child: const Text(
                "CONFIRMAR",
                style: TextStyle(
                  color: Color.fromARGB(255, 17, 71, 188),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🌟 2. LÓGICA INTERNA ASÍNCRONA (Se ejecuta solo al pulsar CONFIRMAR)
  Future<void> _ejecutarEnvioCorreo() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;

      // Diálogo de éxito
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Correo Enviado"),
            content: Text(
              "Se ha enviado un correo a ${user!.email} para restablecer tu contraseña.\n\nRevisa la carpeta de correo no deseado.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CERRAR",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      // Diálogo de error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Error"),
            content: const Text("Error al enviar el correo de recuperación."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CERRAR",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors
          .grey[100], // Fondo limpio premium coincidente con Home y Perfil
      appBar: AppBar(
        title: const Text(
          "Configuración de cuenta",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar datos"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("No se encontraron datos del usuario"),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          bool esOrganizacion = userData['rol'] == 'Organización';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // CONTENEDOR 1: EDITAR Y CONTRASEÑA
                _buildContenedorGrupo([
                  _buildListTile(
                    icono: Icons.edit_note_rounded,
                    titulo: "Editar perfil",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditarPerfilScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    icono: Icons.lock_reset_rounded,
                    titulo: "Cambiar contraseña",
                    onTap: _cambiarPassword,
                  ),
                ]),

                // CONTENEDOR 2: NOTIFICACIONES E IDIOMAS
                _buildContenedorGrupo([
                  _buildListTile(
                    icono: Icons.notifications_none_rounded,
                    titulo: "Notificaciones",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificacionesScreen(
                            esOrganizacion: esOrganizacion,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    icono: Icons.translate_rounded,
                    titulo: "Idiomas",
                    onTap: () => _mostrarIdiomas(context),
                  ),
                ]),

                // CONTENEDOR 3: ELIMINAR CUENTA (BLOQUE DE ACCIÓN DE PELIGRO)
                _buildContenedorGrupo([
                  _buildListTile(
                    icono: Icons.delete_forever_rounded,
                    titulo: "Eliminar cuenta",
                    onTap: () => _confirmarEliminarCuenta(context),
                    esRojo: true,
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- COMPONENTES DE DISEÑO OPTIMIZADOS ---

  Widget _buildContenedorGrupo(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isEven) {
            return items[index ~/ 2];
          } else {
            // Indentación perfecta: El separador empieza donde empieza el texto de la opción
            return const Divider(
              height: 1,
              indent: 54,
              endIndent: 16,
              color: Colors.black12,
            );
          }
        }),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icono,
    required String titulo,
    required VoidCallback onTap,
    bool esRojo = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icono,
          color: esRojo ? Colors.red : Colors.black87,
          size: 20,
        ),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontSize: 15,
          color: esRojo ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w600, // Un toque más marcado semibold moderno
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: esRojo ? Colors.red.withValues() : Colors.black26,
      ),
      onTap: onTap,
    );
  }

  // --- VENTANAS Y DIÁLOGOS ESTILIZADOS ---

  void _mostrarIdiomas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Seleccionar idioma",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.black12),
              _buildIdiomaOption("Español", true),
              _buildIdiomaOption("Valenciano", false),
              _buildIdiomaOption("Inglés", false),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdiomaOption(String nombre, bool seleccionado) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        nombre,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          color: seleccionado ? _colorCorporativo : Colors.black87,
        ),
      ),
      trailing: seleccionado
          ? Icon(Icons.check_circle_rounded, color: _colorCorporativo)
          : null,
      onTap: () => Navigator.pop(context),
    );
  }

  void _confirmarEliminarCuenta(BuildContext context) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: const Text("Eliminar cuenta"),

        content: const Text(
          "¿Estás seguro/a de eliminar la cuenta?\n\nUna vez elimines la cuenta no será posible recuperarla y todas las aplicaciones e historial se perderán.",
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            onPressed: () {
              // Lógica para borrar usuario en Firebase Auth y Firestore

              Navigator.pop(context);
            },

            child: const Text(
              "ELIMINAR CUENTA",

              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
