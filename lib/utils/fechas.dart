const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// Fecha y hora legibles en español, por ejemplo «27 oct 2026, 14:05».
String fechaLegible(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}, ${dos(fecha.hour)}:${dos(fecha.minute)}';
}
