import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../models/materia.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../widgets/burbuja_mensaje.dart';
import 'ficha_detalle_screen.dart';

/// Chat con LS-bot, que responde con el contenido de las fichas. La materia
/// y la ficha de contexto acotan la búsqueda en el servidor.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  static const preguntasSugeridas = [
    '¿Qué ancho de pista necesito para 3 A?',
    '¿Cómo calculo el periodo del PWM con Timer2?',
    '¿Qué es la inversión de prioridad en un RTOS?',
  ];

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final AsistenteController _asistente = Get.find<AsistenteController>();
  final _texto = TextEditingController();
  String? _errorCampo;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  /// Valida aquí para no gastar un viaje al servidor; el campo se limpia
  /// solo si la pregunta sale.
  Future<void> _enviar(String texto) async {
    final error = Validadores.pregunta(texto);
    setState(() => _errorCampo = error);
    if (error != null) return;
    _texto.clear();
    await _asistente.enviar(texto);
  }

  Future<void> _borrar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar la conversación?'),
        content: const Text('Se borrarán todos los mensajes con LS-bot de este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmado == true) await _asistente.borrarConversacion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LS-bot'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Borrar conversación',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _asistente.mensajes.isEmpty || _asistente.enviando.value ? null : _borrar,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _Encabezado(asistente: _asistente),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final vacio =
                  _asistente.mensajes.isEmpty && !_asistente.enviando.value && _asistente.mensajeError.value.isEmpty;
              if (vacio) return _Saludo(onPreguntar: _enviar);
              return _Conversacion(asistente: _asistente);
            }),
          ),
          _CampoPregunta(texto: _texto, error: _errorCampo, asistente: _asistente, onEnviar: _enviar),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.asistente});

  final AsistenteController asistente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Obx(() {
      final elegida = asistente.materia.value;
      final ficha = asistente.fichaContexto.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: elegida == null,
                  onSelected: (_) => asistente.elegirMateria(null),
                ),
                for (final m in Materia.conocidas) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(m.nombre),
                    selected: elegida == m.codigo,
                    onSelected: (_) => asistente.elegirMateria(m.codigo),
                  ),
                ],
              ],
            ),
          ),
          if (ficha != null)
            Material(
              color: tema.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.push_pin_outlined, size: 18, color: tema.colorScheme.onSecondaryContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Contexto: ${ficha.codigo} ${ficha.titulo}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSecondaryContainer),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar contexto',
                      icon: const Icon(Icons.close),
                      onPressed: asistente.quitarFicha,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// Estado vacío: saludo y preguntas sugeridas que se envían al tocarlas.
class _Saludo extends StatelessWidget {
  const _Saludo({required this.onPreguntar});

  final void Function(String pregunta) onPreguntar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.smart_toy_outlined, size: 56, color: tema.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('¡Hola! Soy LS-bot', textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pregúntame sobre Diseño Electrónico y Sistemas Digitales: respondo con el contenido de las fichas.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in AsistenteScreen.preguntasSugeridas)
                  ActionChip(label: Text(p), onPressed: () => onPreguntar(p)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversacion extends StatelessWidget {
  const _Conversacion({required this.asistente});

  final AsistenteController asistente;

  @override
  Widget build(BuildContext context) => Obx(() => _lista(context));

  Widget _lista(BuildContext context) {
    final tema = Theme.of(context);
    final elementos = <Widget>[
      for (final m in asistente.mensajes)
        BurbujaMensaje(
          mensaje: m,
          onAbrirFuente: (f) => Get.to(() => FichaDetalleScreen(id: f.id, codigo: f.codigo)),
        ),
      if (asistente.enviando.value)
        BurbujaBase(
          color: tema.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppSpacing.sm),
              Text('LS-bot está escribiendo…', style: tema.textTheme.bodyMedium),
            ],
          ),
        )
      else if (asistente.mensajeError.value.isNotEmpty)
        BurbujaBase(
          color: tema.colorScheme.errorContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asistente.mensajeError.value,
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onErrorContainer),
              ),
              TextButton.icon(
                onPressed: asistente.reintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
    ];
    // Invertida: lo más reciente queda abajo, junto al campo, sin desplazar a mano.
    final invertidos = elementos.reversed.toList();
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: invertidos.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => invertidos[i],
    );
  }
}

class _CampoPregunta extends StatelessWidget {
  const _CampoPregunta({required this.texto, required this.error, required this.asistente, required this.onEnviar});

  final TextEditingController texto;
  final String? error;
  final AsistenteController asistente;
  final void Function(String texto) onEnviar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: Obx(() {
          final enviando = asistente.enviando.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: texto,
                  enabled: !enviando,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: onEnviar,
                  decoration: InputDecoration(hintText: 'Escribe tu pregunta', errorText: error, counterText: ''),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                tooltip: 'Enviar',
                icon: const Icon(Icons.send),
                onPressed: enviando ? null : () => onEnviar(texto.text),
              ),
            ],
          );
        }),
      ),
    );
  }
}
