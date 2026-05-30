import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const int kDriveThumbnailSize = 1000;
const int kImagenInsumoCache = 240;
const int kImagenEventoCache = 260;
const int kImagenCarritoCache = 180;

final ValueNotifier<ThemeMode> modoTemaApp = ValueNotifier(ThemeMode.light);

bool esModoOscuro(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

void cambiarModoTema() {
  modoTemaApp.value =
      modoTemaApp.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

Widget construirBotonModoTema(BuildContext context) {
  final oscuro = esModoOscuro(context);

  return IconButton(
    tooltip: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
    onPressed: cambiarModoTema,
    icon: Icon(oscuro ? Icons.light_mode : Icons.dark_mode),
  );
}

String obtenerNombreSesion(User usuario) {
  final correo = usuario.email?.trim() ?? 'usuario';

  if (correo.contains('@')) {
    return correo.split('@').first;
  }

  return correo;
}

void mostrarCuadroCuenta(BuildContext context, User usuario) {
  final correo = usuario.email ?? 'Sin correo';
  final nombre = obtenerNombreSesion(usuario);

  showDialog<void>(
    context: context,
    builder: (context) {
      final color = Theme.of(context).colorScheme.primary;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_circle, color: color, size: 58),
            ),
            const SizedBox(height: 14),
            Text(
              'Hola $nombre',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Que tengas un buen dia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorTextoSecundario(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      correo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesion cerrada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion'),
            ),
          ),
        ],
      );
    },
  );
}

Widget construirBotonCuenta(
  BuildContext context, {
  required bool firebaseDisponible,
}) {
  return StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      final usuario = snapshot.data;

      return IconButton(
        tooltip: usuario == null ? 'Iniciar sesión' : 'Cuenta',
        icon: Icon(
          usuario == null
              ? Icons.account_circle_outlined
              : Icons.account_circle,
        ),
        onPressed: () {
          if (usuario != null) {
            mostrarCuadroCuenta(context, usuario);
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return LoginInsumosScreen(
                  firebaseDisponible: firebaseDisponible,
                  tituloBarra: 'Cuenta',
                  tituloAcceso: 'Inicia sesión o crea una cuenta',
                  volverAlAnteriorAlAutenticar: true,
                );
              },
            ),
          );
        },
      );
    },
  );
}

Color colorTextoSecundario(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Color ajustarColorTema(BuildContext context, Color color) {
  if (!esModoOscuro(context)) {
    return color;
  }

  return Color.lerp(color, Colors.white, 0.18) ?? color;
}

const double kLatitudEmpresa = -12.06810;
const double kLongitudEmpresa = -75.21030;
const double kLatitudUsuarioDemo = -12.06480;
const double kLongitudUsuarioDemo = -75.20520;
const MethodChannel canalDeliveryGlobal = MethodChannel(
  'inventario_catering/delivery',
);

Future<void> abrirRutaGoogleMaps(BuildContext context) async {
  try {
    await canalDeliveryGlobal.invokeMethod('openDeliveryMap');
  } on PlatformException catch (e) {
    if (!context.mounted) {
      return;
    }

    final mensaje =
        e.code == 'PERMISSION_DENIED'
            ? 'Permiso de ubicación denegado'
            : 'No se pudo abrir Google Maps';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseDisponible = true;

  try {
    await Firebase.initializeApp();
  } catch (_) {
    firebaseDisponible = false;
  }

  runApp(MyApp(firebaseDisponible: firebaseDisponible));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firebaseDisponible});

  final bool firebaseDisponible;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: modoTemaApp,
      builder: (context, modoTema, child) {
        return MaterialApp(
          title: 'Massha’s Catering',
          debugShowCheckedModeBanner: false,
          themeMode: modoTema,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
            scaffoldBackgroundColor: const Color(0xFFFFF7F0),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF17110E),
            useMaterial3: true,
          ),
          home: InicioScreen(firebaseDisponible: firebaseDisponible),
        );
      },
    );
  }
}

class UbicacionEmpresaView extends StatefulWidget {
  const UbicacionEmpresaView({super.key, required this.onAbrirRuta});

  final VoidCallback onAbrirRuta;

  @override
  State<UbicacionEmpresaView> createState() => _UbicacionEmpresaViewState();
}

class _UbicacionEmpresaViewState extends State<UbicacionEmpresaView> {
  double latitudUsuario = kLatitudUsuarioDemo;
  double longitudUsuario = kLongitudUsuarioDemo;
  bool usandoReferencia = true;

  @override
  void initState() {
    super.initState();
    obtenerUbicacionActual();
  }

