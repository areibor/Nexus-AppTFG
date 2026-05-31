import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_inscripcion_voluntario.dart';

class DetallePublicacionOrg extends StatelessWidget {
  final Map<String, dynamic> data;
  final String idPublicacion;

  const DetallePublicacionOrg({
    super.key,
    required this.data,
    required this.idPublicacion,
  });

  // Color corporativo unificado de tu app
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo limpio unificado
      appBar: AppBar(
        title: const Text(
          "Gestión Voluntariado",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('voluntariados')
            .doc(idPublicacion)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var pubData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> turnos = pubData['turnos'] ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TÍTULO DE LA PUBLICACIÓN DE GRAN FORMATO
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    data['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. SECCIÓN: ESTADO DE TURNOS
                _buildSubtituloSeccion("ESTADO DE LOS TURNOS"),

                // LISTA HORIZONTAL DE TURNOS
                SizedBox(
                  height: 125,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: turnos.length,
                    itemBuilder: (context, index) {
                      var turno = turnos[index];
                      return _buildTarjetaTurnoEstado(turno);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 3. SECCIÓN: CANDIDATOS INSCRITOS
                _buildSubtituloSeccion("CANDIDATOS INSCRITOS"),

                // LISTADO DE VOLUNTARIOS (STREAM)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inscripciones')
                      .where('voluntariado_titulo', isEqualTo: data['titulo'])
                      .where(
                        'organizacion_uid',
                        isEqualTo: data['organizacion_uid'],
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Todavía no hay candidatos inscritos en esta publicación.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // AGRUPACIÓN POR VOLUNTARIO
                    Map<String, Map<String, dynamic>> candidatosAgrupados = {};
                    for (var doc in docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final uid = d['voluntario_uid'];

                      if (!candidatosAgrupados.containsKey(uid)) {
                        candidatosAgrupados[uid] = {
                          'info': d,
                          'ids_inscripciones': [doc.id],
                          'turnos_solicitados': [d['turno']],
                        };
                      } else {
                        candidatosAgrupados[uid]!['ids_inscripciones'].add(
                          doc.id,
                        );
                        candidatosAgrupados[uid]!['turnos_solicitados'].add(
                          d['turno'],
                        );
                      }
                    }

                    final listaCandidatos = candidatosAgrupados.values.toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: listaCandidatos.length,
                      itemBuilder: (context, index) {
                        final candidato = listaCandidatos[index];
                        final infoCandidato = candidato['info'];
                        final String estado =
                            infoCandidato['estado'] ?? 'pendiente';

                        Color colorEstado = Colors.orange;
                        if (estado == 'Aceptado') colorEstado = Colors.green;
                        if (estado == 'Rechazado') colorEstado = Colors.red;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(),
                                blurRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetalleInscripcionVoluntario(
                                        inscripcionData: infoCandidato,
                                        idsInscripciones:
                                            candidato['ids_inscripciones'],
                                        idPublicacion: idPublicacion,
                                        turnosActuales: turnos,
                                        turnosSolicitados:
                                            candidato['turnos_solicitados'],
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('usuarios')
                                        .doc(infoCandidato['voluntario_uid'])
                                        .get(),
                                    builder: (context, snapUser) {
                                      String? urlFoto;
                                      if (snapUser.hasData &&
                                          snapUser.data!.exists) {
                                        urlFoto =
                                            (snapUser.data!.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['foto_perfil'];
                                      }
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[100],
                                          border: Border.all(
                                            color: Colors.grey.withValues(),
                                          ),
                                          image:
                                              (urlFoto != null &&
                                                  urlFoto.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(urlFoto),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child:
                                            (urlFoto == null || urlFoto.isEmpty)
                                            ? Icon(
                                                Icons.person_outline_rounded,
                                                color: Colors.grey[400],
                                                size: 22,
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, // Todo alineado a la izquierda
                                      children: [
                                        Text(
                                          infoCandidato['personal']['nombre'] ??
                                              'Voluntario',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Solicitó ${candidato['turnos_solicitados'].length} turno(s)",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ), // Espacio intermedio suave
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            estado.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colorEstado,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- COMPONENTES DE INTERFAZ AUXILIARES ---

  Widget _buildSubtituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Text(
        titulo,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTarjetaTurnoEstado(Map<String, dynamic> turno) {
    int inscritos = turno['inscritos_reales'] ?? 0;
    int cupo = turno['voluntarios'] ?? 0;

    return Container(
      width: 155,
      margin: const EdgeInsets.only(left: 4, right: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turno['fecha'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                turno['hora'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cupo",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  "$inscritos/$cupo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _colorCorporativo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
