import 'package:flutter/material.dart';

class ModalFiltros extends StatefulWidget {
  final List<String> tiposSeleccionados;
  final List<String> todosLosTipos;
  final String orden;
  final double distanciaMax;

  const ModalFiltros({
    super.key,
    required this.tiposSeleccionados,
    required this.todosLosTipos,
    required this.orden,
    required this.distanciaMax,
  });

  @override
  State<ModalFiltros> createState() => _ModalFiltrosState();
}

class _ModalFiltrosState extends State<ModalFiltros> {
  late List<String> temporalSeleccionados;
  late String temporalOrden;
  late double temporalDistancia;

  // Color Nexus
  final Color colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    temporalSeleccionados = List.from(widget.tiposSeleccionados);
    temporalOrden = widget.orden;
    temporalDistancia = widget.distanciaMax;
  }

  Widget _seccionTitulo(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 12),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Center(
              child: Text(
                "Filtros de búsqueda",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.black12, thickness: 1),

            // Ordenar por
            _seccionTitulo("Ordenar por", Icons.sort_rounded),
            DropdownButtonFormField<String>(
              initialValue: temporalOrden,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "reciente",
                  child: Text("Más reciente", style: TextStyle(fontSize: 15)),
                ),
                DropdownMenuItem(
                  value: "antiguo",
                  child: Text("Más antiguo", style: TextStyle(fontSize: 15)),
                ),
              ],
              onChanged: (val) => setState(() => temporalOrden = val!),
            ),

            const SizedBox(height: 15),

            // Distancia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _seccionTitulo("Distancia máxima", Icons.near_me_rounded),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorCorporativo.withValues(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${temporalDistancia.toInt()} km",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: temporalDistancia,
                min: 1,
                max: 100,
                divisions: 100,
                activeColor: colorCorporativo,
                inactiveColor: colorCorporativo.withValues(),
                onChanged: (val) => setState(() => temporalDistancia = val),
              ),
            ),

            const SizedBox(height: 10),

            // Tipo de voluntariado (chips dinámicos)
            _seccionTitulo("Categoría de voluntariado", Icons.category_rounded),

            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.todosLosTipos.map((tipo) {
                final bool seleccionado = temporalSeleccionados.contains(tipo);
                return FilterChip(
                  label: Text(tipo),
                  labelStyle: TextStyle(
                    color: seleccionado ? Colors.white : Colors.black87,
                    fontWeight: seleccionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                  selected: seleccionado,
                  selectedColor: colorCorporativo,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: seleccionado ? Colors.transparent : Colors.black12,
                    ),
                  ),
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        temporalSeleccionados.add(tipo);
                      } else {
                        temporalSeleccionados.remove(tipo);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 35),

            // Botón que aplica los filtros
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: colorCorporativo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'tipos': temporalSeleccionados,
                  'orden': temporalOrden,
                  'distancia': temporalDistancia,
                });
              },
              child: const Text(
                "Aplicar Filtros",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
