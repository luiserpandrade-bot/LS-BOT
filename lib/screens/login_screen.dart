import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'registro_screen.dart';

/// Inicio de sesión con correo y contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();
  bool _ocultarClave = true;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;
    await _auth.iniciarSesion(_correo.text, _clave.text);
  }

  void _irARegistro() {
    _auth.mensajeError.value = '';
    Get.to(() => const RegistroScreen());
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.memory, size: 64, color: tema.colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text('LS-bot', textAlign: TextAlign.center, style: tema.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Diseño Electrónico y Sistemas Digitales',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Obx(
                    () => _auth.avisoSesion.value.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: AvisoBanner(texto: _auth.avisoSesion.value),
                          ),
                  ),
                  TextFormField(
                    controller: _correo,
                    decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: Validadores.correo,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clave,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _ocultarClave ? 'Mostrar contraseña' : 'Ocultar contraseña',
                        icon: Icon(_ocultarClave ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                      ),
                    ),
                    obscureText: _ocultarClave,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
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
                      onPressed: _auth.cargando.value ? null : _entrar,
                      child: _auth.cargando.value
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: _irARegistro, child: const Text('¿No tienes cuenta? Regístrate')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso informativo (por ejemplo, «Tu sesión caducó»).
class AvisoBanner extends StatelessWidget {
  const AvisoBanner({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colores.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radio),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colores.onSecondaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(texto, style: TextStyle(color: colores.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}
