import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'formulario_inscripcion.dart';

class DetalleVoluntariado extends StatefulWidget {
  final Map<String, dynamic> data;
  final String idPublicacion;
  final bool modoVistaInscrito;

  const DetalleVoluntariado({
    super.key,
    required this.data,
    required this.idPublicacion,
    this.modoVistaInscrito = false,
  });

  @override
  State<DetalleVoluntariado> createState() => _DetalleVoluntariadoState();
}

class _DetalleVoluntariadoState extends State<DetalleVoluntariado> {
  final List<Map<String, dynamic>> _turnosSeleccionados = [];

  // Color Nexus
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  String _obtenerImagenPorTipo(String? tipoRecibido) {
    if (widget.data['imagen_url'] != null &&
        widget.data['imagen_url'].toString().isNotEmpty) {
      return widget.data['imagen_url'];
    }

    final String tipo = (tipoRecibido ?? '').trim();

    // Imágenes del header
    // cada tipo de voluntariado tiene una imagen distinta que representa en general a la categoría de voluntariado
    // las imágenes han sido buscadas/elegidas de la página web de imgs/vídeos unsplash
    switch (tipo) {
      case 'Social':
        return "https://images.unsplash.com/photo-1599059813005-11265ba4b4ce?auto=format&fit=crop&w=800&q=80";
      case 'Ambiental':
        return "https://images.unsplash.com/photo-1758599668508-d8ec9eca1be3?auto=format&fit=crop&w=800&q=80";
      case 'Protección Civil':
        return "https://images.unsplash.com/photo-1593113630400-ea4288922497?auto=format&fit=crop&w=800&q=80";
      case 'Sociosanitario':
        return "https://images.unsplash.com/photo-1680759291238-2f4f9fac8d43?auto=format&fit=crop&w=800&q=80";
      case 'Educativo y Cultural':
        return "https://images.unsplash.com/photo-1616089804390-b2daa80dbf02?auto=format&fit=crop&w=800&q=80";
      case 'Deportivo':
        return "https://images.unsplash.com/photo-1774557937060-0fd4eaf90884?auto=format&fit=crop&w=800&q=80";
      default:
        return "https://images.unsplash.com/photo-1593113598332-cd288d649433?auto=format&fit=crop&w=800&q=80";
    }
  }