  Future<void> obtenerUbicacionActual() async {
    try {
      final respuesta = await canalDeliveryGlobal
          .invokeMapMethod<String, dynamic>('getCurrentLocation');

      final latitud = respuesta?['latitude'];
      final longitud = respuesta?['longitude'];

      if (!mounted || latitud is! num || longitud is! num) {
        return;
      }

      setState(() {
        latitudUsuario = latitud.toDouble();
        longitudUsuario = longitud.toDouble();
        usandoReferencia = false;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }

      setState(() {
        usandoReferencia = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = const Color(0xFF168A4A);
    final superficie = Theme.of(context).colorScheme.surface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        Card(
          elevation: 3,
          color: superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorPrimario.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.route, color: colorPrimario, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ubicación y ruta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usandoReferencia
                            ? 'Mapa referencial con ubicación y empresa.'
                            : 'Mapa con tu ubicación actual y la empresa.',
                        style: TextStyle(color: colorTextoSecundario(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 1.28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  esModoOscuro(context)
                      ? const Color(0xFF102118)
                      : const Color(0xFFE8F4EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorPrimario.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: MapaRutaPainter(
                  oscuro: esModoOscuro(context),
                  colorPrimario: colorPrimario,
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 34,
                      top: 42,
                      child: _PinMapa(
                        icono: Icons.person_pin_circle,
                        texto: 'Tú',
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    Positioned(
                      right: 38,
                      bottom: 58,
                      child: _PinMapa(
                        icono: Icons.storefront,
                        texto: 'Empresa',
                        color: colorPrimario,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorPrimario.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Empresa: $kLatitudEmpresa, $kLongitudEmpresa',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TarjetaCoordenadas(
          titulo:
              usandoReferencia
                  ? 'Ubicación actual referencial'
                  : 'Ubicación actual',
          icono: Icons.my_location,
          latitud: latitudUsuario,
          longitud: longitudUsuario,
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(height: 10),
        _TarjetaCoordenadas(
          titulo: 'Massha’s Catering',
          icono: Icons.storefront,
          latitud: kLatitudEmpresa,
          longitud: kLongitudEmpresa,
          color: colorPrimario,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: widget.onAbrirRuta,
          icon: const Icon(Icons.navigation),
          label: const Text('Navegar con Google Maps'),
          style: FilledButton.styleFrom(
            backgroundColor: colorPrimario,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}

class _TarjetaCoordenadas extends StatelessWidget {
  const _TarjetaCoordenadas({
    required this.titulo,
    required this.icono,
    required this.latitud,
    required this.longitud,
    required this.color,
  });

  final String titulo;
  final IconData icono;
  final double latitud;
  final double longitud;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(icono, color: color),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Latitud: $latitud\nLongitud: $longitud'),
      ),
    );
  }
}

class _PinMapa extends StatelessWidget {
  const _PinMapa({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Icon(icono, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            texto,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class MapaRutaPainter extends CustomPainter {
  const MapaRutaPainter({required this.oscuro, required this.colorPrimario});

  final bool oscuro;
  final Color colorPrimario;

  @override
  void paint(Canvas canvas, Size size) {
    final calle =
        Paint()
          ..color = oscuro ? const Color(0xFF2D3F35) : Colors.white
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;
    final cuadricula =
        Paint()
          ..color =
              oscuro
                  ? Colors.white.withValues(alpha: 0.08)
                  : colorPrimario.withValues(alpha: 0.16)
          ..strokeWidth = 1.4;
    final ruta =
        Paint()
          ..color = colorPrimario
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (var x = -size.width; x < size.width * 1.7; x += 56) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width, size.height),
        cuadricula,
      );
    }
    for (var y = 42.0; y < size.height; y += 62) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 26), calle);
    }

    final path =
        Path()
          ..moveTo(size.width * 0.18, size.height * 0.25)
          ..cubicTo(
            size.width * 0.38,
            size.height * 0.35,
            size.width * 0.42,
            size.height * 0.65,
            size.width * 0.64,
            size.height * 0.6,
          )
          ..cubicTo(
            size.width * 0.78,
            size.height * 0.57,
            size.width * 0.78,
            size.height * 0.76,
            size.width * 0.84,
            size.height * 0.78,
          );
    canvas.drawPath(path, ruta);
  }

  @override
  bool shouldRepaint(covariant MapaRutaPainter oldDelegate) {
    return oldDelegate.oscuro != oscuro ||
        oldDelegate.colorPrimario != colorPrimario;
  }
}

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key, required this.firebaseDisponible});

  final bool firebaseDisponible;

  void abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.restaurant_menu,
                size: 82,
                color: Colors.deepOrange.shade600,
              ),
              const SizedBox(height: 18),
              const Text(
                'Massha’s Catering',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Empresa de catering',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Bienvenido(a)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed:
                    () => abrirPantalla(
                      context,
                      InventarioScreen(firebaseDisponible: firebaseDisponible),
                    ),
                icon: const Icon(Icons.inventory_2),
                label: const Text('Insumos de la Empresa'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    () => abrirPantalla(
                      context,
                      ProductosEventosScreen(
                        firebaseDisponible: firebaseDisponible,
                      ),
                    ),
                icon: const Icon(Icons.celebration),
                label: const Text('Productos para eventos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginInsumosScreen extends StatefulWidget {
  const LoginInsumosScreen({
    super.key,
    required this.firebaseDisponible,
    this.construirDestino,
    this.tituloBarra = 'Login de Insumos',
    this.tituloAcceso = 'Acceso a Insumos de la Empresa',
    this.volverAlAnteriorAlAutenticar = false,
  });

  final bool firebaseDisponible;
  final WidgetBuilder? construirDestino;
  final String tituloBarra;
  final String tituloAcceso;
  final bool volverAlAnteriorAlAutenticar;

  @override
  State<LoginInsumosScreen> createState() => _LoginInsumosScreenState();
}

class _LoginInsumosScreenState extends State<LoginInsumosScreen> {
  final TextEditingController controladorCorreo = TextEditingController();
  final TextEditingController controladorPassword = TextEditingController();
  bool cargando = false;
  bool creandoCuenta = false;
  bool ocultarPassword = true;
  String? mensajeError;

  @override
  void dispose() {
    controladorCorreo.dispose();
    controladorPassword.dispose();
    super.dispose();
  }

  bool validarFormulario(String correo, String password) {
    if (!widget.firebaseDisponible) {
      setState(() {
        mensajeError = 'Firebase no esta configurado para Android.';
      });
      return false;
    }

    if (correo.isEmpty || password.isEmpty) {
      setState(() {
        mensajeError = 'Ingresa correo y contrasena.';
      });
      return false;
    }

    return true;
  }

  void abrirDestino() {
    if (widget.volverAlAnteriorAlAutenticar) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return widget.construirDestino?.call(context) ??
              InventarioScreen(firebaseDisponible: widget.firebaseDisponible);
        },
      ),
    );
  }

  Future<void> guardarUsuarioNuevo(User usuario, String correo) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .set({
          'uid': usuario.uid,
          'correo': correo,
          'metodo': 'correo_contrasena',
          'creadoEn': FieldValue.serverTimestamp(),
        });
  }

  Future<void> iniciarSesion() async {
    final correo = controladorCorreo.text.trim();
    final password = controladorPassword.text.trim();

    if (!validarFormulario(correo, password)) {
      return;
    }

    setState(() {
      cargando = true;
      creandoCuenta = false;
      mensajeError = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      if (!mounted) {
        return;
      }

      abrirDestino();
    } on FirebaseAuthException catch (e) {
      setState(() {
        mensajeError = switch (e.code) {
          'user-not-found' => 'No existe un usuario con ese correo.',
          'wrong-password' => 'La contrasena es incorrecta.',
          'invalid-credential' => 'Correo o contrasena incorrectos.',
          'invalid-email' => 'El correo no tiene un formato valido.',
          _ => 'No se pudo iniciar sesion. ${e.code}',
        };
      });
    } catch (e) {
      setState(() {
        mensajeError = 'No se pudo iniciar sesion. $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> crearCuenta() async {
    final correo = controladorCorreo.text.trim();
    final password = controladorPassword.text.trim();

    if (!validarFormulario(correo, password)) {
      return;
    }

    if (password.length < 6) {
      setState(() {
        mensajeError = 'La contrasena debe tener al menos 6 caracteres.';
      });
      return;
    }

    setState(() {
      cargando = true;
      creandoCuenta = true;
      mensajeError = null;
    });

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: password);

      final usuario = credencial.user;

      if (usuario == null) {
        throw FirebaseAuthException(
          code: 'usuario-no-creado',
          message: 'No se pudo obtener el usuario creado.',
        );
      }

      await guardarUsuarioNuevo(usuario, correo);

      if (!mounted) {
        return;
      }

      abrirDestino();
    } on FirebaseAuthException catch (e) {
      setState(() {
        mensajeError = switch (e.code) {
          'email-already-in-use' => 'Ese correo ya tiene una cuenta.',
          'invalid-email' => 'El correo no tiene un formato valido.',
          'weak-password' => 'La contrasena es muy debil.',
          _ => 'No se pudo crear la cuenta. ${e.code}',
        };
      });
    } catch (e) {
      setState(() {
        mensajeError = 'No se pudo crear la cuenta. $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
          creandoCuenta = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tituloBarra), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Icon(
              Icons.lock_person,
              size: 76,
              color: Colors.deepOrange.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              widget.tituloAcceso,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controladorCorreo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controladorPassword,
              obscureText: ocultarPassword,
              decoration: InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      ocultarPassword = !ocultarPassword;
                    });
                  },
                  icon: Icon(
                    ocultarPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => iniciarSesion(),
            ),
            if (mensajeError != null) ...[
              const SizedBox(height: 12),
              Text(
                mensajeError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: cargando ? null : iniciarSesion,
              icon:
                  cargando && !creandoCuenta
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.login),
              label: Text(
                cargando && !creandoCuenta ? 'Iniciando...' : 'Iniciar sesión',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cargando ? null : crearCuenta,
              icon:
                  cargando && creandoCuenta
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.person_add),
              label: Text(
                cargando && creandoCuenta ? 'Creando...' : 'Crear cuenta',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key, required this.firebaseDisponible});

  final bool firebaseDisponible;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  static const String categoriaTodas = 'Todas';

  List<Map<String, dynamic>> productos = [];
  final TextEditingController controladorBusqueda = TextEditingController();
  final Map<String, int> carrito = {};
  late final AnimationController controladorAnimacionCarrito;
  late final Animation<double> animacionCarrito;
  bool cargando = true;
  String? mensajeError;
  String categoriaSeleccionada = categoriaTodas;
  int pestanaActual = 0;

  static const Map<String, double> preciosReferenciales = {
    'ALI-001': 9.50,
    'ALI-002': 24.00,
    'ALI-003': 16.50,
    'ALI-004': 18.00,
    'ALI-005': 18.50,
    'LAC-001': 4.20,
    'LAC-002': 14.00,
    'LAC-003': 22.00,
    'LAC-004': 17.50,
    'LAC-005': 12.00,
    'VER-001': 2.80,
    'VER-002': 4.50,
    'VER-003': 3.80,
    'VER-004': 3.20,
    'VER-005': 2.60,
    'VER-006': 6.50,
    'FRU-001': 5.50,
    'FRU-002': 6.80,
    'FRU-003': 7.50,
    'FRU-004': 12.00,
    'ABA-001': 4.80,
    'ABA-002': 5.20,
    'ABA-003': 4.00,
    'ABA-004': 4.30,
    'ABA-005': 2.20,
    'ABA-006': 7.00,
    'CON-001': 9.80,
    'CON-002': 4.50,
    'CON-003': 8.90,
    'CON-004': 13.50,
    'CON-005': 18.00,
    'BEB-001': 1.80,
    'BEB-002': 3.20,
    'BEB-003': 2.50,
    'BEB-004': 16.00,
    'DES-001': 12.00,
    'DES-002': 10.00,
    'LIM-001': 11.50,
  };

  @override
  void initState() {
    super.initState();
    controladorAnimacionCarrito = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    animacionCarrito = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.34), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.34, end: 1.0), weight: 45),
    ]).animate(
      CurvedAnimation(
        parent: controladorAnimacionCarrito,
        curve: Curves.easeOutBack,
      ),
    );

    if (widget.firebaseDisponible) {
      obtenerProductos();
    } else {
      cargando = false;
      mensajeError =
          'Firebase no esta configurado para Android.\n'
          'Agrega el archivo android/app/google-services.json y vuelve a ejecutar flutter run.';
    }
  }

  @override
  void dispose() {
    controladorBusqueda.dispose();
    controladorAnimacionCarrito.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get productosFiltrados {
    final busqueda = controladorBusqueda.text.trim().toLowerCase();

    return productos.where((producto) {
      final nombre = producto['producto']?.toString().toLowerCase() ?? '';
      final categoria = producto['categoria']?.toString().toLowerCase() ?? '';
      final coincideBusqueda =
          busqueda.isEmpty ||
          nombre.contains(busqueda) ||
          categoria.contains(busqueda);
      final coincideCategoria =
          categoriaSeleccionada == categoriaTodas ||
          categoria == categoriaSeleccionada.toLowerCase();

      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  List<String> get categoriasDisponibles {
    final categorias = <String>[];

    for (final producto in productos) {
      final categoria = producto['categoria']?.toString().trim() ?? '';

      if (categoria.isNotEmpty && !categorias.contains(categoria)) {
        categorias.add(categoria);
      }
    }

    categorias.sort();
    return [categoriaTodas, ...categorias];
  }

  void precargarImagenesProductos(List<Map<String, dynamic>> lista) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      for (final producto in lista.take(12)) {
        final imagen = obtenerImagenProducto(
          producto['codigo']?.toString() ?? '',
          producto['imagen']?.toString() ?? '',
        );

        if (imagen.isNotEmpty) {
          precacheImage(
            ResizeImage.resizeIfNeeded(
              kImagenInsumoCache,
              null,
              NetworkImage(imagen),
            ),
            context,
          );
        }
      }
    });
  }

  int get totalProductosCarrito {
    return carrito.values.fold(0, (total, cantidad) => total + cantidad);
  }

  double obtenerPrecioProducto(String codigo) {
    return preciosReferenciales[codigo] ?? 0;
  }

  String formatearPrecio(double precio) {
    return 'S/ ${precio.toStringAsFixed(2)}';
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';

    if (codigo.isEmpty) {
      return;
    }

    setState(() {
      carrito[codigo] = (carrito[codigo] ?? 0) + 1;
    });
    controladorAnimacionCarrito.forward(from: 0);
  }

  void actualizarCantidadCarrito(String codigo, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        carrito.remove(codigo);
      } else {
        carrito[codigo] = nuevaCantidad;
      }
    });
  }

  void abrirCarrito() {
    if (totalProductosCarrito == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todavia no agregaste productos al carrito'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          Widget construirCarrito() {
            return CarritoProductosScreen(
              productos: productos,
              carrito: carrito,
              obtenerImagenProducto: obtenerImagenProducto,
              obtenerPrecioProducto: obtenerPrecioProducto,
              formatearPrecio: formatearPrecio,
              onActualizarCantidad: actualizarCantidadCarrito,
            );
          }

          if (FirebaseAuth.instance.currentUser != null) {
            return construirCarrito();
          }

          return LoginInsumosScreen(
            firebaseDisponible: widget.firebaseDisponible,
            tituloBarra: 'Login de Carrito',
            tituloAcceso: 'Para ingresar al carrito debe iniciar sesión',
            construirDestino: (_) => construirCarrito(),
          );
        },
      ),
    );
  }

  Widget construirIconoCarritoAnimado() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: RepaintBoundary(
          child: Badge(
            isLabelVisible: totalProductosCarrito > 0,
            label: Text(totalProductosCarrito.toString()),
            child: ClipRect(
              child: SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: ScaleTransition(
                    scale: animacionCarrito,
                    child: const Icon(Icons.shopping_cart),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> obtenerProductos() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('inventario_catering')
              .orderBy('codigo')
              .get();

      setState(() {
        productos =
            snapshot.docs.map((doc) {
              final producto = {'id': doc.id, ...doc.data()};

              if (producto['codigo'] == 'ABA-001') {
                producto['producto'] = 'Pan de molde';
                producto['categoria'] = 'Panadería';
                producto['descripcion'] =
                    'Pan suave en tajadas para sandwiches, desayunos y preparaciones de catering.';
                producto['unidad'] = 'paquetes';
                producto['proveedor'] = 'Distribuidora Lima SAC';
              }

              return producto;
            }).toList();

        cargando = false;
      });
      precargarImagenesProductos(productos);
    } catch (e) {
      setState(() {
        cargando = false;
        mensajeError = 'No se pudo cargar el inventario.\n$e';
      });
    }
  }

  Color obtenerColorEstado(String estado) {
    final estadoMinuscula = estado.toLowerCase();

    if (estadoMinuscula.contains('suficiente')) {
      return Colors.green;
    }

    if (estadoMinuscula.contains('bajo')) {
      return Colors.orange;
    }

    if (estadoMinuscula.contains('agotado')) {
      return Colors.red;
    }

    return Colors.grey;
  }

  IconData obtenerIconoCategoria(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('carne') || texto.contains('prote')) {
      return Icons.restaurant;
    }
    if (texto.contains('lact')) {
      return Icons.local_drink;
    }
    if (texto.contains('verdura') || texto.contains('hortaliza')) {
      return Icons.eco;
    }
    if (texto.contains('fruta')) {
      return Icons.spa;
    }
    if (texto.contains('panader') || texto.contains('base')) {
      return Icons.bakery_dining;
    }
    if (texto.contains('abarrote') || texto.contains('grano')) {
      return Icons.grain;
    }
    if (texto.contains('bebida')) {
      return Icons.local_cafe;
    }
    if (texto.contains('descartable')) {
      return Icons.flatware;
    }
    if (texto.contains('implemento') || texto.contains('servicio')) {
      return Icons.room_service;
    }
    if (texto.contains('limpieza')) {
      return Icons.cleaning_services;
    }

    return Icons.inventory_2;
  }

  Color obtenerColorCategoria(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('carne') || texto.contains('prote')) {
      return const Color(0xFF8A5A44);
    }
    if (texto.contains('verdura') || texto.contains('hortaliza')) {
      return const Color(0xFF4F7D4F);
    }
    if (texto.contains('fruta')) {
      return const Color(0xFFA7682A);
    }
    if (texto.contains('bebida')) {
      return const Color(0xFF3D6F99);
    }
    if (texto.contains('abarrote') || texto.contains('grano')) {
      return const Color(0xFF9A6A2D);
    }
    if (texto.contains('panader') || texto.contains('base')) {
      return const Color(0xFF9A6A2D);
    }
    if (texto.contains('lact')) {
      return const Color(0xFF317B9B);
    }
    if (texto.contains('descartable')) {
      return const Color(0xFF6A6A6A);
    }
    if (texto.contains('implemento') || texto.contains('servicio')) {
      return const Color(0xFF7A5B2E);
    }
    if (texto.contains('limpieza')) {
      return const Color(0xFF3E7C70);
    }

    return Colors.deepOrange;
  }

  Widget construirImagen(String nombre, String categoria, String urlImagen) {
    final color = ajustarColorTema(context, obtenerColorCategoria(categoria));

    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child:
          urlImagen.isEmpty
              ? Icon(obtenerIconoCategoria(categoria), color: color, size: 30)
              : Image.network(
                urlImagen,
                fit: BoxFit.scaleDown,
                cacheWidth: kImagenInsumoCache,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    obtenerIconoCategoria(categoria),
                    color: color,
                    size: 30,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  );
                },
              ),
    );
  }

  String obtenerImagenProducto(String codigo, String urlImagen) {
    final url = urlImagen.trim();

    if (url.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(url);

    if (uri == null || !uri.host.contains('drive.google.com')) {
      return url;
    }

    final idPorQuery = uri.queryParameters['id'];

    if (idPorQuery != null && idPorQuery.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$idPorQuery&sz=w$kDriveThumbnailSize';
    }

    final segmentos = uri.pathSegments;
    final indiceFile = segmentos.indexOf('d');

    if (indiceFile >= 0 && indiceFile + 1 < segmentos.length) {
      final idArchivo = segmentos[indiceFile + 1];
      return 'https://drive.google.com/thumbnail?id=$idArchivo&sz=w$kDriveThumbnailSize';
    }

    return url;
  }

  Widget construirChipEstado(String estado) {
    final colorEstado = obtenerColorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorEstado),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: colorEstado,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget construirPestanasCategorias() {
    final categorias = categoriasDisponibles;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final seleccionada = categoria == categoriaSeleccionada;
          final color =
              categoria == categoriaTodas
                  ? const Color(0xFFE86A33)
                  : ajustarColorTema(context, obtenerColorCategoria(categoria));

          return ChoiceChip(
            selected: seleccionada,
            showCheckmark: false,
            avatar: Icon(
              categoria == categoriaTodas
                  ? Icons.grid_view
                  : obtenerIconoCategoria(categoria),
              size: 18,
              color: seleccionada ? Colors.white : color,
            ),
            label: Text(categoria),
            labelStyle: TextStyle(
              color: seleccionada ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
            selectedColor: color,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: color.withValues(alpha: 0.45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            onSelected: (_) {
              setState(() {
                categoriaSeleccionada = categoria;
              });
            },
          );
        },
      ),
    );
  }

  Widget construirTarjetaProducto(Map<String, dynamic> producto) {
    final String codigo = producto['codigo']?.toString() ?? '';
    final String nombre = producto['producto']?.toString() ?? 'Sin nombre';
    final String categoria =
        producto['categoria']?.toString() ?? 'Sin categoría';
    final String descripcion = producto['descripcion']?.toString() ?? '';
    final String unidad = producto['unidad']?.toString() ?? '';
    final String stockActual = producto['stockActual']?.toString() ?? '0';
    final String stockMinimo = producto['stockMinimo']?.toString() ?? '0';
    final String ubicacion =
        producto['ubicacion']?.toString() ?? 'Sin ubicación';
    final String proveedor =
        producto['proveedor']?.toString() ?? 'Sin proveedor';
    final String estado = producto['estado']?.toString() ?? 'Sin estado';
    final double precio = obtenerPrecioProducto(codigo);
    final int cantidadCarrito = carrito[codigo] ?? 0;
    final Color colorCategoria = ajustarColorTema(
      context,
      obtenerColorCategoria(categoria),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorCategoria.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            construirImagen(
              nombre,
              categoria,
              obtenerImagenProducto(
                codigo,
                producto['imagen']?.toString() ?? '',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    codigo,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorTextoSecundario(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    categoria,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorCategoria,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(descripcion, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stock: $stockActual $unidad',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Mín: $stockMinimo',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ubicación: $ubicacion',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorTextoSecundario(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proveedor: $proveedor',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorTextoSecundario(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      construirChipEstado(estado),
                      const Spacer(),
                      Text(
                        formatearPrecio(precio),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => agregarAlCarrito(producto),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorCategoria,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (cantidadCarrito > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorCategoria.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorCategoria.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'x$cantidadCarrito',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorCategoria,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirContenido() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mensajeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            mensajeError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (productos.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos registrados',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final productosVisibles = productosFiltrados;

    return RefreshIndicator(
      onRefresh: obtenerProductos,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              controller: controladorBusqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoria',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    controladorBusqueda.text.isEmpty
                        ? null
                        : IconButton(
                          onPressed: () {
                            controladorBusqueda.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.orange.shade100),
                ),
              ),
            ),
          ),
          construirPestanasCategorias(),
          const SizedBox(height: 6),
          if (productosVisibles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  'No se encontraron productos',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            )
          else
            ...productosVisibles.map(construirTarjetaProducto),
        ],
      ),
    );
  }

  Widget construirContenidoActual() {
    if (pestanaActual == 2) {
      return UbicacionEmpresaView(
        onAbrirRuta: () => abrirRutaGoogleMaps(context),
      );
    }

    return construirContenido();
  }

  void cambiarPestanaInferior(int indice) {
    if (indice == 1) {
      abrirCarrito();
      return;
    }

    setState(() {
      pestanaActual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE86A33),
        foregroundColor: Colors.white,
        title: Text(
          pestanaActual == 2 ? 'Ubicación' : 'Insumos de la Empresa',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          construirBotonCuenta(
            context,
            firebaseDisponible: widget.firebaseDisponible,
          ),
          construirBotonModoTema(context),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: construirContenidoActual(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pestanaActual,
        onDestinationSelected: cambiarPestanaInferior,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Insumos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: totalProductosCarrito > 0,
              label: Text(totalProductosCarrito.toString()),
              child: ScaleTransition(
                scale: animacionCarrito,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            selectedIcon: ScaleTransition(
              scale: animacionCarrito,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
        ],
      ),
    );
  }
}

class ProductosEventosScreen extends StatefulWidget {
  const ProductosEventosScreen({super.key, required this.firebaseDisponible});

  final bool firebaseDisponible;

  @override
  State<ProductosEventosScreen> createState() => _ProductosEventosScreenState();
}

class _ProductosEventosScreenState extends State<ProductosEventosScreen>
    with SingleTickerProviderStateMixin {
  static const String categoriaTodas = 'Todas';

  final TextEditingController controladorBusqueda = TextEditingController();
  final Map<String, int> carrito = {};
  late final AnimationController controladorAnimacionCarrito;
  late final Animation<double> animacionCarrito;
  List<Map<String, dynamic>> productosEventos = [];
  bool cargando = true;
  String? mensajeError;
  String categoriaSeleccionada = categoriaTodas;
  int pestanaActual = 0;

  static const List<Map<String, dynamic>> productosEventosBase = [
    {
      'codigo': 'EVT-001',
      'producto': 'Buffet peruano para eventos',
      'categoria': 'Buffets',
      'descripcion':
          'Servicio de platos peruanos variados para matrimonios, reuniones familiares, aniversarios y eventos corporativos.',
      'tipo': 'paquete',
    },
    {
      'codigo': 'EVT-002',
      'producto': 'Cena para matrimonio',
      'categoria': 'Matrimonios',
      'descripcion':
          'Cena formal con entrada, fondo, bebida y postre para recepciones de boda.',
      'tipo': 'servicio',
    },
    {
      'codigo': 'EVT-003',
      'producto': 'Coffee break empresarial',
      'categoria': 'Corporativo',
      'descripcion':
          'Bebidas calientes, jugos, bocaditos y dulces para reuniones o capacitaciones.',
      'tipo': 'servicio',
    },
    {
      'codigo': 'EVT-004',
      'producto': 'Mesa de bocaditos salados',
      'categoria': 'Bocaditos',
      'descripcion':
          'Mini sandwiches, empanaditas, tequenos y piqueos para recepciones sociales.',
      'tipo': 'mesa',
    },
    {
      'codigo': 'EVT-005',
      'producto': 'Mesa de bocaditos dulces',
      'categoria': 'Bocaditos',
      'descripcion':
          'Trufas, alfajores, cupcakes, mini tartas y dulces decorativos para eventos.',
      'tipo': 'mesa',
    },
    {
      'codigo': 'EVT-006',
      'producto': 'Pack de bebidas para fiesta',
      'categoria': 'Bebidas',
      'descripcion':
          'Agua, gaseosas, jugos y hielo para matrimonios, graduaciones y cumpleanos.',
      'tipo': 'pack',
    },
    {
      'codigo': 'EVT-007',
      'producto': 'Mesa de postres decorada',
      'categoria': 'Postres',
      'descripcion':
          'Postres individuales con presentacion para mesa principal o zona dulce.',
      'tipo': 'mesa',
    },
    {
      'codigo': 'EVT-008',
      'producto': 'Menu para graduacion',
      'categoria': 'Graduaciones',
      'descripcion':
          'Menu completo para celebraciones de promocion, egresados y ceremonias.',
      'tipo': 'paquete',
    },
    {
      'codigo': 'EVT-009',
      'producto': 'Menu infantil para eventos',
      'categoria': 'Infantil',
      'descripcion':
          'Mini hamburguesas, nuggets, papas, jugos y dulces para eventos infantiles.',
      'tipo': 'paquete',
    },
    {
      'codigo': 'EVT-010',
      'producto': 'Box lunch ejecutivo',
      'categoria': 'Corporativo',
      'descripcion':
          'Caja individual con sandwich, fruta, bebida y snack para reuniones o viajes.',
      'tipo': 'unidad',
    },
    {
      'codigo': 'EVT-011',
      'producto': 'Servicio de mozos',
      'categoria': 'Personal',
      'descripcion':
          'Personal de atencion para servicio en mesa, buffet, bebidas y recepcion.',
      'tipo': 'servicio',
    },
    {
      'codigo': 'EVT-012',
      'producto': 'Alquiler de utensilios',
      'categoria': 'Implementos',
      'descripcion':
          'Utensilios, platos, vasos, cubiertos y copas para recepciones formales o buffet.',
      'tipo': 'pack',
    },
    {
      'codigo': 'EVT-013',
      'producto': 'Decoracion basica de mesa',
      'categoria': 'Decoracion',
      'descripcion':
          'Manteleria, centros de mesa y montaje basico para eventos sociales.',
      'tipo': 'servicio',
    },
    {
      'codigo': 'EVT-014',
      'producto': 'Parrilla para evento social',
      'categoria': 'Buffets',
      'descripcion':
          'Estacion de parrilla con carnes, guarniciones, salsas y servicio de atencion.',
      'tipo': 'paquete',
    },
  ];
  static const Map<String, double> preciosEventos = {
    'EVT-001': 850.00,
    'EVT-002': 1450.00,
    'EVT-003': 420.00,
    'EVT-004': 360.00,
    'EVT-005': 390.00,
    'EVT-006': 260.00,
    'EVT-007': 520.00,
    'EVT-008': 780.00,
    'EVT-009': 460.00,
    'EVT-010': 18.00,
    'EVT-011': 180.00,
    'EVT-012': 220.00,
    'EVT-013': 300.00,
    'EVT-014': 1100.00,
  };

  @override
  void initState() {
    super.initState();
    controladorAnimacionCarrito = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    animacionCarrito = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.34), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.34, end: 1.0), weight: 45),
    ]).animate(
      CurvedAnimation(
        parent: controladorAnimacionCarrito,
        curve: Curves.easeOutBack,
      ),
    );

    productosEventos = List<Map<String, dynamic>>.from(productosEventosBase);

    if (widget.firebaseDisponible) {
      obtenerProductosEventos();
    } else {
      cargando = false;
      mensajeError = 'Firebase no esta configurado. Se muestran datos locales.';
    }
  }

  @override
  void dispose() {
    controladorBusqueda.dispose();
    controladorAnimacionCarrito.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get productosFiltrados {
    final busqueda = controladorBusqueda.text.trim().toLowerCase();

    return productosEventos.where((producto) {
      final nombre = producto['producto']?.toString().toLowerCase() ?? '';
      final categoria = producto['categoria']?.toString().toLowerCase() ?? '';
      final coincideBusqueda =
          busqueda.isEmpty ||
          nombre.contains(busqueda) ||
          categoria.contains(busqueda);
      final coincideCategoria =
          categoriaSeleccionada == categoriaTodas ||
          categoria == categoriaSeleccionada.toLowerCase();

      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  List<String> get categoriasDisponibles {
    final categorias = <String>[];

    for (final producto in productosEventos) {
      final categoria = producto['categoria']?.toString().trim() ?? '';

      if (categoria.isNotEmpty && !categorias.contains(categoria)) {
        categorias.add(categoria);
      }
    }

    categorias.sort();
    return [categoriaTodas, ...categorias];
  }

  Future<void> obtenerProductosEventos() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('productos_eventos')
              .orderBy('codigo')
              .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          productosEventos = List<Map<String, dynamic>>.from(
            productosEventosBase,
          );
          cargando = false;
          mensajeError =
              'Aun no hay productos para eventos en Firebase. Se muestran datos locales.';
        });
        precargarImagenesProductos(productosEventos);
        return;
      }

      setState(() {
        productosEventos =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        cargando = false;
      });
      precargarImagenesProductos(productosEventos);
    } catch (e) {
      setState(() {
        productosEventos = List<Map<String, dynamic>>.from(
          productosEventosBase,
        );
        cargando = false;
        mensajeError =
            'No se pudo cargar productos para eventos. Se muestran datos locales.';
      });
      precargarImagenesProductos(productosEventos);
    }
  }

  void precargarImagenesProductos(List<Map<String, dynamic>> lista) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      for (final producto in lista.take(12)) {
        final imagen = obtenerImagenProducto(
          producto['codigo']?.toString() ?? '',
          producto['imagen']?.toString() ?? '',
        );

        if (imagen.isNotEmpty) {
          precacheImage(
            ResizeImage.resizeIfNeeded(
              kImagenEventoCache,
              null,
              NetworkImage(imagen),
            ),
            context,
          );
        }
      }
    });
  }

  int get totalProductosCarrito {
    return carrito.values.fold(0, (total, cantidad) => total + cantidad);
  }

  double obtenerPrecioProducto(String codigo) {
    Object? precio;

    for (final producto in productosEventos) {
      if (producto['codigo']?.toString() == codigo) {
        precio = producto['precio'];
        break;
      }
    }

    if (precio is num) {
      return precio.toDouble();
    }

    if (precio is String) {
      return double.tryParse(precio) ?? 0;
    }

    return preciosEventos[codigo] ?? 0;
  }

  String obtenerImagenProducto(String codigo, String urlImagen) {
    final url = urlImagen.trim();

    if (url.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(url);

    if (uri == null || !uri.host.contains('drive.google.com')) {
      return url;
    }

    final idPorQuery = uri.queryParameters['id'];

    if (idPorQuery != null && idPorQuery.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$idPorQuery&sz=w$kDriveThumbnailSize';
    }

    final segmentos = uri.pathSegments;
    final indiceFile = segmentos.indexOf('d');

    if (indiceFile >= 0 && indiceFile + 1 < segmentos.length) {
      final idArchivo = segmentos[indiceFile + 1];
      return 'https://drive.google.com/thumbnail?id=$idArchivo&sz=w$kDriveThumbnailSize';
    }

    return url;
  }

  String formatearPrecio(double precio) {
    return 'S/ ${precio.toStringAsFixed(2)}';
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';

    if (codigo.isEmpty) {
      return;
    }

    setState(() {
      carrito[codigo] = (carrito[codigo] ?? 0) + 1;
    });
    controladorAnimacionCarrito.forward(from: 0);
  }

  void actualizarCantidadCarrito(String codigo, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        carrito.remove(codigo);
      } else {
        carrito[codigo] = nuevaCantidad;
      }
    });
  }

  void abrirCarrito() {
    if (totalProductosCarrito == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todavia no agregaste productos al carrito'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          Widget construirCarrito() {
            return CarritoProductosScreen(
              productos: productosEventos,
              carrito: carrito,
              obtenerImagenProducto: obtenerImagenProducto,
              obtenerPrecioProducto: obtenerPrecioProducto,
              formatearPrecio: formatearPrecio,
              onActualizarCantidad: actualizarCantidadCarrito,
            );
          }

          if (FirebaseAuth.instance.currentUser != null) {
            return construirCarrito();
          }

          return LoginInsumosScreen(
            firebaseDisponible: widget.firebaseDisponible,
            tituloBarra: 'Login de Carrito',
            tituloAcceso: 'Para ingresar al carrito debe iniciar sesión',
            construirDestino: (_) => construirCarrito(),
          );
        },
      ),
    );
  }

  Widget construirIconoCarritoAnimado() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: RepaintBoundary(
          child: Badge(
            isLabelVisible: totalProductosCarrito > 0,
            label: Text(totalProductosCarrito.toString()),
            child: ClipRect(
              child: SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: ScaleTransition(
                    scale: animacionCarrito,
                    child: const Icon(Icons.shopping_cart),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void actualizarProductosEventos() {
    if (widget.firebaseDisponible) {
      obtenerProductosEventos();
    } else {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Productos para eventos actualizados'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  IconData obtenerIconoEvento(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('buffet')) {
      return Icons.room_service;
    }
    if (texto.contains('matrimonio')) {
      return Icons.favorite;
    }
    if (texto.contains('corporativo')) {
      return Icons.business_center;
    }
    if (texto.contains('bocadito')) {
      return Icons.fastfood;
    }
    if (texto.contains('bebida')) {
      return Icons.local_bar;
    }
    if (texto.contains('postre')) {
      return Icons.cake;
    }
    if (texto.contains('graduacion')) {
      return Icons.school;
    }
    if (texto.contains('infantil')) {
      return Icons.child_care;
    }
    if (texto.contains('personal')) {
      return Icons.groups;
    }
    if (texto.contains('implemento')) {
      return Icons.flatware;
    }
    if (texto.contains('decor')) {
      return Icons.celebration;
    }

    return Icons.event;
  }

  Color obtenerColorEvento(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('buffet')) {
      return const Color(0xFFB2552F);
    }
    if (texto.contains('matrimonio')) {
      return const Color(0xFFB14C74);
    }
    if (texto.contains('corporativo')) {
      return const Color(0xFF366FA8);
    }
    if (texto.contains('bocadito')) {
      return const Color(0xFFD07924);
    }
    if (texto.contains('bebida')) {
      return const Color(0xFF287D9A);
    }
    if (texto.contains('postre') || texto.contains('infantil')) {
      return const Color(0xFFC15F92);
    }
    if (texto.contains('graduacion')) {
      return const Color(0xFF6268B3);
    }
    if (texto.contains('personal')) {
      return const Color(0xFF607D8B);
    }
    if (texto.contains('implemento')) {
      return const Color(0xFF6A6A6A);
    }
    if (texto.contains('decor')) {
      return const Color(0xFF7C56A6);
    }

    return Colors.deepOrange;
  }

  Widget construirImagen(String categoria, String urlImagen) {
    final color = ajustarColorTema(context, obtenerColorEvento(categoria));

    return Container(
      width: 86,
      height: 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child:
          urlImagen.isEmpty
              ? Icon(obtenerIconoEvento(categoria), color: color, size: 32)
              : Image.network(
                urlImagen,
                fit: BoxFit.scaleDown,
                cacheWidth: kImagenEventoCache,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    obtenerIconoEvento(categoria),
                    color: color,
                    size: 32,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  );
                },
              ),
    );
  }

  Widget construirPestanasCategorias() {
    final categorias = categoriasDisponibles;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final seleccionada = categoria == categoriaSeleccionada;
          final color =
              categoria == categoriaTodas
                  ? const Color(0xFFE86A33)
                  : ajustarColorTema(context, obtenerColorEvento(categoria));

          return ChoiceChip(
            selected: seleccionada,
            showCheckmark: false,
            avatar: Icon(
              categoria == categoriaTodas
                  ? Icons.grid_view
                  : obtenerIconoEvento(categoria),
              size: 18,
              color: seleccionada ? Colors.white : color,
            ),
            label: Text(categoria),
            labelStyle: TextStyle(
              color: seleccionada ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
            selectedColor: color,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: color.withValues(alpha: 0.45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            onSelected: (_) {
              setState(() {
                categoriaSeleccionada = categoria;
              });
            },
          );
        },
      ),
    );
  }

  Widget construirTarjetaProducto(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';
    final nombre = producto['producto']?.toString() ?? 'Sin nombre';
    final categoria = producto['categoria']?.toString() ?? 'Sin categoria';
    final descripcion = producto['descripcion']?.toString() ?? '';
    final tipo =
        producto['tipo']?.toString() ?? producto['unidad']?.toString() ?? '';
    final imagen = obtenerImagenProducto(
      codigo,
      producto['imagen']?.toString() ?? '',
    );
    final precio = obtenerPrecioProducto(codigo);
    final cantidadCarrito = carrito[codigo] ?? 0;
    final colorCategoria = ajustarColorTema(
      context,
      obtenerColorEvento(categoria),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorCategoria.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            construirImagen(categoria, imagen),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    categoria,
                    style: TextStyle(
                      color: colorCategoria,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(descripcion, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tipo: $tipo',
                          style: TextStyle(
                            color: colorTextoSecundario(context),
                          ),
                        ),
                      ),
                      Text(
                        formatearPrecio(precio),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => agregarAlCarrito(producto),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorCategoria,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (cantidadCarrito > 0) ...[
                        const SizedBox(width: 10),
                        Chip(
                          label: Text('x$cantidadCarrito'),
                          backgroundColor: colorCategoria.withValues(
                            alpha: 0.13,
                          ),
                          labelStyle: TextStyle(
                            color: colorCategoria,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide(
                            color: colorCategoria.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirContenido() {
    final productos = productosFiltrados;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            controller: controladorBusqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar producto para evento',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  controladorBusqueda.text.isEmpty
                      ? null
                      : IconButton(
                        onPressed: () {
                          controladorBusqueda.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFFC7A6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFFC7A6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE86A33),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        construirPestanasCategorias(),
        const SizedBox(height: 6),
        if (cargando)
          const Padding(
            padding: EdgeInsets.only(top: 22),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (mensajeError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Text(
              mensajeError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ajustarColorTema(context, Colors.deepOrange),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (productos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                'No se encontraron productos',
                style: TextStyle(fontSize: 17),
              ),
            ),
          )
        else
          ...productos.map(construirTarjetaProducto),
      ],
    );
  }

  Widget construirContenidoActual() {
    if (pestanaActual == 2) {
      return UbicacionEmpresaView(
        onAbrirRuta: () => abrirRutaGoogleMaps(context),
      );
    }

    return construirContenido();
  }

  void cambiarPestanaInferior(int indice) {
    if (indice == 1) {
      abrirCarrito();
      return;
    }

    setState(() {
      pestanaActual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE86A33),
        foregroundColor: Colors.white,
        title: Text(
          pestanaActual == 2 ? 'Ubicación' : 'Productos para Eventos',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          construirBotonCuenta(
            context,
            firebaseDisponible: widget.firebaseDisponible,
          ),
          construirBotonModoTema(context),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: construirContenidoActual(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pestanaActual,
        onDestinationSelected: cambiarPestanaInferior,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: totalProductosCarrito > 0,
              label: Text(totalProductosCarrito.toString()),
              child: ScaleTransition(
                scale: animacionCarrito,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            selectedIcon: ScaleTransition(
              scale: animacionCarrito,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
        ],
      ),
    );
  }
}

class CarritoProductosScreen extends StatefulWidget {
  const CarritoProductosScreen({
    super.key,
    required this.productos,
    required this.carrito,
    required this.obtenerImagenProducto,
    required this.obtenerPrecioProducto,
    required this.formatearPrecio,
    required this.onActualizarCantidad,
  });

  final List<Map<String, dynamic>> productos;
  final Map<String, int> carrito;
  final String Function(String codigo, String urlImagen) obtenerImagenProducto;
  final double Function(String codigo) obtenerPrecioProducto;
  final String Function(double precio) formatearPrecio;
  final void Function(String codigo, int cantidad) onActualizarCantidad;

  @override
  State<CarritoProductosScreen> createState() => _CarritoProductosScreenState();
}

class _CarritoProductosScreenState extends State<CarritoProductosScreen> {
  static const MethodChannel canalDelivery = MethodChannel(
    'inventario_catering/delivery',
  );

  List<Map<String, dynamic>> get productosEnCarrito {
    return widget.productos.where((producto) {
      final codigo = producto['codigo']?.toString() ?? '';
      return (widget.carrito[codigo] ?? 0) > 0;
    }).toList();
  }

  double get totalPagar {
    return productosEnCarrito.fold(0.0, (total, producto) {
      final codigo = producto['codigo']?.toString() ?? '';
      final cantidad = widget.carrito[codigo] ?? 0;
      final precio = widget.obtenerPrecioProducto(codigo);

      return total + (precio * cantidad);
    });
  }

  void cambiarCantidad(String codigo, int cantidad) {
    widget.onActualizarCantidad(codigo, cantidad);
    setState(() {});
  }

  void pagar() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.82, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, escala, child) {
            return Transform.scale(scale: escala, child: child);
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 560),
                  curve: Curves.elasticOut,
                  builder: (context, valor, child) {
                    final opacidad = valor.clamp(0.0, 1.0);

                    return Opacity(
                      opacity: opacidad,
                      child: Transform.scale(scale: valor, child: child),
                    );
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Compra realizada',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pedido registrado con exito',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorTextoSecundario(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepOrange.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total pagado',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        widget.formatearPrecio(totalPagar),
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.done),
                  label: const Text('Aceptar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> abrirDelivery() async {
    try {
      await canalDelivery.invokeMethod('openDeliveryMap');
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }

      final mensaje =
          e.code == 'PERMISSION_DENIED'
              ? 'Permiso de ubicación denegado'
              : 'No se pudo abrir Google Maps';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
      );
    }
  }

  IconData obtenerIconoCarrito(String categoria) {
    final texto = categoria.toLowerCase();

    if (texto.contains('buffet') || texto.contains('matrimonio')) {
      return Icons.room_service;
    }
    if (texto.contains('bocadito')) {
      return Icons.fastfood;
    }
    if (texto.contains('bebida')) {
      return Icons.local_bar;
    }
    if (texto.contains('postre')) {
      return Icons.cake;
    }
    if (texto.contains('panader') || texto.contains('base')) {
      return Icons.bakery_dining;
    }
    if (texto.contains('verdura') || texto.contains('hortaliza')) {
      return Icons.eco;
    }
    if (texto.contains('fruta')) {
      return Icons.spa;
    }
    if (texto.contains('limpieza')) {
      return Icons.cleaning_services;
    }

    return Icons.inventory_2;
  }

  Widget construirImagen(String categoria, String urlImagen) {
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child:
          urlImagen.isEmpty
              ? Icon(obtenerIconoCarrito(categoria), color: Colors.deepOrange)
              : Image.network(
                urlImagen,
                fit: BoxFit.scaleDown,
                cacheWidth: kImagenCarritoCache,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    obtenerIconoCarrito(categoria),
                    color: Colors.deepOrange,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
    );
  }

  Widget construirItemCarrito(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';
    final nombre = producto['producto']?.toString() ?? 'Sin nombre';
    final categoria = producto['categoria']?.toString() ?? 'Sin categoria';
    final imagen = widget.obtenerImagenProducto(
      codigo,
      producto['imagen']?.toString() ?? '',
    );
    final cantidad = widget.carrito[codigo] ?? 0;
    final precio = widget.obtenerPrecioProducto(codigo);
    final subtotal = precio * cantidad;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            construirImagen(categoria, imagen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoria,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Precio: ${widget.formatearPrecio(precio)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${widget.formatearPrecio(subtotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => cambiarCantidad(codigo, cantidad - 1),
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          cantidad.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => cambiarCantidad(codigo, cantidad + 1),
                        icon: const Icon(Icons.add),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => cambiarCantidad(codigo, 0),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirContenido() {
    final productos = productosEnCarrito;

    if (productos.isEmpty) {
      return const Center(
        child: Text(
          'Todavia no agregaste productos',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: productos.map(construirItemCarrito).toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: esModoOscuro(context) ? 0.3 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total a pagar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      widget.formatearPrecio(totalPagar),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: pagar,
                        icon: const Icon(Icons.payments),
                        label: const Text('Pagar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: abrirDelivery,
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text('Delivery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Productos'),
        centerTitle: true,
      ),
      body: construirContenido(),
    );
  }
}
