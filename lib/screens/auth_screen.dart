import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _extraInfoController = TextEditingController();

  bool _esRegistro = false;
  String _rolSeleccionado = 'Voluntario';
  bool _cargando = false;

  // 🌟 NUEVO: Estado para controlar la visibilidad de la contraseña
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _extraInfoController.dispose();
    super.dispose();
  }

  // 🌟 NUEVO: Función nativa para recuperar la contraseña vía Firebase
  Future<void> _recuperarPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, introduce tu correo electrónico para restablecer la contraseña.",
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Correo de recuperación enviado a $email. Revisa tu bandeja de spam.",
            ),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar el correo: $e")),
        );
      }
    }
  }

  Future<void> _autenticar() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, rellena todos los campos.")),
      );
      return;
    }

    if (_esRegistro && _nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, introduce tu nombre.")),
      );
      return;
    }

    if (_esRegistro &&
        _rolSeleccionado == 'Organización' &&
        _extraInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, explica brevemente quién eres o tu entidad.",
          ),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      if (_esRegistro) {
        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
              'nombre': _nombreController.text.trim(),
              'email': _emailController.text.trim(),
              'rol': _rolSeleccionado,
              'fecha_registro': FieldValue.serverTimestamp(),
              'estaVerificado': false,
              'infoVerificacion': _extraInfoController.text.trim(),
            });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error de autenticación";
      if (e.code == 'email-already-in-use') {
        mensaje = "El email ya está en uso.";
      }
      if (e.code == 'weak-password') mensaje = "La contraseña es muy débil.";

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorCorporativo = Color.fromARGB(255, 17, 71, 188);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconoCorporativoNexus(size: 90),
                const SizedBox(height: 24),
                Text(
                  _esRegistro ? "Crear Cuenta" : "¡Te damos la bienvenida!",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _esRegistro
                      ? "Regístrate para empezar a ayudar"
                      : "Inicia sesión para continuar",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (_esRegistro) ...[
                          TextField(
                            controller: _nombreController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Nombre completo",
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: colorCorporativo,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _rolSeleccionado,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: "Tu propósito en la app",
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              prefixIcon: const Icon(
                                Icons.assignment_ind_outlined,
                                color: colorCorporativo,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Voluntario',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Quiero ser voluntario',
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Organización',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Publicar causa (ONG/Particular)',
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _rolSeleccionado = val!),
                          ),
                          const SizedBox(height: 16),
                          if (_rolSeleccionado == 'Organización') ...[
                            TextField(
                              controller: _extraInfoController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Descripción o ID de la entidad',
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                hintText: 'ONG registrada / Particular',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.info_outline,
                                  color: colorCorporativo,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Correo electrónico",
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: colorCorporativo,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText:
                              _ocultarPassword, // 🌟 DINÁMICO: Cambia según el estado del ojo
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: colorCorporativo,
                              size: 20,
                            ),
                            // 🌟 NUEVO: Botón de visibilidad de contraseña
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black45,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _ocultarPassword = !_ocultarPassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        if (!_esRegistro) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _recuperarPassword,
                              child: const Text(
                                "¿Has olvidado la contraseña?",
                                style: TextStyle(
                                  color: colorCorporativo,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _cargando
                            ? const CircularProgressIndicator(
                                color: colorCorporativo,
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorCorporativo,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _autenticar,
                                child: Text(
                                  _esRegistro
                                      ? "REGISTRARSE"
                                      : "INICIAR SESIÓN",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _esRegistro = !_esRegistro),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: _esRegistro
                              ? "¿Ya tienes una cuenta? "
                              : "¿No tienes una cuenta todavía? ",
                        ),
                        TextSpan(
                          text: _esRegistro ? "Inicia Sesión" : "Regístrate",
                          style: const TextStyle(
                            color: colorCorporativo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

class IconoCorporativoNexus extends StatelessWidget {
  final double size;
  const IconoCorporativoNexus({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    const Color colorCorporativo = Color.fromARGB(255, 17, 71, 188);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorCorporativo,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.65,
          height: size * 0.65,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  "η",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'sans-serif',
                    height: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
