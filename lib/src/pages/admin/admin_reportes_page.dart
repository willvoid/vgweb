import 'package:flutter/material.dart';
import 'package:myapp/src/model/dao/reporte_productos_dao.dart';
import 'package:myapp/src/services/reporte_pdf_service.dart';

class AdminReportesPage extends StatefulWidget {
  const AdminReportesPage({Key? key}) : super(key: key);

  @override
  State<AdminReportesPage> createState() => _AdminReportesPageState();
}

class _AdminReportesPageState extends State<AdminReportesPage> {
  final ReporteProductosDao _reporteDao = ReporteProductosDao();
  final ReportePdfService _pdfService = ReportePdfService();

  List<Map<String, dynamic>> _datosReporte = [];
  bool _isLoadingData = true;
  bool _isGeneratingPdf = false;
  String _errorMessage = '';

  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = '';
    });

    try {
      final datos = await _reporteDao.obtenerProductosPorCategoria();
      setState(() {
        _datosReporte = datos;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos para el reporte: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _generarYDescargarPdf() async {
    if (_datosReporte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles para generar el reporte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final bytes = await _pdfService.generarPdf(_datosReporte);
      _pdfService.descargarPdf(
        bytes,
        'reporte_productos_por_categoria_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte PDF descargado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar los datos por categoría para la vista previa en pantalla
    final Map<String, List<Map<String, dynamic>>> categoriasAgrupadas = {};
    for (final row in _datosReporte) {
      final catNombre = row['categoria_nombre'] as String? ?? 'Sin categoría';
      categoriasAgrupadas.putIfAbsent(catNombre, () => []);
      categoriasAgrupadas[catNombre]!.add(row);
    }

    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportes del Sistema',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 33, 33, 33),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generación de documentos PDF y catálogos',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (_isLoadingData || _isGeneratingPdf)
                      ? null
                      : _generarYDescargarPdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, size: 20),
                  label: Text(_isGeneratingPdf
                      ? 'Generando PDF...'
                      : 'Descargar PDF de Catálogo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color.fromARGB(255, 238, 238, 238)),

          // Contenido principal / Vista Previa
          Expanded(
            child: _isLoadingData
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarDatos,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _datosReporte.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.insert_drive_file_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay productos registrados para el reporte',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Banner informativo del reporte
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 238, 238, 238)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.info_outline,
                                          color: _primaryColor),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Vista Previa del Catálogo',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color.fromARGB(
                                                  255, 33, 33, 33),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Se agrupan ${_datosReporte.length} productos en ${categoriasAgrupadas.keys.length} categorías. El documento generado incluirá el logotipo de la empresa, detalles, precios y fotos.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Listado de Categorías y sus productos en vista previa
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: categoriasAgrupadas.keys.length,
                                  itemBuilder: (context, index) {
                                    final catNombre = categoriasAgrupadas.keys
                                        .elementAt(index);
                                    final productos =
                                        categoriasAgrupadas[catNombre]!;

                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: ExpansionTile(
                                        title: Text(
                                          catNombre.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _primaryColor,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${productos.length} producto(s) en esta categoría',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500]),
                                        ),
                                        childrenPadding: const EdgeInsets.all(0),
                                        children: [
                                          const Divider(
                                              height: 1, color: Colors.grey),
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: productos.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                                    height: 1,
                                                    color: Color.fromARGB(
                                                        255, 245, 245, 245)),
                                            itemBuilder: (context, pIndex) {
                                              final prod = productos[pIndex];
                                              final urlImg =
                                                  prod['producto_url_img']
                                                      as String?;
                                              final precio =
                                                  prod['producto_precio']
                                                          as int? ??
                                                      0;
                                              final stock =
                                                  prod['producto_stock']
                                                      as int?;

                                              // Formatear precio
                                              final precioFormateado = precio
                                                  .toString()
                                                  .replaceAllMapped(
                                                    RegExp(
                                                        r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                    (Match m) => '${m[1]}.',
                                                  );

                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                leading: urlImg != null &&
                                                        urlImg.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        child: Image.network(
                                                          urlImg,
                                                          width: 45,
                                                          height: 45,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __,
                                                                  ___) =>
                                                              _buildPlaceholderImg(),
                                                        ),
                                                      )
                                                    : _buildPlaceholderImg(),
                                                title: Text(
                                                  prod['producto_nombre']
                                                          as String? ??
                                                      'Sin nombre',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14),
                                                ),
                                                subtitle: Text(
                                                  prod['producto_descripcion']
                                                          as String? ??
                                                      'Sin descripción',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500]),
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Gs. $precioFormateado',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: _primaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      stock != null
                                                          ? 'Stock: $stock'
                                                          : 'Sin stock',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: stock != null &&
                                                                stock > 0
                                                            ? Colors.green[700]
                                                            : Colors.red[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImg() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.image, color: Colors.grey[400], size: 20),
    );
  }
}
