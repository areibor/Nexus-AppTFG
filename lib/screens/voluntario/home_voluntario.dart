import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/tarjeta_voluntariado.dart';
import 'filtros.dart';

class HomeVoluntario extends StatefulWidget {
  const HomeVoluntario({super.key});

  @override
  State<HomeVoluntario> createState() => _HomeVoluntarioState();
}

class _HomeVoluntarioState extends State<HomeVoluntario> {
  final TextEditingController _searchController = TextEditingController();
  String _textoBusqueda = "";
  List<String> _tiposSeleccionados = [];
  Position? _posicionUsuario;
  String _orden = "reciente";
  double _distanciaMax = 100.0;

  final List<String> _todosLosTipos = [
    'Social',
    'Ambiental',
    'Protección Civil',
    'Sociosanitario',
    'Educativo y Cultural',
    'Deportivo',
  ];

  // Color Nexus
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _textoBusqueda = _searchController.text.toLowerCase();
        });
      }
    });
  }

  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }

    if (permiso == LocationPermission.deniedForever) return;

    _posicionUsuario = await Geolocator.getCurrentPosition();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Voluntariados cerca de ti",
                    style: TextStyle(color: Colors.grey[900], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Barra de búsqueda + filtrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "Buscar por título, entidad...",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _mostrarFiltros(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color:
                            _tiposSeleccionados.isNotEmpty ||
                                _orden != "reciente" ||
                                _distanciaMax < 100
                            ? _colorCorporativo
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _tiposSeleccionados.isNotEmpty ||
                                  _orden != "reciente" ||
                                  _distanciaMax < 100
                              ? Colors.transparent
                              : Colors.black12,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color:
                            _tiposSeleccionados.isNotEmpty ||
                                _orden != "reciente" ||
                                _distanciaMax < 100
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chips de filtros activo
            if (_tiposSeleccionados.isNotEmpty ||
                _orden != "reciente" ||
                _distanciaMax < 100)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Botón de Limpieza General
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.white,
                        ),
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
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _tiposSeleccionados.clear();
                              _orden = "reciente";
                              _distanciaMax = 100.0;
                            });
                          }
                        },
                      ),
                    ),

                    if (_orden != "reciente")
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          label: Text(
                            _orden == "antiguo"
                                ? "Más antiguos"
                                : "Más recientes",
                          ),
                          labelStyle: TextStyle(
                            color: _colorCorporativo,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: _colorCorporativo.withValues(),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onDeleted: () => setState(() => _orden = "reciente"),
                          deleteIconColor: _colorCorporativo,
                        ),
                      ),

                    if (_distanciaMax < 100)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          avatar: Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: _colorCorporativo,
                          ),
                          label: Text("< ${_distanciaMax.toInt()} km"),
                          labelStyle: TextStyle(
                            color: _colorCorporativo,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: _colorCorporativo.withValues(),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onDeleted: () =>
                              setState(() => _distanciaMax = 100.0),
                          deleteIconColor: _colorCorporativo,
                        ),
                      ),

                    ..._tiposSeleccionados.map(
                      (tipo) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          label: Text(tipo),
                          labelStyle: TextStyle(
                            color: _colorCorporativo,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: _colorCorporativo.withValues(),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onDeleted: () =>
                              setState(() => _tiposSeleccionados.remove(tipo)),
                          deleteIconColor: _colorCorporativo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('voluntariados')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    bool estaValidado = data['organizacionVerificada'] == true;
                    if (!estaValidado) return false;

                    String titulo = (data['titulo'] ?? "")
                        .toString()
                        .toLowerCase();
                    String barrio = (data['barrio_pueblo'] ?? "")
                        .toString()
                        .toLowerCase();
                    String direccion = (data['direccion_exacta'] ?? "")
                        .toString()
                        .toLowerCase();
                    String tipo = (data['tipo_voluntariado'] ?? "")
                        .toString()
                        .toLowerCase();
                    String nombreOrg = (data['organizacion_nombre'] ?? "")
                        .toString()
                        .toLowerCase();
                    String infoCompleta =
                        "$titulo $nombreOrg $barrio $direccion $tipo";

                    bool coincideBusqueda = infoCompleta.contains(
                      _textoBusqueda,
                    );
                    String tipoOriginal = data['tipo_voluntariado'] ?? "";
                    bool coincideTipo =
                        _tiposSeleccionados.isEmpty ||
                        _tiposSeleccionados.contains(tipoOriginal);

                    bool coincideDistancia = true;
                    if (_distanciaMax < 100.0) {
                      if (_posicionUsuario != null &&
                          data['latitud'] != null &&
                          data['longitud'] != null) {
                        double distanciaEnMetros = Geolocator.distanceBetween(
                          _posicionUsuario!.latitude,
                          _posicionUsuario!.longitude,
                          data['latitud'],
                          data['longitud'],
                        );
                        double distanciaEnKm = distanciaEnMetros / 1000;
                        coincideDistancia = distanciaEnKm <= _distanciaMax;
                      }
                    }

                    return coincideBusqueda &&
                        coincideTipo &&
                        coincideDistancia;
                  }).toList();

                  if (_orden == "reciente") {
                    docs.sort((a, b) {
                      Timestamp tA =
                          (a.data()
                              as Map<String, dynamic>)['fecha_creacion'] ??
                          Timestamp.now();
                      Timestamp tB =
                          (b.data()
                              as Map<String, dynamic>)['fecha_creacion'] ??
                          Timestamp.now();
                      return tB.compareTo(tA);
                    });
                  } else {
                    docs.sort((a, b) {
                      Timestamp tA =
                          (a.data()
                              as Map<String, dynamic>)['fecha_creacion'] ??
                          Timestamp.now();
                      Timestamp tB =
                          (b.data()
                              as Map<String, dynamic>)['fecha_creacion'] ??
                          Timestamp.now();
                      return tA.compareTo(tB);
                    });
                  }

                  if (docs.isEmpty) {
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
                            "No se encontraron resultados",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String idReal = doc.id;
                      return TarjetaVoluntariado(
                        data: data,
                        idPublicacion: idReal,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) async {
    final Map<String, dynamic>? resultado = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ModalFiltros(
        tiposSeleccionados: _tiposSeleccionados,
        todosLosTipos: _todosLosTipos,
        orden: _orden,
        distanciaMax: _distanciaMax,
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _tiposSeleccionados = resultado['tipos'];
        _orden = resultado['orden'];
        _distanciaMax = resultado['distancia'];
      });
    }
  }
}
