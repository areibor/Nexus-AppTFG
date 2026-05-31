import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  bool esModoEdicion = false;
  final user = FirebaseAuth.instance.currentUser;
  String? _rol;

  // Controladores
  final _telController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _fechaController = TextEditingController();
  String _genero = "Prefiero no decirlo";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _rol = data['rol'];

      setState(() {
        String nombreCompleto = data['nombre'] ?? '';

        if (_rol == 'Voluntario') {
          int primerEspacio = nombreCompleto.indexOf(' ');
          if (primerEspacio != -1) {
            _nombreController.text = nombreCompleto.substring(0, primerEspacio);
            _apellidosController.text = nombreCompleto.substring(
              primerEspacio + 1,
            );
          } else {
            _nombreController.text = nombreCompleto;
            _apellidosController.text = '';
          }
        } else {
          _nombreController.text = nombreCompleto;
        }

        _telController.text = data['telefono'] ?? '';
        _fechaController.text = data['fecha_nacimiento'] ?? '';
        _genero = data['genero'] ?? "Prefiero no decirlo";
      });
    }
  }

  void _guardarCambios() async {
    String nombreAGuardar = _nombreController.text.trim();
    if (_rol == 'Voluntario' && _apellidosController.text.isNotEmpty) {
      nombreAGuardar =
          "${_nombreController.text.trim()} ${_apellidosController.text.trim()}";
    }

    Map<String, dynamic> datosActualizados = {
      'nombre': nombreAGuardar,
      'telefono': _telController.text.trim(),
    };

    if (_rol == 'Voluntario') {
      datosActualizados['fecha_nacimiento'] = _fechaController.text.trim();
      datosActualizados['genero'] = _genero;
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .update(datosActualizados);

    if (!mounted) return;

    setState(() => esModoEdicion = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Perfil actualizado correctamente"),
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esOrganizacion = _rol == 'Organización';

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo premium consistente con tu app
      appBar: AppBar(
        title: const Text(
          "Editar Perfil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // 🌟 BOTÓN DE ACCIÓN REESTILIZADO (Más visible y moderno)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (esModoEdicion) {
                  _guardarCambios();
                } else {
                  setState(() => esModoEdicion = true);
                }
              },
              child: Text(
                esModoEdicion ? "GUARDAR" : "EDITAR",
                style: TextStyle(
                  color: esModoEdicion ? Colors.green : Colors.black45,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BLOQUE 1: DETALLES DE LA CUENTA ---
            _buildSubtituloSeccion("DETALLES DE LA CUENTA"),
            _buildCardContenedor([
              _buildCampo(
                label: "Email de la cuenta",
                controller: TextEditingController(text: user?.email),
                icono: Icons.email_outlined,
                habilitado:
                    false, // Siempre deshabilitado, estéticamente limpio
              ),
              _buildCampo(
                label: "Teléfono de contacto",
                controller: _telController,
                icono: Icons.phone_outlined,
                habilitado: esModoEdicion,
                keyboardType: TextInputType.phone,
              ),
            ]),

            const SizedBox(height: 20),

            // --- BLOQUE 2: DATOS ESPECÍFICOS SEGÚN ROL ---
            _buildSubtituloSeccion(
              esOrganizacion ? "INFORMACIÓN DE LA ENTIDAD" : "DATOS PERSONALES",
            ),
            _buildCardContenedor([
              _buildCampo(
                label: esOrganizacion
                    ? "Nombre de la Organización / Particular"
                    : "Nombre",
                controller: _nombreController,
                icono: esOrganizacion
                    ? Icons.corporate_fare_rounded
                    : Icons.person_outline_rounded,
                habilitado: esModoEdicion,
                textCapitalization: TextCapitalization.words,
              ),
              if (!esOrganizacion) ...[
                _buildCampo(
                  label: "Apellidos",
                  controller: _apellidosController,
                  icono: Icons.people_outline_rounded,
                  habilitado: esModoEdicion,
                  textCapitalization: TextCapitalization.words,
                ),
                _buildCampo(
                  label: "Fecha de Nacimiento",
                  controller: _fechaController,
                  icono: Icons.cake_outlined,
                  habilitado: esModoEdicion,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_FechaInputFormatter()],
                  hintText: "DD/MM/AAAA",
                ),

                // 🌟 DROPDOWN GÉNERO REESTILIZADO DENTRO DE LA TARJETA
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _genero,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Género",
                      labelStyle: TextStyle(
                        color: esModoEdicion ? Colors.grey : Colors.black54,
                      ),
                      prefixIcon: Icon(
                        Icons.wc_rounded,
                        color: esModoEdicion ? Colors.black38 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: esModoEdicion ? Colors.white : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                      ),
                    ),
                    items: ["Hombre", "Mujer", "Otro", "Prefiero no decirlo"]
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: esModoEdicion
                        ? (val) => setState(() => _genero = val!)
                        : null,
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DE DISEÑO ---

  Widget _buildSubtituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

  Widget _buildCardContenedor(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues()),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildCampo({
    required String label,
    required TextEditingController controller,
    required IconData icono,
    bool habilitado = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: habilitado,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: habilitado ? Colors.black87 : Colors.black38,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: habilitado ? Colors.black45 : Colors.black45,
          ),
          prefixIcon: Icon(
            icono,
            color: habilitado ? Colors.black45 : Colors.black26,
            size: 22,
          ),
          filled: true,
          // Cambiamos el color gris tosco por un blanco o gris muy sutil premium
          fillColor: habilitado ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          // Estilo de bordes redondeados modernos suavizados
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color.fromARGB(94, 0, 0, 0).withValues(),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _FechaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    if (n.text.length < o.text.length) return n;

    var t = n.text.replaceAll('/', '');
    var b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      b.write(t[i]);
      if ((i == 1 || i == 3) && i != t.length - 1) b.write('/');
    }
    return n.copyWith(
      text: b.toString(),
      selection: TextSelection.collapsed(offset: b.length),
    );
  }
}
