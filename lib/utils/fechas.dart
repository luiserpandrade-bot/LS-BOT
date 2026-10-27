const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// Fecha y hora legibles en español, por ejemplo «27 oct 2026, 14:05».
String fechaLegible(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}, ${dos(fecha.hour)}:${dos(fecha.minute)}';
}

/// Fecha y hora cortas, por ejemplo «27/10 14:05».
String fechaCorta(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)} ${dos(fecha.hour)}:${dos(fecha.minute)}';
}
