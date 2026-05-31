import 'package:flutter/material.dart';

class NotificacionesScreen extends StatefulWidget {
  final bool esOrganizacion;

  const NotificacionesScreen({super.key, required this.esOrganizacion});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  // Apartado 1 (Inscripciones para Org / Estado Aplicación para Voluntario)
  bool appAceptado = true;
  bool emailAceptado = false;

  // Apartado 2 (Solo para Voluntarios)
  bool appNuevos = true;
  bool emailNuevos = true;
  String frecuencia = "Semanalmente";

  // Color corporativo unificado de tu app
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Fondo premium consistente con toda la app
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN 1: INSCRIPCIONES O ESTADO ---
            _buildTitulo(
              widget.esOrganizacion
                  ? "NUEVAS INSCRIPCIONES"
                  : "ESTADO DE APLICACIONES",
            ),
            _buildContenedor([
              _buildSwitch(
                "Notificaciones de la app",
                appAceptado,
                (v) => setState(() => appAceptado = v),
              ),
              _buildSwitch(
                "Notificaciones por email",
                emailAceptado,
                (v) => setState(() => emailAceptado = v),
              ),
            ]),

            // --- SECCIÓN 2: SOLO PARA VOLUNTARIOS ---
            if (!widget.esOrganizacion) ...[
              const SizedBox(height: 25),
              _buildTitulo("NUEVOS VOLUNTARIADOS"),
              _buildContenedor([
                _buildSwitch(
                  "Notificaciones de la app",
                  appNuevos,
                  (v) => setState(() => appNuevos = v),
                ),
                _buildSwitch(
                  "Notificaciones por email",
                  emailNuevos,
                  (v) => setState(() => emailNuevos = v),
                ),
                const Divider(
                  height: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.black12,
                ),

                // Selector de frecuencia reestilizado y acolchado elegantemente
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Frecuencia de avisos",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withValues()),
                        ),
                        child: DropdownButton<String>(
                          value: frecuencia,
                          underline:
                              const SizedBox(), // Eliminamos la línea inferior tosca de Android
                          style: TextStyle(
                            color: _colorCorporativo,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _colorCorporativo,
                          ),
                          items: ["A diario", "Semanalmente"]
                              .map(
                                (f) =>
                                    DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => frecuencia = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DE DISEÑO ---

  Widget _buildTitulo(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      t,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _buildContenedor(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues()),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isEven) {
            return children[index ~/ 2];
          } else {
            // Inserta divisores limpios automáticamente solo entre elementos
            return const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.black12,
            );
          }
        }),
      ),
    );
  }

  Widget _buildSwitch(String t, bool v, Function(bool) onChanged) =>
      SwitchListTile(
        title: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        activeThumbColor: Colors.white, // Color de la bolita interna activa
        activeTrackColor: _colorCorporativo, // Color de fondo del switch activo
        inactiveThumbColor: Colors.grey[400],
        inactiveTrackColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        value: v,
        onChanged: onChanged,
      );
}
