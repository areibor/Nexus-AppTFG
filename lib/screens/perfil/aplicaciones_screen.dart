import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../voluntario/detalle_voluntariado.dart';
import 'filtros_aplicaciones.dart';

class AplicacionesScreen extends StatefulWidget {
  const AplicacionesScreen({super.key});

  @override
  State<AplicacionesScreen> createState() => _AplicacionesScreenState();
}

class _AplicacionesScreenState extends State<AplicacionesScreen> {
  List<String> _filtrosEstado = [];

  void _abrirFiltros() async {
    final resultado = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FiltrosAplicaciones(estadosSeleccionados: _filtrosEstado),
    );

    if (resultado != null && mounted) {
      setState(() {
        _filtrosEstado = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Mis Inscripciones",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _filtrosEstado.isNotEmpty ? Colors.black : Colors.black,
            ),
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtrosEstado.isNotEmpty) _buildBarraChips(),
          Expanded(
            child: uid == null
                ? const Center(
                    child: Text("Inicia sesión para ver tus aplicaciones"),
                  )
                : _buildStreamInscripciones(uid),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraChips() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: const Icon(Icons.refresh, size: 14, color: Colors.white),
              label: const Text("Limpiar"),
              backgroundColor: Colors.redAccent,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: () => setState(() => _filtrosEstado = []),
            ),
          ),
          ..._filtrosEstado.map((estado) {
            Color colorChip = Colors.orange;
            if (estado == 'aceptado') colorChip = Colors.green;
            if (estado == 'rechazado') colorChip = Colors.red;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text(estado[0].toUpperCase() + estado.substring(1)),
                labelStyle: TextStyle(
                  color: colorChip,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(color: colorChip.withValues(), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                onDeleted: () {
                  setState(() => _filtrosEstado.remove(estado));
                },
                deleteIconColor: colorChip,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStreamInscripciones(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inscripciones')
          .where('voluntario_uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Aún no has aplicado a ningún voluntariado",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          );
        }

        final docsFiltrados = docs.where((doc) {
          if (_filtrosEstado.isEmpty) return true;
          var data = doc.data() as Map<String, dynamic>;
          String estado = (data['estado'] ?? 'pendiente')
              .toString()
              .toLowerCase();
          return _filtrosEstado.contains(estado);
        }).toList();

        Map<String, Map<String, dynamic>> agrupados = {};
        for (var doc in docsFiltrados) {
          var data = doc.data() as Map<String, dynamic>;
          String idPub = data['id_publicacion'] ?? '';
          if (!agrupados.containsKey(idPub)) {
            agrupados[idPub] = data;
          }
        }

        final listaFinal = agrupados.values.toList();

        if (listaFinal.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                const Text(
                  "No hay aplicaciones con estos filtros",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: listaFinal.length,
          itemBuilder: (context, index) {
            var inscripcion = listaFinal[index];
            String idPub = inscripcion['id_publicacion'];
            String estado = inscripcion['estado'] ?? 'pendiente';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('voluntariados')
                  .doc(idPub)
                  .get(),
              builder: (context, volSnap) {
                if (!volSnap.hasData) return const SizedBox.shrink();
                var volData = volSnap.data!.data() as Map<String, dynamic>?;
                if (volData == null) return const SizedBox.shrink();

                return _buildTarjetaInscripcion(
                  context,
                  volData,
                  idPub,
                  estado,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTarjetaInscripcion(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
    String estado,
  ) {
    Color colorEstado = Colors.orange;
    if (estado.toLowerCase() == 'aceptado') colorEstado = Colors.green;
    if (estado.toLowerCase() == 'rechazado') colorEstado = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              builder: (context) => DetalleVoluntariado(
                data: data,
                idPublicacion: id,
                modoVistaInscrito: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          border: Border.all(color: Colors.grey.withValues()),
                        ),
                        child: ClipOval(
                          child: (urlImagen != null && urlImagen.isNotEmpty)
                              ? Image.network(urlImagen, fit: BoxFit.cover)
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['ubicacion_formateada'] ?? 'Valencia',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        color: colorEstado,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
