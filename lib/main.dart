import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return MaterialApp(
      title: 'Massha’s Catering',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: InicioScreen(firebaseDisponible: firebaseDisponible),
    );
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
      backgroundColor: const Color(0xFFFFF7F0),
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
              const Text(
                'Empresa de catering',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
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
                      LoginInsumosScreen(
                        firebaseDisponible: firebaseDisponible,
                      ),
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
                    () =>
                        abrirPantalla(context, const ProductosEventosScreen()),
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
  const LoginInsumosScreen({super.key, required this.firebaseDisponible});

  final bool firebaseDisponible;

  @override
  State<LoginInsumosScreen> createState() => _LoginInsumosScreenState();
}

class _LoginInsumosScreenState extends State<LoginInsumosScreen> {
  final TextEditingController controladorCorreo = TextEditingController();
  final TextEditingController controladorPassword = TextEditingController();
  bool cargando = false;
  bool ocultarPassword = true;
  String? mensajeError;

  @override
  void dispose() {
    controladorCorreo.dispose();
    controladorPassword.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final correo = controladorCorreo.text.trim();
    final password = controladorPassword.text.trim();

    if (!widget.firebaseDisponible) {
      setState(() {
        mensajeError = 'Firebase no esta configurado para Android.';
      });
      return;
    }

    if (correo.isEmpty || password.isEmpty) {
      setState(() {
        mensajeError = 'Ingresa correo y contrasena.';
      });
      return;
    }

    setState(() {
      cargando = true;
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return InventarioScreen(
              firebaseDisponible: widget.firebaseDisponible,
            );
          },
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login de Insumos'), centerTitle: true),
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
            const Text(
              'Acceso a Insumos de la Empresa',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  cargando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.login),
              label: Text(cargando ? 'Ingresando...' : 'Ingresar'),
              style: FilledButton.styleFrom(
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
  List<Map<String, dynamic>> productos = [];
  final TextEditingController controladorBusqueda = TextEditingController();
  final Map<String, int> carrito = {};
  late final AnimationController controladorAnimacionCarrito;
  late final Animation<double> animacionCarrito;
  bool cargando = true;
  String? mensajeError;

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
    'CONG-001': 10.50,
    'CONG-002': 9.50,
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

    if (busqueda.isEmpty) {
      return productos;
    }

    return productos.where((producto) {
      final nombre = producto['producto']?.toString().toLowerCase() ?? '';
      final categoria = producto['categoria']?.toString().toLowerCase() ?? '';

      return nombre.contains(busqueda) || categoria.contains(busqueda);
    }).toList();
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CarritoProductosScreen(
            productos: productos,
            carrito: carrito,
            obtenerImagenProducto: obtenerImagenProducto,
            obtenerPrecioProducto: obtenerPrecioProducto,
            formatearPrecio: formatearPrecio,
            onActualizarCantidad: actualizarCantidadCarrito,
          );
        },
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
    if (texto.contains('panader') || texto.contains('base')) {
      return const Color(0xFF9A6A2D);
    }
    if (texto.contains('lact')) {
      return const Color(0xFF317B9B);
    }
    if (texto.contains('descartable')) {
      return const Color(0xFF6A6A6A);
    }
    if (texto.contains('limpieza')) {
      return const Color(0xFF3E7C70);
    }

    return Colors.deepOrange;
  }

  Widget construirImagen(String nombre, String categoria, String urlImagen) {
    final color = obtenerColorCategoria(categoria);

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
                fit: BoxFit.cover,
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
    return urlImagen;
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
    final Color colorCategoria = obtenerColorCategoria(categoria);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 4,
      color: Colors.white,
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
                      color: Colors.grey.shade700,
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
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ubicación: $ubicacion',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proveedor: $proveedor',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.orange.shade100),
                ),
              ),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE86A33),
        foregroundColor: Colors.white,
        title: const Text(
          'Insumos de la Empresa',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: abrirCarrito,
            icon: Badge(
              isLabelVisible: totalProductosCarrito > 0,
              label: Text(totalProductosCarrito.toString()),
              child: ScaleTransition(
                scale: animacionCarrito,
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
          IconButton(
            onPressed: obtenerProductos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF7F0),
      body: construirContenido(),
    );
  }
}

