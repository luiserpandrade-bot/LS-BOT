import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Crear cuenta: al terminar, la sesión queda iniciada.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;
    final entro = await _auth.registrar(_correo.text, _nombre.text, _clave.text);
    // Con la sesión iniciada, la base de la app ya muestra la pantalla principal.
    if (entro && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  validator: Validadores.nombre,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _correo,
                  decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validadores.correo,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _clave,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Entre 8 y 72 caracteres',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
                  validator: Validadores.password,
                ),
                Obx(
                  () => _auth.mensajeError.value.isEmpty
                      ? const SizedBox(height: AppSpacing.lg)
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Text(
                            _auth.mensajeError.value,
                            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.error),
                          ),
                        ),
                ),
                Obx(
                  () => FilledButton(
                    onPressed: _auth.cargando.value ? null : _registrar,
                    child: _auth.cargando.value
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Crear cuenta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
