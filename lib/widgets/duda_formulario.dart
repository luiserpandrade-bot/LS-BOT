import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Formulario para publicar o editar una duda, pensado para una hoja inferior.
/// `alEnviar` devuelve null si salió bien (la hoja se cierra) o el mensaje
/// del servidor, que se muestra aquí mismo sin cerrar nada.
class DudaFormulario extends StatefulWidget {
  const DudaFormulario({
    super.key,
    required this.titulo,
    required this.textoBoton,
    required this.alEnviar,
    this.textoInicial,
  });

  final String titulo;
  final String textoBoton;
  final String? textoInicial;
  final Future<String?> Function(String texto) alEnviar;

  @override
  State<DudaFormulario> createState() => _DudaFormularioState();
}

class _DudaFormularioState extends State<DudaFormulario> {
  final _formulario = GlobalKey<FormState>();
  late final _texto = TextEditingController(text: widget.textoInicial);
  bool _enviando = false;
  String? _errorServidor;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando || !_formulario.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _errorServidor = null;
    });
    final error = await widget.alEnviar(_texto.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _enviando = false;
      _errorServidor = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.titulo, style: tema.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _texto,
              autofocus: true,
              enabled: !_enviando,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              validator: Validadores.duda,
              decoration: const InputDecoration(labelText: 'Tu duda', alignLabelWithHint: true),
            ),
            if (_errorServidor != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_errorServidor!, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.textoBoton),
            ),
          ],
        ),
      ),
    );
  }
}