class ProductosEventosScreen extends StatefulWidget {
  const ProductosEventosScreen({super.key});

  @override
  State<ProductosEventosScreen> createState() => _ProductosEventosScreenState();
}

class _ProductosEventosScreenState extends State<ProductosEventosScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController controladorBusqueda = TextEditingController();
  final Map<String, int> carrito = {};
  late final AnimationController controladorAnimacionCarrito;
  late final Animation<double> animacionCarrito;

  static const List<Map<String, dynamic>> productosEventos = [
    {
      'codigo': 'EVT-001',
      'producto': 'Buffet criollo para eventos',
      'categoria': 'Buffets',
      'descripcion':
          'Servicio de comida criolla para matrimonios, reuniones familiares y celebraciones.',
      'unidad': 'paquete',
    },
    {
      'codigo': 'EVT-002',
      'producto': 'Buffet marino premium',
      'categoria': 'Buffets',
      'descripcion':
          'Propuesta marina para recepciones, almuerzos especiales y eventos corporativos.',
      'unidad': 'paquete',
    },
    {
      'codigo': 'EVT-003',
      'producto': 'Cena para matrimonio',
      'categoria': 'Matrimonios',
      'descripcion':
          'Cena formal con entrada, fondo, bebida y postre para recepciones de boda.',
      'unidad': 'servicio',
    },
    {
      'codigo': 'EVT-004',
      'producto': 'Coffee break empresarial',
      'categoria': 'Corporativo',
      'descripcion':
          'Bebidas calientes, jugos, bocaditos y dulces para reuniones o capacitaciones.',
      'unidad': 'servicio',
    },
    {
      'codigo': 'EVT-005',
      'producto': 'Mesa de bocaditos salados',
      'categoria': 'Bocaditos',
      'descripcion':
          'Mini sandwiches, empanaditas, tequeños y piqueos para recepciones sociales.',
      'unidad': 'mesa',
    },
    {
      'codigo': 'EVT-006',
      'producto': 'Mesa de bocaditos dulces',
      'categoria': 'Bocaditos',
      'descripcion':
          'Trufas, alfajores, cupcakes, mini tartas y dulces decorativos para eventos.',
      'unidad': 'mesa',
    },
    {
      'codigo': 'EVT-007',
      'producto': 'Pack de bebidas para fiesta',
      'categoria': 'Bebidas',
      'descripcion':
          'Agua, gaseosas, jugos y hielo para matrimonios, graduaciones y cumpleaños.',
      'unidad': 'pack',
    },
    {
      'codigo': 'EVT-008',
      'producto': 'Mesa de postres decorada',
      'categoria': 'Postres',
      'descripcion':
          'Postres individuales con presentacion para mesa principal o zona dulce.',
      'unidad': 'mesa',
    },
    {
      'codigo': 'EVT-009',
      'producto': 'Menú para graduación',
      'categoria': 'Graduaciones',
      'descripcion':
          'Menu completo para celebraciones de promocion, egresados y ceremonias.',
      'unidad': 'paquete',
    },
    {
      'codigo': 'EVT-010',
      'producto': 'Menú infantil para eventos',
      'categoria': 'Infantil',
      'descripcion':
          'Mini hamburguesas, nuggets, papas, jugos y dulces para eventos infantiles.',
      'unidad': 'paquete',
    },
    {
      'codigo': 'EVT-011',
      'producto': 'Box lunch ejecutivo',
      'categoria': 'Corporativo',
      'descripcion':
          'Caja individual con sandwich, fruta, bebida y snack para reuniones o viajes.',
      'unidad': 'unidad',
    },
    {
      'codigo': 'EVT-012',
      'producto': 'Servicio de mozos',
      'categoria': 'Personal',
      'descripcion':
          'Personal de atencion para servicio en mesa, buffet, bebidas y recepcion.',
      'unidad': 'servicio',
    },
    {
      'codigo': 'EVT-013',
      'producto': 'Alquiler de vajilla',
      'categoria': 'Implementos',
      'descripcion':
          'Platos, vasos, cubiertos y copas para recepciones formales o buffet.',
      'unidad': 'pack',
    },
    {
      'codigo': 'EVT-014',
      'producto': 'Decoración básica de mesa',
      'categoria': 'Decoración',
      'descripcion':
          'Manteleria, centros de mesa y montaje basico para eventos sociales.',
      'unidad': 'servicio',
    },
    {
      'codigo': 'EVT-015',
      'producto': 'Parrilla para evento social',
      'categoria': 'Buffets',
      'descripcion':
          'Estacion de parrilla con carnes, guarniciones, salsas y servicio de atencion.',
      'unidad': 'paquete',
    },
  ];

  static const Map<String, double> preciosEventos = {
    'EVT-001': 850.00,
    'EVT-002': 980.00,
    'EVT-003': 1450.00,
    'EVT-004': 420.00,
    'EVT-005': 360.00,
    'EVT-006': 390.00,
    'EVT-007': 260.00,
    'EVT-008': 520.00,
    'EVT-009': 780.00,
    'EVT-010': 460.00,
    'EVT-011': 18.00,
    'EVT-012': 180.00,
    'EVT-013': 220.00,
    'EVT-014': 300.00,
    'EVT-015': 1100.00,
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
  }

  @override
  void dispose() {
    controladorBusqueda.dispose();
    controladorAnimacionCarrito.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get productosFiltrados {
    final busqueda = controladorBusqueda.text.trim().toLowerCase();

    if (busqueda.isEmpty) {
      return productosEventos;
    }

    return productosEventos.where((producto) {
      final nombre = producto['producto']?.toString().toLowerCase() ?? '';
      final categoria = producto['categoria']?.toString().toLowerCase() ?? '';

      return nombre.contains(busqueda) || categoria.contains(busqueda);
    }).toList();
  }

  int get totalProductosCarrito {
    return carrito.values.fold(0, (total, cantidad) => total + cantidad);
  }

  double obtenerPrecioProducto(String codigo) {
    return preciosEventos[codigo] ?? 0;
  }

  String obtenerImagenProducto(String codigo, String urlImagen) {
    return urlImagen;
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CarritoProductosScreen(
            productos: productosEventos,
            carrito: carrito,
            obtenerImagenProducto: obtenerImagenProducto,
            obtenerPrecioProducto: obtenerPrecioProducto,
            formatearPrecio: formatearPrecio,
            onActualizarCantidad: actualizarCantidadCarrito,
          );
        },
      ),
    );
  }

  void actualizarProductosEventos() {
    setState(() {});
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

  Widget construirImagen(String categoria) {
    final color = obtenerColorEvento(categoria);

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(obtenerIconoEvento(categoria), color: color, size: 32),
    );
  }

  Widget construirTarjetaProducto(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';
    final nombre = producto['producto']?.toString() ?? 'Sin nombre';
    final categoria = producto['categoria']?.toString() ?? 'Sin categoria';
    final descripcion = producto['descripcion']?.toString() ?? '';
    final unidad = producto['unidad']?.toString() ?? '';
    final precio = obtenerPrecioProducto(codigo);
    final cantidadCarrito = carrito[codigo] ?? 0;
    final colorCategoria = obtenerColorEvento(categoria);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorCategoria.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            construirImagen(categoria),
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
                          'Unidad: $unidad',
                          style: TextStyle(color: Colors.grey.shade700),
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
              fillColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE86A33),
        foregroundColor: Colors.white,
        title: const Text(
          'Productos para Eventos',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: abrirCarrito,
            icon: Badge(
              isLabelVisible: totalProductosCarrito > 0,
              label: Text(totalProductosCarrito.toString()),
              child: ScaleTransition(
                scale: animacionCarrito,
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
          IconButton(
            onPressed: actualizarProductosEventos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF7F0),
      body: construirContenido(),
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
        return AlertDialog(
          content: const Text(
            'Compra realizada con éxito',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
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

  Widget construirImagen(String categoria) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child: Icon(obtenerIconoCarrito(categoria), color: Colors.deepOrange),
    );
  }

  Widget construirItemCarrito(Map<String, dynamic> producto) {
    final codigo = producto['codigo']?.toString() ?? '';
    final nombre = producto['producto']?.toString() ?? 'Sin nombre';
    final categoria = producto['categoria']?.toString() ?? 'Sin categoria';
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
            construirImagen(categoria),
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
