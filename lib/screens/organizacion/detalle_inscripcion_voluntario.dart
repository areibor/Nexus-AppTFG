import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalleInscripcionVoluntario extends StatelessWidget {
  final Map<String, dynamic> inscripcionData;
  final List<dynamic> idsInscripciones;
  final List<dynamic> turnosSolicitados;
  final String idPublicacion;
  final List<dynamic> turnosActuales;

  const DetalleInscripcionVoluntario({
    super.key,
    required this.inscripcionData,
    required this.idsInscripciones,
    required this.turnosSolicitados,
    required this.idPublicacion,
    required this.turnosActuales,
  });

  // Color Nexus
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  Future<void> _actualizarEstadoMultiple(
    BuildContext context,
    String nuevoEstado,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      if (nuevoEstado == 'Aceptado') {
        List<dynamic> turnosUpdate = List.from(turnosActuales);

        for (var turnoSol in turnosSolicitados) {
          for (var tPub in turnosUpdate) {
            if (tPub['fecha'] == turnoSol['fecha'] &&
                tPub['hora'] == turnoSol['hora']) {
              tPub['inscritos_reales'] = (tPub['inscritos_reales'] ?? 0) + 1;
            }
          }
        }
        batch.update(
          FirebaseFirestore.instance
              .collection('voluntariados')
              .doc(idPublicacion),
          {'turnos': turnosUpdate},
        );
      }

      for (var idDoc in idsInscripciones) {
        batch.update(
          FirebaseFirestore.instance.collection('inscripciones').doc(idDoc),
          {'estado': nuevoEstado},
        );
      }

      await batch.commit();

      if (!context.mounted) return;
      Navigator.pop(context); // Quita el cargando
      Navigator.pop(context); // Para volver atrás

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Candidato $nuevoEstado en todos sus turnos"),
          backgroundColor: nuevoEstado == 'Aceptado'
              ? Colors.grey
              : Colors.grey,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint("Error al actualizar estados en lote: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final personal = inscripcionData['personal'] ?? {};
    final perfil = inscripcionData['perfil'] ?? {};
    final logistica = inscripcionData['salud_logistica'] ?? {};
    final List<dynamic> idiomas = perfil['idiomas'] ?? [];
    final String estadoActual =
        inscripcionData['estado']?.toString().toLowerCase() ?? 'pendiente';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Detalle Inscripción",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              20,
              16,
              estadoActual == 'pendiente' ? 120 : 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turnos solicitados
                _buildTituloSeccion("TURNOS SOLICITADOS"),
                ...turnosSolicitados.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _colorCorporativo.withValues()),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: _colorCorporativo,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${t['fecha']}   •   ${t['hora']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _colorCorporativo,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Disponibilidad y compromiso
                _buildFichaDatos("DISPONIBILIDAD Y COMPROMISO", [
                  _buildFilaInfo(
                    "Disponibilidad",
                    logistica['disponibilidad_total'],
                  ),
                  _buildFilaInfo(
                    "Transporte Propio",
                    logistica['transporte_propio'],
                  ),
                  _buildFilaInfo(
                    "Compromiso de Asistencia",
                    logistica['compromiso_asistencia'],
                  ),
                ]),

                // Autorizaciones
                _buildFichaDatos("AUTORIZACIONES Y DOCUMENTACIÓN", [
                  _buildFilaInfo(
                    "Cesión de Imagen",
                    logistica['autorizacion_imagen'] == true ? 'SÍ' : 'NO',
                    destacarBooleano: true,
                  ),
                  _buildFilaInfo(
                    "Certificado de Delitos",
                    logistica['certificado_delitos'] == true ? 'SÍ' : 'NO',
                    destacarBooleano: true,
                  ),
                ]),

                // Info personal
                _buildFichaDatos("INFORMACIÓN PERSONAL", [
                  _buildFilaInfo("Nombre Completo", personal['nombre']),
                  _buildFilaInfo(
                    "Documento (DNI/NIE/Pasaporte)",
                    personal['documento'],
                  ),
                  _buildFilaInfo("Teléfono", personal['tel']),
                  _buildFilaInfo("Email", personal['email']),
                  _buildFilaInfo("Municipio / Ciudad", personal['ciudad']),
                ]),

                // Perfil y motivación
                _buildFichaDatos("PERFIL Y MOTIVACIÓN", [
                  _buildFilaInfo(
                    "Motivación principal",
                    perfil['motivacion'],
                    esBloqueTexto: true,
                  ),
                  _buildFilaInfo(
                    "Experiencia",
                    perfil['experiencia'],
                    esBloqueTexto: true,
                  ),
                  _buildFilaInfo(
                    "Habilidades destacadas",
                    perfil['habilidades'],
                    esBloqueTexto: true,
                  ),
                ]),

                // Idiomas que han sido declarados por el voluntario/a
                if (idiomas.isNotEmpty) ...[
                  _buildTituloSeccion("IDIOMAS DECLARADOS"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues()),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: idiomas.map((i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.translate_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (i['nombre'] ?? 'Idioma')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Lectura [${i['lectura']}]   •   Escucha [${i['escucha']}]   •   Habla [${i['habla']}]",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Salud y logística
                _buildFichaDatos("SALUD Y LOGÍSTICA", [
                  _buildFilaInfo(
                    "Contacto de Emergencia",
                    logistica['contacto_emergencia'],
                  ),
                  _buildFilaInfo(
                    "Información Médica relevante",
                    logistica['info_medica'],
                    esBloqueTexto: true,
                  ),
                  _buildFilaInfo("Talla de Camiseta", logistica['talla']),
                ]),

                // Estado de la inscrpción
                _buildFichaDatos("ESTADO DE LA INSCRIPCIÓN", [
                  _buildFilaInfo(
                    "Estado Actual",
                    estadoActual.toUpperCase(),
                    resaltarEstado: true,
                  ),
                  _buildFilaInfo("Fecha de registro", () {
                    if (inscripcionData['fecha_registro'] == null) return 'N/A';

                    DateTime fecha = inscripcionData['fecha_registro'].toDate();

                    String dia = fecha.day.toString().padLeft(2, '0');
                    String mes = fecha.month.toString().padLeft(2, '0');
                    String anio = fecha.year.toString();
                    String hora = fecha.hour.toString().padLeft(2, '0');
                    String minuto = fecha.minute.toString().padLeft(2, '0');

                    return "$dia-$mes-$anio $hora:$minuto";
                  }()),
                ]),
              ],
            ),
          ),

          // Botones RECHAZAR y ACEPTAR
          // estos está abajo, fijos (zócalo)
          if (estadoActual == 'pendiente')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(color: Colors.white),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _actualizarEstadoMultiple(context, "Rechazado"),
                        child: const Text(
                          "RECHAZAR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _actualizarEstadoMultiple(context, "Aceptado"),
                        child: const Text(
                          "ACEPTAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Componentes auxiliares
  Widget _buildTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        titulo,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFichaDatos(String tituloSeccion, List<Widget> filas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloSeccion(tituloSeccion),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filas,
          ),
        ),
      ],
    );
  }

  Widget _buildFilaInfo(
    String clave,
    dynamic valor, {
    bool esBloqueTexto = false,
    bool destacarBooleano = false,
    bool resaltarEstado = true,
  }) {
    final String stringValor = (valor ?? 'No especificado').toString();

    if (esBloqueTexto) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clave,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stringValor.isNotEmpty ? stringValor : 'No especificado',
              softWrap: true,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              clave,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 3,
            child: DefaultTextStyle(
              style: const TextStyle(height: 1.2),
              softWrap: true,
              overflow: TextOverflow.visible,
              child: _construirValorEstilizado(
                stringValor,
                destacarBooleano,
                resaltarEstado,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirValorEstilizado(
    String valor,
    bool destacarBooleano,
    bool resaltarEstado,
  ) {
    if (destacarBooleano) {
      bool esSi = valor.toUpperCase() == 'SÍ';
      return Text(
        valor,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: esSi ? Colors.green : Colors.redAccent,
        ),
      );
    }

    if (resaltarEstado &&
        (valor == 'PENDIENTE' || valor == 'ACEPTADO' || valor == 'RECHAZADO')) {
      Color colorState = Colors.orange;
      if (valor == 'ACEPTADO') colorState = Colors.green;
      if (valor == 'RECHAZADO') colorState = Colors.redAccent;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Text(
          valor,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colorState,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return Text(
      valor,
      textAlign: TextAlign.end,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
