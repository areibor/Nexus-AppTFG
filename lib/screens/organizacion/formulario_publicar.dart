import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

class FormularioPublicarScreen extends StatefulWidget {
  const FormularioPublicarScreen({super.key});

  @override
  State<FormularioPublicarScreen> createState() =>
      _FormularioPublicarScreenState();
}

class _FormularioPublicarScreenState extends State<FormularioPublicarScreen> {
  // Controladores principales
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _reqController = TextEditingController();
  final _barrioPuebloController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telController = TextEditingController();
  final _emailContactoController = TextEditingController();
  final _webController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();

  // Controladores para la sección de turnos
  final _voluntariosTurnoController = TextEditingController(text: "1");
  String _fechaTexto = "Día";
  String _horaInicioTexto = "Inicio";
  String _horaFinTexto = "Fin";

  DateTime? _fechaRaw;
  TimeOfDay? _horaInicioRaw;
  TimeOfDay? _horaFinRaw;

  final List<Map<String, dynamic>> _turnosAgregados = [];

  String? _tipoSeleccionado;
  final List<String> _tiposVoluntariado = [
    'Social',
    'Ambiental',
    'Protección Civil',
    'Sociosanitario',
    'Educativo y Cultural',
    'Deportivo',
  ];

  // Color corporativo unificado de tu app
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    _prellenarDatosContacto();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    _reqController.dispose();
    _barrioPuebloController.dispose();
    _direccionController.dispose();
    _telController.dispose();
    _emailContactoController.dispose();
    _webController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _voluntariosTurnoController.dispose();
    super.dispose();
  }

  Future<void> _prellenarDatosContacto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailContactoController.text = user.email ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _telController.text = data['telefono'] ?? '';
          if (data['email_contacto'] != null) {
            _emailContactoController.text = data['email_contacto'];
          }
        });
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      cancelText: "CANCELAR",
      confirmText: "ACEPTAR",
      helpText: "SELECCIONA UNA FECHA",
      errorFormatText: "Formato de fecha no válido",
      errorInvalidText: "Fecha fuera de rango",
      fieldLabelText: "Introduce la fecha",
      fieldHintText: "día/mes/año",
    );
    if (fecha != null) {
      setState(() {
        _fechaRaw = fecha;
        _fechaTexto = "${fecha.day}/${fecha.month}/${fecha.year}";
      });
    }
  }

  Future<void> _pickTime(bool esInicio) async {
    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      cancelText: "CANCELAR",
      confirmText: "ACEPTAR",
      helpText: "SELECCIONA UNA HORA",
      errorInvalidText: "Hora no válida",
      hourLabelText: "Hora",
      minuteLabelText: "Minuto",
      builder: (BuildContext context, Widget? child) {
        // Mantenemos tu envoltura forzada al estilo de reloj de 24 horas europeo
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        final horasStr = hora.hour.toString().padLeft(2, '0');
        final minutosStr = hora.minute.toString().padLeft(2, '0');
        final horaFormateada24h = "$horasStr:$minutosStr";

        if (esInicio) {
          _horaInicioRaw = hora;
          _horaInicioTexto = horaFormateada24h;
        } else {
          _horaFinRaw = hora;
          _horaFinTexto = horaFormateada24h;
        }
      });
    }
  }

  void _agregarTurnoALista() {
    if (_fechaRaw == null || _horaInicioRaw == null || _horaFinRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona día, hora de inicio y fin"),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }
    setState(() {
      _turnosAgregados.add({
        'fecha': _fechaTexto,
        'hora': "$_horaInicioTexto - $_horaFinTexto",
        'voluntarios': int.tryParse(_voluntariosTurnoController.text) ?? 1,
        'inscritos_reales': 0, // Inicializador para cupos reales
      });
      _fechaTexto = "Día";
      _horaInicioTexto = "Inicio";
      _horaFinTexto = "Fin";
      _fechaRaw = null;
      _horaInicioRaw = null;
      _horaFinRaw = null;
      _voluntariosTurnoController.text = "1";
    });
  }

  Future<void> _publicar() async {
    String direccion = _direccionController.text.trim();
    double lat = 0.0;
    double lng = 0.0;

    if (_tituloController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _reqController.text.trim().isEmpty ||
        _barrioPuebloController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty ||
        _telController.text.trim().isEmpty ||
        _emailContactoController.text.trim().isEmpty ||
        _tipoSeleccionado == null ||
        _turnosAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Completa los campos obligatorios y añade al menos un turno",
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docUser = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      String nombreOrg = "Organización";
      if (docUser.exists && docUser.data() != null) {
        nombreOrg = docUser.data()!['nombre'] ?? "Organización";
      }

      try {
        List<Location> locations = await locationFromAddress(direccion);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (e) {
        debugPrint("Error obteniendo geolocalización: $e");
      }

      await FirebaseFirestore.instance.collection('voluntariados').add({
        'organizacion_uid': user.uid,
        'organizacion_nombre': nombreOrg,
        'titulo': _tituloController.text.trim(),
        'tipo_voluntariado': _tipoSeleccionado,
        'descripcion': _descController.text.trim(),
        'requisitos': _reqController.text.trim(),
        'barrio_pueblo': _barrioPuebloController.text.trim(),
        'direccion_exacta': _direccionController.text.trim(),
        'latitud': lat,
        'longitud': lng,
        'ubicacion_formateada':
            "${_barrioPuebloController.text.trim()}, Valencia",
        'telefono_contacto': _telController.text.trim(),
        'email_contacto': _emailContactoController.text.trim(),
        'web_contacto': _webController.text.trim(),
        'instagram_user': _instagramController.text.trim(),
        'twitter_user': _twitterController.text.trim(),
        'facebook_user': _facebookController.text.trim(),
        'turnos': _turnosAgregados,
        'fecha_creacion': FieldValue.serverTimestamp(),
        'organizacionVerificada': true,
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Quitar cargando

      _limpiarFormulario();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "¡Publicado con éxito! Revisa la pestaña 'Publicaciones'",
          ),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _limpiarFormulario() {
    _tituloController.clear();
    _descController.clear();
    _reqController.clear();
    _barrioPuebloController.clear();
    _direccionController.clear();
    _telController.clear();
    _emailContactoController.clear();
    _webController.clear();
    _instagramController.clear();
    _twitterController.clear();
    _facebookController.clear();
    _voluntariosTurnoController.text = "1";
    setState(() {
      _turnosAgregados.clear();
      _tipoSeleccionado = null;
      _fechaTexto = "Día";
      _horaInicioTexto = "Inicio";
      _horaFinTexto = "Fin";
      _fechaRaw = null;
      _horaInicioRaw = null;
      _horaFinRaw = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo unificado premium
      appBar: AppBar(
        title: const Text(
          "Nueva Publicación",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
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

            // I. DETALLES DE LA CAUSA
            _buildSubtituloSeccion("DETALLE DEL VOLUNTARIADO"),
            _buildCardContenedor([
              _buildTextField(
                _tituloController,
                "Título*",
                Icons.title_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Tipo de voluntariado*",
                    labelStyle: TextStyle(
                      color: _colorCorporativo,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: _colorCorporativo,
                      size: 20,
                    ),
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
                      borderSide: BorderSide(
                        color: _colorCorporativo,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: _tiposVoluntariado
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _tipoSeleccionado = val),
                ),
              ),
              _buildTextField(
                _descController,
                "Descripción detallada de la actividad*",
                Icons.description_outlined,
                multiline: true,
              ),
              _buildTextField(
                _reqController,
                "Requisitos necesarios para participar*",
                Icons.assignment_late_outlined,
                multiline: true,
              ),
            ]),

            const SizedBox(height: 24),

            // II. UBICACIÓN
            _buildSubtituloSeccion("¿DÓNDE SE REALIZA?"),
            _buildCardContenedor([
              _buildTextField(
                _barrioPuebloController,
                "Barrio o Municipio*",
                Icons.map_outlined,
              ),
              _buildTextField(
                _direccionController,
                "Dirección exacta*",
                Icons.location_on_outlined,
              ),
            ]),

            const SizedBox(height: 24),

            // III. CONTACTO Y ENLACES
            _buildSubtituloSeccion("CONTACTO Y REDES SOCIALES"),
            _buildCardContenedor([
              _buildTextField(
                _telController,
                "Teléfono de contacto*",
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                _emailContactoController,
                "Email de contacto*",
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                _webController,
                "Página Web",
                Icons.language_rounded,
                keyboardType: TextInputType.url,
              ),
              _buildTextField(
                _instagramController,
                "Usuario de Instagram",
                FontAwesomeIcons.instagram,
              ),
              _buildTextField(
                _twitterController,
                "Usuario de X / Twitter",
                FontAwesomeIcons.xTwitter,
              ),
              _buildTextField(
                _facebookController,
                "Página o grupo de Facebook",
                Icons.facebook_outlined,
              ),
            ]),

            const SizedBox(height: 24),

            // IV. PLANIFICACIÓN DE TURNOS
            _buildSubtituloSeccion("TURNOS Y CAPACIDAD"),
            _buildCardContenedor([
              // Selectores de fecha y hora horizontales
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: _colorCorporativo,
                      ),
                      label: Text(
                        _fechaTexto,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorCorporativo,
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: _colorCorporativo,
                      ),
                      label: _formatearHoraPlana(_horaInicioTexto),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorCorporativo,
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: Icon(
                        Icons.access_time_filled_rounded,
                        size: 14,
                        color: _colorCorporativo,
                      ),
                      label: _formatearHoraPlana(_horaFinTexto),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorCorporativo,
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fila de asignación de cupo y botón Añadir
              Wrap(
                alignment: WrapAlignment
                    .spaceBetween, // 🌟 Distribuye el espacio entre los bloques si caben en una línea
                crossAxisAlignment: WrapCrossAlignment
                    .center, // 🌟 Mantiene la alineación vertical de los elementos
                spacing: 8, // Espacio horizontal entre elementos
                runSpacing:
                    12, // 🌟 Espacio vertical de separación si el botón salta a la línea de abajo
                children: [
                  // Agrupamos la zona del contador (Cupo + botones) para que mantengan la cohesión si hay un salto
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Cupo:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Menos
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () {
                          int val =
                              int.tryParse(_voluntariosTurnoController.text) ??
                              1;
                          if (val > 1) {
                            _voluntariosTurnoController.text = (val - 1)
                                .toString();
                          }
                        },
                      ),

                      const SizedBox(width: 6),

                      // Caja de texto de cantidad
                      SizedBox(
                        width: 48,
                        height: 34,
                        child: TextFormField(
                          controller: _voluntariosTurnoController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _colorCorporativo,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Botón Más
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.green,
                          size: 22,
                        ),
                        onPressed: () {
                          int val =
                              int.tryParse(_voluntariosTurnoController.text) ??
                              0;
                          _voluntariosTurnoController.text = (val + 1)
                              .toString();
                        },
                      ),
                    ],
                  ),

                  // Botón Añadir Turno (Dará el salto abajo de forma limpia solo si no cabe al lado)
                  TextButton.icon(
                    onPressed: _agregarTurnoALista,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      "Añadir Turno",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _colorCorporativo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              // Renderizado de turnos agregados de forma fluida
              if (_turnosAgregados.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.black12),
                const SizedBox(height: 6),
                ..._turnosAgregados.map(
                  (turno) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues()),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.green,
                        size: 22,
                      ),
                      title: Text(
                        "${turno['fecha']}  |  ${turno['hora']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "Necesarios: ${turno['voluntarios']} voluntarios",
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _turnosAgregados.remove(turno)),
                      ),
                    ),
                  ),
                ),
              ],
            ]),

            const SizedBox(height: 32),

            // BOTÓN PRINCIPAL DE ENVÍO FIRESTORE
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _colorCorporativo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _publicar,
              child: const Text(
                "PUBLICAR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

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
    TextEditingController controller,
    String label,
    IconData icono, {
    bool multiline = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: multiline ? null : 1,
        keyboardType: multiline ? TextInputType.multiline : keyboardType,
        textInputAction: multiline
            ? TextInputAction.newline
            : TextInputAction.next,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          alignLabelWithHint: true,
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
      ),
    );
  }

  Widget _formatearHoraPlana(String textoHora) {
    return Text(
      textoHora,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );
  }
}