  bool _esPasado(String fecha, String rangoHora) {
    try {
      List<String> d = fecha.split('/');
      int dia = int.parse(d[0]);
      int mes = int.parse(d[1]);
      int anio = int.parse(d[2]);

      String horaInicioRaw = rangoHora.split('-')[0].trim();
      List<String> partesHora = horaInicioRaw.split(':');

      int hora = int.parse(partesHora[0]);
      int minuto = int.parse(partesHora[1]);

      DateTime fechaTurno = DateTime(anio, mes, dia, hora, minuto);

      return fechaTurno.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Stream<List<String>> _streamInscripciones() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('inscripciones')
        .where('voluntario_uid', isEqualTo: uid)
        .where('voluntariado_titulo', isEqualTo: widget.data['titulo'])
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            var t = d.data()['turno'];
            return "${t['fecha']}_${t['hora']}";
          }).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final String tipoActual = widget.data['tipo_voluntariado'] ?? 'General';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                elevation: 0,
                backgroundColor: _colorCorporativo,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildBotonGuardar(),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _compartirVoluntariado,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _obtenerImagenPorTipo(tipoActual),
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                              Colors.black26,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cuerpo central del voluntariado
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(125, 85, 133, 238),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tipoActual.toUpperCase(),
                              style: TextStyle(
                                color: _colorCorporativo,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        widget.data['titulo'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.corporate_fare_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.data['organizacion_nombre'] ??
                                'Organización',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Detalles agrupados en tarjetas
                      _buildCardSeccion(
                        "Descripción",
                        widget.data['descripcion'] ?? '',
                        Icons.description_outlined,
                      ),
                      _buildCardSeccion(
                        "Requisitos",
                        widget.data['requisitos'] ?? '',
                        Icons.assignment_late_outlined,
                      ),
                      _buildCardSeccion(
                        "Ubicación",
                        widget.data['direccion_exacta'] ?? '',
                        Icons.location_on_outlined,
                      ),

                      // Bloque/apartado para la sección de contactos
                      const Padding(
                        padding: EdgeInsets.only(left: 4, top: 10, bottom: 12),
                        child: Text(
                          "Medios de contacto",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues()),
                        ),
                        child: Column(
                          children: [
                            _buildIconInfo(
                              Icons.phone_rounded,
                              widget.data['telefono_contacto'],
                            ),
                            _buildIconInfo(
                              Icons.email_rounded,
                              widget.data['email_contacto'],
                            ),
                            _buildIconInfo(
                              Icons.language_rounded,
                              widget.data['web_contacto'],
                            ),
                            _buildIconInfo(
                              FontAwesomeIcons.instagram,
                              widget.data['instagram_user'],
                            ),
                            _buildIconInfo(
                              FontAwesomeIcons.xTwitter,
                              widget.data['twitter_user'],
                            ),
                            _buildIconInfo(
                              Icons.facebook_outlined,
                              widget.data['facebook_user'],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 12),

                      Text(
                        widget.modoVistaInscrito
                            ? "Mis turnos inscritos"
                            : "Turnos disponibles",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.modoVistaInscrito
                            ? "Estos son los horarios que tienes asignados"
                            : "Marca una o varias opciones para unirte",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      widget.modoVistaInscrito
                          ? _buildListaTurnosInscritos()
                          : _buildSelectorTurnos(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (!widget.modoVistaInscrito) _buildBotonFlotante(),
        ],
      ),
    );
  }

  Widget _buildCardSeccion(String titulo, String contenido, IconData icono) {
    if (contenido.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contenido,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('guardados')
          .doc(widget.idPublicacion)
          .snapshots(),
      builder: (context, snapshot) {
        bool estaGuardado = snapshot.hasData && snapshot.data!.exists;
        return IconButton(
          icon: Icon(
            estaGuardado
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return;
            final ref = FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .collection('guardados')
                .doc(widget.idPublicacion);

            if (estaGuardado) {
              await ref.delete();
            } else {
              await ref.set({
                'id_publicacion': widget.idPublicacion,
                'fecha_guardado': FieldValue.serverTimestamp(),
                'data': Map<String, dynamic>.from(widget.data),
              });
            }
          },
        );
      },
    );
  }

  Widget _buildSelectorTurnos() {
    return StreamBuilder<List<String>>(
      stream: _streamInscripciones(),
      builder: (context, snapInscritos) {
        final listadoInscritos = snapInscritos.data ?? [];
        final List<dynamic> turnos = widget.data['turnos'] ?? [];

        return Column(
          children: turnos.map((turno) {
            final String id = "${turno['fecha']}_${turno['hora']}";
            bool yaInscrito = listadoInscritos.contains(id);
            bool pasado = _esPasado(turno['fecha'], turno['hora']);
            int actual = turno['inscritos_reales'] ?? 0;
            int max = turno['voluntarios'] ?? 0;
            bool lleno = actual >= max;
            bool bloqueado = yaInscrito || pasado || lleno;
            bool seleccionado = _turnosSeleccionados.any(
              (t) => t['fecha'] == turno['fecha'] && t['hora'] == turno['hora'],
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: bloqueado
                    ? Colors.grey[50]
                    : (seleccionado ? Colors.white : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: seleccionado ? _colorCorporativo : _colorCorporativo,
                  width: seleccionado ? 2 : 1.5,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                onTap: bloqueado
                    ? null
                    : () {
                        setState(() {
                          if (seleccionado) {
                            _turnosSeleccionados.removeWhere(
                              (t) =>
                                  t['fecha'] == turno['fecha'] &&
                                  t['hora'] == turno['hora'],
                            );
                          } else {
                            _turnosSeleccionados.add(turno);
                          }
                        });
                      },
                leading: Icon(
                  seleccionado
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off_rounded,
                  color: bloqueado ? _colorCorporativo : _colorCorporativo,
                  size: 24,
                ),
                title: Text(
                  turno['fecha'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: bloqueado ? Colors.black38 : Colors.black87,
                    decoration: pasado ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      turno['hora'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    _labelEstado(yaInscrito, pasado, lleno),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    "$actual / $max",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: lleno ? Colors.red : Colors.black54,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBotonFlotante() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(color: Colors.white),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _turnosSeleccionados.isEmpty
                ? Colors.grey[300]
                : _colorCorporativo,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _turnosSeleccionados.isEmpty
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormularioInscripcionScreen(
                        dataVoluntariado: widget.data,
                        turnosSeleccionados: _turnosSeleccionados,
                        idPublicacion: widget.idPublicacion,
                      ),
                    ),
                  );
                  if (mounted) setState(() => _turnosSeleccionados.clear());
                },
          child: Text(
            _turnosSeleccionados.isEmpty
                ? "SOLICITAR UNIRSE"
                : "SOLICITAR UNIRSE",
            style: TextStyle(
              color: _turnosSeleccionados.isEmpty
                  ? Colors.black38
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icono, String? texto) {
    if (texto == null || texto.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icono, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelEstado(bool inscrito, bool pasado, bool lleno) {
    String t = "DISPONIBLE";
    Color c = Colors.green;
    if (inscrito) {
      t = "YA INSCRITO";
      c = Colors.blueGrey;
    } else if (pasado) {
      t = "FINALIZADO";
      c = Colors.red;
    } else if (lleno) {
      t = "COMPLETO";
      c = Colors.red;
    }

    return Text(
      t,
      style: TextStyle(
        color: c,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildListaTurnosInscritos() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inscripciones')
          .where('voluntario_uid', isEqualTo: uid)
          .where('id_publicacion', isEqualTo: widget.idPublicacion)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            var t = doc['turno'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colorCorporativo, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['fecha'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t['hora'],
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _compartirVoluntariado() {
    final String titulo = widget.data['titulo'] ?? '¡Mira este voluntariado!';
    final String id = widget.idPublicacion;
    final String deepLink = "nexo://voluntariado?id=$id";

    final String mensaje =
        "¡Hola! He visto este voluntariado y he pensado en ti:\n\n"
        "*$titulo*\n\n"
        "Puedes verlo aquí: $deepLink";

    SharePlus.instance.share(
      ShareParams(text: mensaje, subject: '¡Mira este voluntariado!'),
    );
  }
}
