import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/imagen.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/model/dao/imagencrudimpl.dart';
import 'package:myapp/src/services/storage_service.dart';
import 'package:myapp/src/widgets/image_picker_widget.dart';

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({Key? key}) : super(key: key);
  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final Productocrudimpl _productoCrud = Productocrudimpl();
  final CategoriaCrud _categoriaCrud = CategoriaCrud();
  final ImagenCrud _imagenCrud = ImagenCrud();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = List.from(_productos);
      } else {
        _productosFiltrados = _productos
            .where((p) =>
                p.nombre.toLowerCase().contains(query) ||
                p.descripcion.toLowerCase().contains(query) ||
                _getNombreCategoria(p.categoria).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final productos = await _productoCrud.leerProductos();
    final categorias = await _categoriaCrud.leerCategorias();
    setState(() {
      _productos = productos;
      _productosFiltrados = List.from(productos);
      _categorias = categorias;
      _isLoading = false;
    });
  }

  String _getNombreCategoria(int catId) {
    final cat = _categorias.where((c) => c.id == catId).toList();
    return cat.isNotEmpty ? cat.first.nombre : 'Sin categoría';
  }

  void _mostrarFormulario({Producto? producto}) {
    final isEditing = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: producto?.descripcion ?? '');
    final desc2Ctrl = TextEditingController(text: producto?.desc2 ?? '');
    final precioCtrl = TextEditingController(text: producto?.precio.toString() ?? '');
    final cuotasCtrl = TextEditingController(text: producto?.cuotas.toString() ?? '');
    final stockCtrl = TextEditingController(text: producto?.stock?.toString() ?? '0');
    int? selectedCategoriaId = producto?.categoria;
    int recomendado = producto?.recomendado ?? 1;
    String? imgUrl = producto?.img;
    Uint8List? nuevaImgBytes;
    String? nuevaImgNombre;
    bool isSubmitting = false;

    List<Imagen> imagenesExistentes = [];
    List<_NuevaImagen> nuevasImagenes = [];
    bool loadingImagenes = isEditing;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (isEditing && loadingImagenes) {
              _imagenCrud.leerImagenesPorProducto(producto!.id!).then((imgs) {
                setDialogState(() {
                  imagenesExistentes = imgs;
                  loadingImagenes = false;
                });
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 600,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(isEditing ? Icons.edit : Icons.add_circle, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            isEditing ? 'Editar Producto' : 'Nuevo Producto',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(ctx).pop()),
                        ],
                      ),
                    ),
                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field(nombreCtrl, 'Nombre', 'Ej: Mesa de comedor', Icons.label),
                            SizedBox(height: 14),
                            _field(descripcionCtrl, 'Descripción', 'Descripción corta', Icons.description, maxLines: 2),
                            SizedBox(height: 14),
                            _field(desc2Ctrl, 'Descripción detallada', 'Descripción larga', Icons.article, maxLines: 3),
                            SizedBox(height: 14),
                            Row(children: [
                              Expanded(child: _field(precioCtrl, 'Precio', '0', Icons.attach_money, isNumber: true)),
                              SizedBox(width: 12),
                              Expanded(child: _field(cuotasCtrl, 'Cuotas', '0', Icons.credit_card, isNumber: true)),
                              SizedBox(width: 12),
                              Expanded(child: _field(stockCtrl, 'Stock', '0', Icons.inventory, isNumber: true)),
                            ]),
                            SizedBox(height: 14),
                            // Categoría
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: selectedCategoriaId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryColor, width: 2)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    isDense: true,
                                  ),
                                  hint: Text('Seleccionar categoría'),
                                  items: _categorias.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.nombre))).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCategoriaId = val),
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            SwitchListTile(
                              title: Text('Recomendado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text('Aparece en la sección de recomendados', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              value: recomendado == 1,
                              onChanged: (val) => setDialogState(() => recomendado = val ? 1 : 0),
                              activeColor: _primaryColor,
                              contentPadding: EdgeInsets.zero,
                            ),
                            Divider(height: 24),
                            Text('Imagen principal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                            SizedBox(height: 8),
                            ImagePickerWidget(
                              label: 'Imagen del producto',
                              currentImageUrl: nuevaImgBytes != null ? null : imgUrl,
                              onImageSelected: (bytes, name) {
                                setDialogState(() { nuevaImgBytes = bytes; nuevaImgNombre = name; });
                              },
                            ),
                            if (nuevaImgBytes != null)
                              Container(
                                width: double.infinity, height: 120, margin: EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green, width: 2)),
                                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(nuevaImgBytes!, fit: BoxFit.cover)),
                              ),
                            Divider(height: 24),
                            Text('Imágenes adicionales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                            SizedBox(height: 8),
                            if (loadingImagenes)
                              Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            if (imagenesExistentes.isNotEmpty)
                              Wrap(spacing: 8, runSpacing: 8, children: imagenesExistentes.map((img) => Stack(children: [
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img.urlImg, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image)))),
                                Positioned(top: 2, right: 2, child: GestureDetector(
                                  onTap: () async { await _imagenCrud.eliminarImagen(img.id!); setDialogState(() => imagenesExistentes.removeWhere((i) => i.id == img.id)); },
                                  child: Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)),
                                )),
                              ])).toList()),
                            if (nuevasImagenes.isNotEmpty)
                              Padding(padding: EdgeInsets.only(top: 8), child: Wrap(spacing: 8, runSpacing: 8, children: nuevasImagenes.asMap().entries.map((entry) => Stack(children: [
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(entry.value.bytes, width: 80, height: 80, fit: BoxFit.cover)),
                                Positioned(top: 2, right: 2, child: GestureDetector(
                                  onTap: () => setDialogState(() => nuevasImagenes.removeAt(entry.key)),
                                  child: Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)),
                                )),
                              ])).toList())),
                            SizedBox(height: 8),
                            ImagePickerWidget(label: 'Agregar imagen adicional', onImageSelected: (bytes, name) {
                              setDialogState(() => nuevasImagenes.add(_NuevaImagen(bytes: bytes, nombre: name)));
                            }),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(), child: Text('Cancelar', style: TextStyle(color: Colors.grey[600]))),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSubmitting ? null : () async {
                              if (nombreCtrl.text.trim().isEmpty || selectedCategoriaId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Nombre y categoría son requeridos'), backgroundColor: Colors.red));
                                return;
                              }
                              setDialogState(() => isSubmitting = true);
                              if (nuevaImgBytes != null && nuevaImgNombre != null) {
                                final url = await _storageService.subirImagen(bucketName: 'muebles', bytes: nuevaImgBytes!, fileName: nuevaImgNombre!);
                                if (url != null) imgUrl = url;
                              }
                              final prod = Producto(id: producto?.id, nombre: nombreCtrl.text.trim(), descripcion: descripcionCtrl.text.trim(), desc2: desc2Ctrl.text.trim(), precio: int.tryParse(precioCtrl.text) ?? 0, cuotas: int.tryParse(cuotasCtrl.text) ?? 0, stock: int.tryParse(stockCtrl.text) ?? 0, categoria: selectedCategoriaId!, img: imgUrl ?? '', recomendado: recomendado);
                              bool success; int? productoId = producto?.id;
                              if (isEditing) { success = await _productoCrud.actualizarProducto(prod); }
                              else { final result = await _productoCrud.crearProducto(prod); success = result != null; productoId = result?.id; }
                              if (success && productoId != null && nuevasImagenes.isNotEmpty) {
                                for (final ni in nuevasImagenes) {
                                  final url = await _storageService.subirImagen(bucketName: 'muebles', bytes: ni.bytes, fileName: ni.nombre);
                                  if (url != null) { await _imagenCrud.crearImagen(Imagen(urlImg: url, idProducto: productoId)); }
                                }
                              }
                              setDialogState(() => isSubmitting = false);
                              if (success) {
                                Navigator.of(ctx).pop(); _cargarDatos();
                                if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(isEditing ? 'Producto actualizado' : 'Producto creado'), backgroundColor: Colors.green));
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
                              }
                            },
                            icon: isSubmitting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Icon(isEditing ? Icons.save : Icons.add, size: 18),
                            label: Text(isEditing ? 'Guardar' : 'Crear'),
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 6),
        TextField(
          controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: _primaryColor, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con buscador
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestión de Productos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                          SizedBox(height: 4),
                          Text('${_productosFiltrados.length} de ${_productos.length} productos', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarFormulario(),
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Nuevo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor, foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto o categoría...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: _primaryColor, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]), onPressed: () => _searchController.clear())
                        : null,
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), isDense: true,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Lista con acordeón
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
                : _productosFiltrados.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(_searchController.text.isNotEmpty ? 'Sin resultados' : 'No hay productos', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                      ]))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) => _buildProductoCard(_productosFiltrados[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Producto p) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: p.img.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(p.img, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImg()),
              )
            : _placeholderImg(),
        title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey[900])),
        subtitle: Row(
          children: [
            Text(_getNombreCategoria(p.categoria), style: TextStyle(fontSize: 12, color: _primaryColor)),
            SizedBox(width: 8),
            if (p.esRecomendado()) Icon(Icons.star, color: Colors.amber, size: 14),
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: 12),
          // Info en grid responsive
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _infoChip(Icons.tag, 'ID: ${p.id}'),
              _infoChip(Icons.attach_money, '${p.precio} Gs.'),
              _infoChip(Icons.credit_card, '${p.cuotas} cuotas'),
              _infoChip(Icons.inventory, 'Stock: ${p.stock ?? 0}'),
              _infoChip(Icons.star, p.esRecomendado() ? 'Recomendado' : 'No recomendado'),
            ],
          ),
          if (p.descripcion.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(p.descripcion, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarFormulario(producto: p),
              icon: Icon(Icons.edit, size: 16),
              label: Text('Editar producto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey[500]),
      SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
    ]);
  }

  Widget _placeholderImg() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.image, color: Colors.grey[400], size: 22),
    );
  }
}

class _NuevaImagen {
  final Uint8List bytes;
  final String nombre;
  _NuevaImagen({required this.bytes, required this.nombre});
}
