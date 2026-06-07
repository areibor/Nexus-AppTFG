import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_voluntariado.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // Controlador para poder manipular la cámara del mapa
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedData;
  String? _selectedId;

  // Posición inicial por defecto (Valencia, España)
  // para cuando el usuario no acepta al dispositivo que coja/use su ubicación
  final LatLng _initialPos = const LatLng(39.4697, -0.3773);

  @override
  void initState() {
    super.initState();
    _determinarPosicion(); // Pedir los permisos de ubicación y centrar en el usuario
    _cargarMarcadores(); // Traer puntos desde Firebase
  }

  /// Función que solicita permisos de GPS y mueve la cámara a la ubicación del usuario
  Future<void> _determinarPosicion() async {
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

    Position position = await Geolocator.getCurrentPosition();
    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    // Mueve la cámara a la posición del voluntario
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14.0));
  }

  /// Función para obtener los voluntariados de Firestore y crear los marcadores
  Future<void> _cargarMarcadores() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('voluntariados')
          .get();

      final Set<Marker> nuevosMarcadores = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final double lat = (data['latitud'] ?? 0.0).toDouble();
        final double lng = (data['longitud'] ?? 0.0).toDouble();

        if (lat != 0.0 && lng != 0.0) {
          nuevosMarcadores.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              onTap: () {
                setState(() {
                  _selectedData = data;
                  _selectedId = doc.id;
                });
              },
            ),
          );
        }
      }

      setState(() {
        _markers.clear();
        _markers.addAll(nuevosMarcadores);
      });
    } catch (e) {
      debugPrint("Error cargando marcadores: $e");
    }
  }

  void _navegarADetalle(Map<String, dynamic> data, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetalleVoluntariado(data: data, idPublicacion: id),
      ),
    );
  }

  /// Widget que aparece en la parte inferior al seleccionar un marcador
  Widget _panelInferior(Map<String, dynamic> data, String id) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['titulo'] ?? 'Voluntariado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedData = null),
              ),
            ],
          ),
          Text(
            "${data['organizacion_nombre'] ?? 'Organización'} • ${data['tipo_voluntariado'] ?? ''}",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 0),
              ),
              onPressed: () => _navegarADetalle(data, id),
              child: const Text(
                "+ info",
                style: TextStyle(
                  color: Color.fromARGB(255, 17, 71, 188),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _initialPos,
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (_) => setState(() => _selectedData = null),
          ),

          if (_selectedData != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _panelInferior(_selectedData!, _selectedId!),
            ),
        ],
      ),
    );
  }
}
