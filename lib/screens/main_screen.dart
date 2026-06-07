import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'voluntario/home_voluntario.dart';
import 'voluntario/mapa_screen.dart';
import 'voluntario/detalle_voluntariado.dart';
import 'organizacion/mis_publicaciones.dart';
import 'organizacion/formulario_publicar.dart';
import 'perfil/perfil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _manejarNavegacionLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _manejarNavegacionLink(uri);
    });
  }

  Future<void> _manejarNavegacionLink(Uri uri) async {
    if (uri.scheme == 'nexo' && uri.host == 'voluntariado') {
      final String? id = uri.queryParameters['id'];
      if (id != null && mounted) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('voluntariados')
              .doc(id)
              .get();

          if (doc.exists && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleVoluntariado(
                  data: doc.data() as Map<String, dynamic>,
                  idPublicacion: id,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error al abrir link: $e");
        }
      }
    }
  }

  Future<Map<String, dynamic>> _obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'rol': 'Voluntario', 'estaVerificado': false};

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    return {
      'rol': doc.data()?['rol'] ?? 'Voluntario',
      'estaVerificado': doc.data()?['estaVerificado'] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _obtenerDatosUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final datos =
            snapshot.data ?? {'rol': 'Voluntario', 'estaVerificado': false};
        final bool esOrg = datos['rol'] == 'Organización';
        final bool estaVerificado = datos['estaVerificado'] == true;

        final List<Widget> paginas = esOrg
            ? [
                const MisPublicacionesScreen(),
                const FormularioPublicarScreen(),
                const PerfilScreen(),
              ]
            : [
                const HomeVoluntario(),
                const MapaScreen(),
                const PerfilScreen(),
              ];

        return Scaffold(
          body: paginas[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (esOrg && index == 1 && !estaVerificado) {
                // Alerta/ventana emergente para avisar que la cuenta está en revisión
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Perfil en Revisión"),
                    content: const Text(
                      "Tu cuenta está siendo evaluada por nuestro equipo técnico. "
                      "Podrás publicar voluntariados en cuanto verifiquemos tu identidad.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CERRAR"),
                      ),
                    ],
                  ),
                );
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            items: esOrg ? _itemsOrg() : _itemsVoluntario(),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _itemsOrg() => const [
    BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Publicaciones'),
    BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Publicar'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
  ];

  List<BottomNavigationBarItem> _itemsVoluntario() => const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Casa'),
    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
  ];
}
