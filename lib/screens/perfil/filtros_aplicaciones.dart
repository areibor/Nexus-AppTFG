import 'package:flutter/material.dart';

class FiltrosAplicaciones extends StatefulWidget {
  final List<String> estadosSeleccionados;

  const FiltrosAplicaciones({super.key, required this.estadosSeleccionados});

  @override
  State<FiltrosAplicaciones> createState() => _ModalFiltrosAplicacionesState();
}

class _ModalFiltrosAplicacionesState extends State<FiltrosAplicaciones> {
  late List<String> temporalEstados;
  final List<String> todosLosEstados = ['pendiente', 'aceptado', 'rechazado'];
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    temporalEstados = List.from(widget.estadosSeleccionados);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Filtrar por estado",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),

          ...todosLosEstados.map((estado) {
            final bool seleccionado = temporalEstados.contains(estado);

            return Theme(
              data: ThemeData(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CheckboxListTile(
                  title: Text(
                    estado[0].toUpperCase() + estado.substring(1),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: seleccionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: seleccionado ? Colors.black87 : Colors.black87,
                    ),
                  ),
                  value: seleccionado,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _colorCorporativo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        temporalEstados.add(estado);
                      } else {
                        temporalEstados.remove(estado);
                      }
                    });
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _colorCorporativo,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, temporalEstados),
            child: const Text(
              "APLICAR FILTROS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
