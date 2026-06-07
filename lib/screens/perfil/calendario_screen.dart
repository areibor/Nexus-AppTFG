import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../voluntario/detalle_voluntariado.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, List<Map<String, dynamic>>> _events = {};

  // Color Nexus
  final Color _colorCorporativo = const Color.fromARGB(255, 17, 71, 188);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarInscripciones();
  }

  String _normDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _cargarInscripciones() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('inscripciones')
        .where('voluntario_uid', isEqualTo: user!.uid)
        .where('estado', isEqualTo: 'Aceptado')
        .snapshots()
        .first;

    Map<String, List<Map<String, dynamic>>> newEvents = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final turno = data['turno'];

      try {
        List<String> partes = turno['fecha'].split('/');
        DateTime fechaOriginal = DateTime(
          int.parse(partes[2]), // año
          int.parse(partes[1]), // mes
          int.parse(partes[0]), // día
        );

        String key = _normDate(fechaOriginal);

        if (newEvents[key] == null) newEvents[key] = [];
        newEvents[key]!.add({...data, 'id': doc.id});
      } catch (e) {
        debugPrint("Error parseando fecha en calendario: $e");
      }
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[_normDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Mi Calendario",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,

              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.black87,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black87,
                ),
              ),

              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),

              calendarStyle: CalendarStyle(
                outsideDaysVisible:
                    false, // Para ocultar los días del mes anterior y limpiar la vista
                defaultTextStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),

                markerDecoration: BoxDecoration(
                  color: _colorCorporativo,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,

                selectedDecoration: BoxDecoration(
                  color: const Color.fromARGB(79, 85, 133, 238),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),

                todayDecoration: BoxDecoration(
                  color: const Color.fromARGB(141, 18, 64, 164),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              "No tienes voluntariados para este día.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildTarjetaCalendario(event);
      },
    );
  }

  Widget _buildTarjetaCalendario(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        onTap: () => _verDetalles(event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(125, 85, 133, 238),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: _colorCorporativo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['voluntariado_titulo'] ?? 'Sin título',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Turno: ${event['turno']['hora']}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalles(Map<String, dynamic> event) async {
    String idPub =
        event['id_publicacion'] ?? event['voluntariado_uid_publicacion'];

    final doc = await FirebaseFirestore.instance
        .collection('voluntariados')
        .doc(idPub)
        .get();

    if (doc.exists && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleVoluntariado(
            data: doc.data()!,
            idPublicacion: doc.id,
            modoVistaInscrito: true,
          ),
        ),
      );
    }
  }
}
