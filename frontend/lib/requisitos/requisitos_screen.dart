import 'package:flutter/material.dart';

import 'models.dart';
import 'requisitos_service.dart';
import '../main.dart' show colorGranate, colorNegro, colorTextoSecundario;

class RequisitosScreen extends StatefulWidget {
  const RequisitosScreen({
    super.key,
    required this.service,
    required this.estudianteId,
  });

  final RequisitosService service;
  final String estudianteId;

  @override
  State<RequisitosScreen> createState() => _RequisitosScreenState();
}

class _RequisitosScreenState extends State<RequisitosScreen> {
  late Future<List<Requisito>> _futureRequisitos;

  @override
  void initState() {
    super.initState();
    _futureRequisitos = widget.service.obtenerRequisitos(widget.estudianteId);
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return colorGranate;
      case 'cumplido':
        return colorNegro;
      default:
        return colorTextoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis requisitos')),
      body: FutureBuilder<List<Requisito>>(
        future: _futureRequisitos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudo cargar la información. Intenta de nuevo.'),
            );
          }

          final requisitos = snapshot.data ?? [];

          if (requisitos.isEmpty) {
            return const Center(child: Text('No tienes requisitos registrados.'));
          }

          return ListView.builder(
            itemCount: requisitos.length,
            itemBuilder: (context, index) {
              final requisito = requisitos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _colorPorEstado(requisito.estado),
                      width: 4,
                    ),
                  ),
                  color: Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    requisito.nombre,
                    style: const TextStyle(color: colorNegro),
                  ),
                  subtitle: Text(
                    requisito.estado,
                    style: const TextStyle(color: colorTextoSecundario),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
