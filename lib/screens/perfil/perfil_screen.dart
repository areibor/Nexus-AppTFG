import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'calendario_screen.dart';
import 'cuenta_screen.dart';
import 'aplicaciones_screen.dart';
import 'guardados_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  // Color corporativo unificado
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  bool _turnoFinalizado(String fechaStr, String horarioStr) {
    try {
      List<String> partesFecha = fechaStr.split('/');
      int dia = int.parse(partesFecha[0]);
      int mes = int.parse(partesFecha[1]);
      int anio = int.parse(partesFecha[2]);

      List<String> partesHorario = horarioStr.split(' - ');
      String horaFinStr = partesHorario[1];

      DateTime horaFinDt = _parsearHoraConFecha(horaFinStr, anio, mes, dia);
      return DateTime.now().isAfter(horaFinDt);
    } catch (e) {
      return false;
    }
  }

  DateTime _parsearHoraConFecha(String horaStr, int anio, int mes, int dia) {
    final formato = horaStr.trim().toUpperCase();
    int hora = int.parse(formato.split(':')[0]);
    int minuto = int.parse(formato.split(':')[1].split(' ')[0]);
    bool esPM = formato.contains('PM');

    if (esPM && hora != 12) hora += 12;
    if (!esPM && hora == 12) hora = 0;

    return DateTime(anio, mes, dia, hora, minuto);
  }

  double _calcularHorasDeTurno(String horario) {
    try {
      // Limpiamos espacios por si acaso
      List<String> partes = horario.split(' - ');
      if (partes.length < 2) return 0;

      // Parseamos hora y minuto directamente sin depender de fechas complejas
      List<String> horaMinInicio = partes[0].trim().split(':');
      List<String> horaMinFin = partes[1].trim().split(':');

      int minsInicio =
          (int.parse(horaMinInicio[0]) * 60) + int.parse(horaMinInicio[1]);
      int minsFin = (int.parse(horaMinFin[0]) * 60) + int.parse(horaMinFin[1]);

      // Si la hora de fin es menor, es que pasa de medianoche (ej: 23:00 a 02:00)
      if (minsFin < minsInicio) {
        minsFin += 24 * 60;
      }

      double resultadoHoras = (minsFin - minsInicio) / 60.0;

      // 🌟 ESTE PRINT APARECERÁ EN TU CONSOLA DE VS CODE / ANDROID STUDIO
      // Te dirá exactamente qué string está leyendo y qué número está calculando
      debugPrint(
        "NEXO_DEBUG: Horario leído: '$horario' -> Horas calculadas: $resultadoHoras",
      );

      return resultadoHoras;
    } catch (e) {
      debugPrint("NEXO_DEBUG: Error parseando horario: $e");
      return 0;
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Actualizar foto de perfil",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.photo_library_outlined,
              color: _colorCorporativo,
            ),
            title: const Text("Elegir de la galería"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: _colorCorporativo),
            title: const Text("Tomar una foto"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (source == null) return;

    final XFile? imagen = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (imagen == null) return;

    try {
      File file = File(imagen.path);
      Reference ref = FirebaseStorage.instance.ref().child('perfiles/$uid.jpg');
      UploadTask uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() => null);

      String urlDescarga = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'foto_perfil': urlDescarga,
      });
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const Scaffold(
            body: Center(child: Text("Cerrando sesión...")),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String rol = userData['rol'] ?? 'Voluntario';

        return Scaffold(
          backgroundColor: Colors.grey[100], // Fondo premium más limpio
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 🌟 BANNER SUPERIOR CON DEGRADADO CORPORATIVO
                _buildBannerHeader(userData, rol),
                const SizedBox(height: 24),

                // 🌟 SECCIONES DE MENÚ SEGÚN EL ROL
                if (rol == 'Voluntario') ...[
                  _buildSeccionMenu([
                    _buildItemLista(
                      texto: "Guardado",
                      icono: Icons.bookmark_border_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GuardadosScreen(),
                        ),
                      ),
                    ),
                    _buildItemLista(
                      texto: "Inscripciones",
                      icono: Icons.assignment_turned_in_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AplicacionesScreen(),
                        ),
                      ),
                    ),
                    _buildItemLista(
                      texto: "Calendario",
                      icono: Icons.calendar_today_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarioScreen(),
                        ),
                      ),
                    ),
                  ]),
                ],

                _buildSeccionMenu([
                  _buildItemLista(
                    texto: "Configuración de la cuenta",
                    icono: rol == 'Organización'
                        ? Icons.settings_outlined
                        : Icons.person_outline_rounded,
                    onTap: () => _irACuenta(),
                  ),
                  _buildItemLista(
                    texto: "Soporte técnico",
                    icono: Icons.help_outline_rounded,
                    onTap: () => _mostrarSoporte(),
                  ),
                ]),

                _buildSeccionMenu([
                  _buildItemLista(
                    texto: "Cerrar sesión",
                    icono: Icons.logout_rounded,
                    esRojo: true,
                    onTap: () => FirebaseAuth.instance.signOut(),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget del banner superior con estética moderna
  Widget _buildBannerHeader(Map<String, dynamic> data, String rol) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorCorporativo,
            _colorCorporativo
                .withBlue(220)
                .withGreen(100), // Degradado sutil moderno
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
      child: Row(
        children: [
          _buildFotoPerfilConBoton(data['foto_perfil']),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['nombre'] ?? "Usuario",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _buildSubtituloDinamico(rol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construcción del avatar redondo con un botón flotante de edición integrado
  Widget _buildFotoPerfilConBoton(String? url) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Colors.grey[200],
            backgroundImage: (url != null && url.isNotEmpty)
                ? NetworkImage(url)
                : null,
            child: (url == null || url.isEmpty)
                ? Icon(Icons.person_rounded, size: 48, color: Colors.grey[400])
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _cambiarFotoPerfil,
            child: Container(
              height: 28,
              width: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: _colorCorporativo,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Subtítulos dinámicos según el tipo de rol cargados asíncronamente
  Widget _buildSubtituloDinamico(String rol) {
    if (rol == 'Voluntario') {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('inscripciones')
            .where('voluntario_uid', isEqualTo: user?.uid)
            .where('estado', isEqualTo: 'Aceptado')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(
              "Cargando...",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            );
          }

          Map<String, Map<String, dynamic>> turnosUnicosProcesados = {};

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Extraemos los datos del turno de forma segura
            String idPub =
                data['id_publicacion'] ??
                data['voluntariado_uid_publicacion'] ??
                doc.id;
            String? fecha = data['turno']?['fecha'];
            String? horario = data['turno']?['hora'];
            String? estado =
                data['estado']; // Obtenemos el estado de la inscripción

            // 🌟 REGLA DE ORO TFG: Solo computan las causas donde el voluntario ha sido "Aceptado"
            if (fecha != null && horario != null && estado == 'Aceptado') {
              // Creamos una clave única indestructible para este turno específico
              String llaveTurno = "${idPub}_${fecha}_$horario";

              if (!turnosUnicosProcesados.containsKey(llaveTurno)) {
                turnosUnicosProcesados[llaveTurno] = data;
              }
            }
          }

          double totalHoras = 0;
          int completados = 0;

          // 🌟 CÁLCULO SOBRE LA LISTA DEPURADA
          for (var insc in turnosUnicosProcesados.values) {
            String fecha = insc['turno']['fecha'];
            String horario = insc['turno']['hora'];

            // Comprobamos si el turno ya ha pasado en el tiempo
            if (_turnoFinalizado(fecha, horario)) {
              completados++;
              totalHoras += _calcularHorasDeTurno(horario);
            }
          }

          String textoHoras = totalHoras == 1.0 ? "h servida" : "h servidas";
          String textoVoluntariados = completados == 1
              ? "voluntariado"
              : "voluntariados";

          return Text(
            "${totalHoras.toStringAsFixed(1)} $textoHoras  •  $completados $textoVoluntariados",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      );
    } else {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('voluntariados')
            .where('organizacion_uid', isEqualTo: user?.uid)
            .get(),
        builder: (context, snapshot) {
          int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Text(
            "$total publicaciones activas",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      );
    }
  }

  // Contenedor unificado para agrupar ítems del menú de forma elegante
  Widget _buildSeccionMenu(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isEven) {
            return items[index ~/ 2];
          } else {
            return const Divider(
              height: 0.5,
              indent: 54,
              endIndent: 16,
              color: Colors.grey,
            );
          }
        }),
      ),
    );
  }

  // Elemento individual de la lista de menú
  Widget _buildItemLista({
    required String texto,
    required IconData icono,
    required VoidCallback onTap,
    bool esRojo = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icono, color: esRojo ? Colors.red : Colors.black, size: 20),
      ),
      title: Text(
        texto,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: esRojo ? Colors.red : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: esRojo ? Colors.red : Colors.black26,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _irACuenta() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CuentaScreen()),
    );
  }

  void _mostrarSoporte() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Colors.black),
            SizedBox(width: 10),
            Text("Soporte"),
          ],
        ),
        content: const Text(
          "¿Tienes alguna duda o problema?\n\nContáctanos en:\nsoporte@nexus.org",
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CERRAR",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
