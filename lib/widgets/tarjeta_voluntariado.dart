import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/voluntario/detalle_voluntariado.dart';

class TarjetaVoluntariado extends StatelessWidget {
  final Map<String, dynamic> data;
  final String idPublicacion;

  const TarjetaVoluntariado({
    super.key,
    required this.data,
    required this.idPublicacion,
  });

  // Color Nexus
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  String _obtenerFechaRelativa(Timestamp? timestamp) {
    if (timestamp == null) return "Reciente";

    DateTime fecha = timestamp.toDate();
    DateTime ahora = DateTime.now();
    Duration diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) return "Hoy";
    if (diferencia.inDays == 1) return "Ayer";
    if (diferencia.inDays < 7) return "Hace ${diferencia.inDays} días";

    int semanas = (diferencia.inDays / 7).floor();
    if (semanas < 4) {
      return semanas == 1 ? "Hace 1 semana" : "Hace $semanas semanas";
    }

    int meses = (diferencia.inDays / 30).floor();
    if (meses < 12) {
      return meses <= 1 ? "Hace 1 mes" : "Hace $meses meses";
    }

    int anios = (diferencia.inDays / 365).floor();
    return anios <= 1 ? "Hace 1 año" : "Hace $anios años";
  }

  void _toggleGuardado(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('guardados')
        .doc(idPublicacion);

    try {
      final doc = await docRef.get();
      if (!context.mounted) return;

      if (doc.exists) {
        await docRef.delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Eliminado de guardados"),
            backgroundColor: Colors.black87,
          ),
        );
      } else {
        Map<String, dynamic> dataLimpia = Map<String, dynamic>.from(data);
        await docRef.set({
          'id_publicacion': idPublicacion,
          'fecha_guardado': FieldValue.serverTimestamp(),
          'data': dataLimpia,
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Guardado correctamente"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error toggle guardado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String tipoVoluntariado = data['tipo_voluntariado'] ?? 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalleVoluntariado(data: data, idPublicacion: idPublicacion),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parte superior --> foto perfil (pfp) de la entidad, título y nombre de la entidad
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(data['organizacion_uid']?.toString())
                        .get(),
                    builder: (context, snapshot) {
                      String? urlImagen;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        urlImagen = userData['foto_perfil'];
                      }
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          border: Border.all(
                            color: Colors.grey.withValues(),
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: (urlImagen != null && urlImagen.isNotEmpty)
                              ? Image.network(
                                  urlImagen,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.corporate_fare_rounded,
                                        color: Colors.grey[450],
                                        size: 22,
                                      ),
                                )
                              : Icon(
                                  Icons.corporate_fare_rounded,
                                  color: Colors.grey[400],
                                  size: 22,
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['titulo'] ?? 'Sin título',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data['organizacion_nombre'] ?? 'Organización',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 14),

              // Parte media --> la ubicación formateada, es decir, barrio/municipio + Valencia (ej. Ruzafa, Valencia o Alfafar, Valencia)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['ubicacion_formateada'] ?? 'Valencia',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Parte inferior --> etiqueta del tipo de voluntariado (a la izq) y tiempo relativo + icono/función de guardados (a la dcha)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(125, 85, 133, 238),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tipoVoluntariado,
                      style: TextStyle(
                        color: _colorCorporativo,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _obtenerFechaRelativa(
                          data['fecha_creacion'] as Timestamp?,
                        ),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 14, color: Colors.black12),
                      const SizedBox(width: 2),
                      _buildBotonGuardar(uid),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonGuardar(String? uid) {
    if (uid == null) {
      return const Icon(
        Icons.bookmark_border_rounded,
        color: Colors.black26,
        size: 20,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('guardados')
          .doc(idPublicacion)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Icon(
            Icons.bookmark_border_rounded,
            color: Colors.black26,
            size: 20,
          );
        }

        bool estaGuardado = snapshot.hasData && snapshot.data!.exists;

        return IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          splashRadius: 18,
          icon: Icon(
            estaGuardado
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: estaGuardado ? _colorCorporativo : Colors.black26,
            size: 20,
          ),
          onPressed: () => _toggleGuardado(context),
        );
      },
    );
  }
}
