import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class FormularioInscripcionScreen extends StatefulWidget {
  final Map<String, dynamic> dataVoluntariado;
  final List<Map<String, dynamic>> turnosSeleccionados;
  final String idPublicacion;

  const FormularioInscripcionScreen({
    super.key,
    required this.dataVoluntariado,
    required this.turnosSeleccionados,
    required this.idPublicacion,
  });

  @override
  State<FormularioInscripcionScreen> createState() =>
      _FormularioInscripcionScreenState();
}

class _FormularioInscripcionScreenState
    extends State<FormularioInscripcionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _mostrarErrores = false;

  // I. Información Personal
  final _nombreController = TextEditingController();
  String _tipoId = 'DNI';
  final _idController = TextEditingController();
  final _fechaNacController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _ciudadController = TextEditingController();

  // II. Participación
  String? _disponibilidad;
  String? _transporte;
  String? _compromiso;

  // III. Perfil
  final _motivacionController = TextEditingController();
  final _experienciaController = TextEditingController();
  final _habilidadesController = TextEditingController();

  final List<Map<String, dynamic>> _idiomasSeleccionados = [];

  // IV. Logística
  final _nombreEmergenciaController = TextEditingController();
  final _telEmergenciaController = TextEditingController();
  final _medicoController = TextEditingController();
  String? _tallaPrenda;

  // V. Autorizaciones
  bool _aceptaPrivacidad = false;
  bool _aceptaImagen = false;
  bool _certificadoDelitos = false;
  bool _declaracionVeracidad = false;

  // Color corporativo unificado de tu app
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  Future<void> _cargarDatosPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _telController.text = data['telefono'] ?? '';
          _fechaNacController.text = data['fecha_nacimiento'] ?? '';
          _ciudadController.text = data['ciudad'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _idController.dispose();
    _fechaNacController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
    _motivacionController.dispose();
    _experienciaController.dispose();
    _habilidadesController.dispose();
    _nombreEmergenciaController.dispose();
    _telEmergenciaController.dispose();
    _medicoController.dispose();
    for (var idioma in _idiomasSeleccionados) {
      idioma['controller'].dispose();
    }
    super.dispose();
  }

  Future<void> _enviarInscripcion() async {
    setState(() {
      _mostrarErrores = true;
    });

    if (!_formKey.currentState!.validate() ||
        !_aceptaPrivacidad ||
        !_declaracionVeracidad ||
        _disponibilidad == null ||
        _transporte == null ||
        _compromiso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, rellena todos los campos obligatorios y acepta los términos.",
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final batch = FirebaseFirestore.instance.batch();

      for (var turno in widget.turnosSeleccionados) {
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('inscripciones')
            .doc();
        batch.set(docRef, {
          'voluntario_uid': uid,
          'voluntariado_titulo': widget.dataVoluntariado['titulo'],
          'organizacion_uid': widget.dataVoluntariado['organizacion_uid'],
          'id_publicacion': widget.idPublicacion,
          'turno': turno,
          'personal': {
            'nombre': _nombreController.text.trim(),
            'documento': "$_tipoId: ${_idController.text.trim()}",
            'fecha_nac': _fechaNacController.text.trim(),
            'tel': _telController.text.trim(),
            'email': _emailController.text.trim(),
            'ciudad': _ciudadController.text.trim(),
          },
          'perfil': {
            'motivacion': _motivacionController.text.trim(),
            'experiencia': _experienciaController.text.trim(),
            'habilidades': _habilidadesController.text.trim(),
            'idiomas': _idiomasSeleccionados
                .map(
                  (i) => {
                    'nombre': i['controller'].text.trim(),
                    'lectura': i['lectura'],
                    'escucha': i['escucha'],
                    'habla': i['habla'],
                  },
                )
                .toList(),
          },
          'salud_logistica': {
            'contacto_emergencia':
                "${_nombreEmergenciaController.text.trim()} (${_telEmergenciaController.text.trim()})",
            'info_medica': _medicoController.text.trim(),
            'talla': _tallaPrenda,
            'disponibilidad_total': _disponibilidad,
            'transporte_propio': _transporte,
            'compromiso_asistencia': _compromiso,
            'autorizacion_imagen': _aceptaImagen,
            'certificado_delitos': _certificadoDelitos,
          },
          'fecha_registro': FieldValue.serverTimestamp(),
          'estado': 'pendiente',
        });
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context); // Cierra indicador de carga
      Navigator.pop(context); // Regresa a la vista anterior

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Inscripción completada con éxito!"),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo premium consistente
      appBar: AppBar(
        title: const Text(
          "Formulario de Inscripción",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  "* Campos obligatorios",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // I. INFORMACIÓN PERSONAL
              _buildSubtituloSeccion("INFORMACIÓN PERSONAL"),
              _buildCardContenedor([
                _buildTextField(
                  _nombreController,
                  "Nombre y Apellidos*",
                  Icons.person_outline_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 115,
                        height: 48,
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipoId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                          ),
                          items: ['DNI', 'NIE', 'Pasaporte']
                              .map(
                                (id) => DropdownMenuItem(
                                  value: id,
                                  child: Text(
                                    id,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _tipoId = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: _buildTextField(
                            _idController,
                            "Número*",
                            Icons.badge_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTextField(
                  _fechaNacController,
                  "Fecha de nacimiento*",
                  Icons.cake_outlined,
                  keyboard: TextInputType.number,
                  formatters: [_FechaInputFormatter()],
                  hintText: "DD/MM/AAAA",
                ),
                _buildTextField(
                  _telController,
                  "Teléfono*",
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                _buildTextField(
                  _emailController,
                  "Email*",
                  Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                _buildTextField(
                  _ciudadController,
                  "Municipio o Barrio*",
                  Icons.location_city_outlined,
                ),
              ]),

              const SizedBox(height: 24),

              // II. REQUISITOS DE PARTICIPACIÓN
              _buildSubtituloSeccion("PARTICIPACIÓN"),
              _buildCardContenedor([
                _buildRadioPregunta(
                  "¿Disponibilidad para los turnos elegidos?*",
                  ["Total", "Parcial"],
                  _disponibilidad,
                  (v) => setState(() => _disponibilidad = v),
                ),
                const Divider(height: 24),
                _buildRadioPregunta(
                  "¿Dispone de vehículo propio?*",
                  ["Sí", "No"],
                  _transporte,
                  (v) => setState(() => _transporte = v),
                ),
                const Divider(height: 24),
                _buildRadioPregunta(
                  "¿Se compromete a asistir con puntualidad?*",
                  ["Sí", "No"],
                  _compromiso,
                  (v) => setState(() => _compromiso = v),
                ),
              ]),

              const SizedBox(height: 24),

              // III. PERFIL DEL VOLUNTARIO
              _buildSubtituloSeccion("PERFIL DEL VOLUNTARIO"),
              _buildCardContenedor([
                _buildTextField(
                  _motivacionController,
                  "Motivación*",
                  Icons.chat_bubble_outline_rounded,
                  multiline: true,
                ),
                _buildTextField(
                  _experienciaController,
                  "Experiencia*",
                  Icons.history_edu_rounded,
                  multiline: true,
                ),
                _buildTextField(
                  _habilidadesController,
                  "Habilidades*",
                  Icons.star_border_rounded,
                  multiline: true,
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 18,
                          color: _colorCorporativo,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Idiomas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color.fromARGB(255, 17, 71, 188),
                          ),
                        ),
                      ],
                    ),
                    _buildBotonAnadirIdioma(),
                  ],
                ),
                ..._idiomasSeleccionados.asMap().entries.map(
                  (e) => _buildCardIdioma(e.key),
                ),
              ]),

              const SizedBox(height: 24),

              // IV. LOGÍSTICA Y SALUD
              _buildSubtituloSeccion("LOGÍSTICA Y SALUD"),
              _buildCardContenedor([
                _buildTextField(
                  _nombreEmergenciaController,
                  "Nombre de contacto de emergencia*",
                  Icons.contact_emergency_outlined,
                ),
                _buildTextField(
                  _telEmergenciaController,
                  "Teléfono de emergencia*",
                  Icons.phone_android_rounded,
                  keyboard: TextInputType.phone,
                ),
                _buildTextField(
                  _medicoController,
                  "Alergias o datos médicos relevantes*",
                  Icons.medical_information_outlined,
                  multiline: true,
                ),
                _buildDropdownTalla(),
              ]),

              const SizedBox(height: 24),

              // V. AUTORIZACIONES Y DECLARACIONES
              _buildSubtituloSeccion("AUTORIZACIONES Y PRIVACIDAD"),
              _buildCardContenedor([
                _buildCheckbox(
                  "He leído y acepto la Política de protección de datos*",
                  _aceptaPrivacidad,
                  (v) => setState(() => _aceptaPrivacidad = v!),
                ),
                _buildCheckbox(
                  "Autorizo la cesión de derechos de imagen para la difusión de la actividad",
                  _aceptaImagen,
                  (v) => setState(() => _aceptaImagen = v!),
                ),
                _buildCheckbox(
                  "Dispongo del Certificado de Delitos Sexuales en vigor",
                  _certificadoDelitos,
                  (v) => setState(() => _certificadoDelitos = v!),
                ),
                _buildCheckbox(
                  "Declaro bajo firma la veracidad de los datos introducidos*",
                  _declaracionVeracidad,
                  (v) => setState(() => _declaracionVeracidad = v!),
                ),
              ]),

              const SizedBox(height: 32),

              // BOTÓN PRINCIPAL DE ENVÍO
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _colorCorporativo,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _enviarInscripcion,
                child: const Text(
                  "ENVIAR INSCRIPCIÓN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS COMPONENTES REDISEÑADOS ---

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController c,
    String label,
    IconData icono, {
    bool multiline = false,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: c,
        maxLines: multiline ? null : 1,
        keyboardType: multiline ? TextInputType.multiline : keyboard,
        inputFormatters: formatters,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          // Forzamos un hintText y reducimos el tamaño tipográfico general para que todo quepa de sobra
          labelText: label,
          hintText: hintText ?? label,
          labelStyle: TextStyle(color: _colorCorporativo, fontSize: 13),
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          prefixIcon: Icon(icono, color: _colorCorporativo, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
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
            borderSide: BorderSide(color: _colorCorporativo, width: 1.5),
          ),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? "Este campo es obligatorio" : null,
      ),
    );
  }

  Widget _buildRadioPregunta(
    String p,
    List<String> opciones,
    String? currentGroupValue,
    Function(String?) onChanged,
  ) {
    bool tieneError = _mostrarErrores && currentGroupValue == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
            border: Border.all(
              color: tieneError ? Colors.redAccent : Colors.grey.withValues(),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _colorCorporativo;
                  }
                  return Colors.black45;
                }),
              ),
            ),
            child: RadioGroup<String>(
              groupValue: currentGroupValue,
              onChanged: onChanged,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: opciones.map((opt) {
                  return Expanded(
                    child: RadioListTile<String>(
                      title: Text(opt, style: const TextStyle(fontSize: 14)),
                      value: opt,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (tieneError)
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Debes seleccionar una respuesta",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckbox(String texto, bool value, Function(bool?) onChanged) =>
      Theme(
        data: ThemeData(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: _colorCorporativo,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      );

  Widget _buildDropdownTalla() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: DropdownButtonFormField<String>(
      initialValue: _tallaPrenda,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ), // 🌟 Forzar letra interna pequeña
      decoration: InputDecoration(
        labelText: "Talla de equipación / prenda",
        labelStyle: TextStyle(
          color: _colorCorporativo,
          fontSize: 13,
        ), // 🌟 Letra pequeña en el título
        prefixIcon: Icon(
          Icons.checkroom_rounded,
          color: _colorCorporativo,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ), // 🌟 Relleno premium unificado
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
          borderSide: BorderSide(color: _colorCorporativo, width: 1.5),
        ),
      ),
      items: ["S", "M", "L", "XL"]
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, style: const TextStyle(fontSize: 14)),
            ),
          ) // 🌟 Ítems pequeños
          .toList(),
      onChanged: (v) => setState(() => _tallaPrenda = v),
    ),
  );

  Widget _buildCardIdioma(int index) {
    return Container(
      key: ValueKey(_idiomasSeleccionados[index]),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorCorporativo),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idiomasSeleccionados[index]['controller'],
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Escribe el idioma...",
                    isDense: true,
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _idiomasSeleccionados[index]['controller'].dispose();
                    _idiomasSeleccionados.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildNivelIdioma(index, "Nivel de Lectura", "lectura"),
          _buildNivelIdioma(index, "Nivel de Escucha", "escucha"),
          _buildNivelIdioma(index, "Nivel de Habla", "habla"),
        ],
      ),
    );
  }

  Widget _buildBotonAnadirIdioma() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _idiomasSeleccionados.add({
            'controller': TextEditingController(),
            'lectura': 'Bajo',
            'escucha': 'Bajo',
            'habla': 'Bajo',
          });
        });
      },
      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
      label: const Text(
        "Añadir",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        foregroundColor: _colorCorporativo,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNivelIdioma(int index, String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          DropdownButton<String>(
            value: _idiomasSeleccionados[index][key],
            underline: const SizedBox(),
            style: TextStyle(
              color: _colorCorporativo,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            icon: Icon(Icons.arrow_drop_down_rounded, color: _colorCorporativo),
            items: [
              'Bajo',
              'Medio',
              'Alto',
              'Nativo',
            ].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (v) =>
                setState(() => _idiomasSeleccionados[index][key] = v!),
          ),
        ],
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
