import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Servicio para generar y descargar reportes PDF
class ReportePdfService {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF581717);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFF581717);
  static const PdfColor _headerText = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _tableBorder = PdfColor.fromInt(0xFFDDDDDD);
  static const PdfColor _altRowBg = PdfColor.fromInt(0xFFF9F9F9);

  /// Genera el PDF a partir de los datos de la vista
  Future<Uint8List> generarPdf(List<Map<String, dynamic>> datos) async {
    final pdf = pw.Document(
      title: 'VG Mueblería - Catálogo de Productos',
      author: 'VG Mueblería',
      creator: 'VG Mueblería App',
    );

    // Cargar logo desde assets
    final logoData = await rootBundle.load('assets/images/logo.jpg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Agrupar datos por categoría
    final Map<String, List<Map<String, dynamic>>> categorias = {};
    for (final row in datos) {
      final catNombre = row['categoria_nombre'] as String? ?? 'Sin categoría';
      categorias.putIfAbsent(catNombre, () => []);
      categorias[catNombre]!.add(row);
    }

    // Pre-cargar imágenes de productos
    final Map<String, pw.MemoryImage> imagenesCache = {};
    for (final row in datos) {
      final urlImg = row['producto_url_img'] as String?;
      if (urlImg != null && urlImg.isNotEmpty && !imagenesCache.containsKey(urlImg)) {
        try {
          final response = await http.get(Uri.parse(urlImg));
          if (response.statusCode == 200) {
            imagenesCache[urlImg] = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          // Si falla la descarga, simplemente no se incluye la imagen
          print('⚠️ No se pudo descargar imagen: $urlImg');
        }
      }
    }

    // Fecha del reporte
    final fechaReporte = _formatearFecha(DateTime.now());

    // Construir páginas del PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(logoImage, fechaReporte, context),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final List<pw.Widget> widgets = [];

          // Resumen general
          widgets.add(_buildResumen(datos, categorias.length));
          widgets.add(pw.SizedBox(height: 20));

          // Por cada categoría
          for (final entry in categorias.entries) {
            widgets.add(_buildCategoriaHeader(entry.key, entry.value.length));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildProductosTable(entry.value, imagenesCache));
            widgets.add(pw.SizedBox(height: 20));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  /// Header del PDF con logo y título
  pw.Widget _buildHeader(pw.MemoryImage logo, String fecha, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Image(logo, width: 50, height: 50, fit: pw.BoxFit.cover),
          ),
          pw.SizedBox(width: 16),
          // Título
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VG MUEBLERÍA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Catálogo de Productos por Categoría',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFFDDCCCC),
                  ),
                ),
              ],
            ),
          ),
          // Fecha
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Fecha del reporte:',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFFDDCCCC),
                ),
              ),
              pw.Text(
                fecha,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer con número de página
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _tableBorder, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'VG Mueblería - Los muebles perfectos para cada espacio',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Resumen general del reporte
  pw.Widget _buildResumen(List<Map<String, dynamic>> datos, int totalCategorias) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF5F5),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFEECCCC)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildResumenItem('Total Productos', datos.length.toString()),
          _buildResumenItem('Categorías', totalCategorias.toString()),
          _buildResumenItem(
            'Con Stock',
            datos.where((d) => (d['producto_stock'] as int? ?? 0) > 0).length.toString(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildResumenItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Encabezado de categoría
  pw.Widget _buildCategoriaHeader(String nombre, int cantProductos) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            nombre.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1,
            ),
          ),
          pw.Text(
            '$cantProductos producto(s)',
            style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFFDDCCCC)),
          ),
        ],
      ),
    );
  }

  /// Tabla de productos de una categoría
  pw.Widget _buildProductosTable(
    List<Map<String, dynamic>> productos,
    Map<String, pw.MemoryImage> imagenesCache,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _tableBorder, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(50),  // Imagen
        1: const pw.FlexColumnWidth(2.5),   // Nombre
        2: const pw.FlexColumnWidth(3),     // Descripción
        3: const pw.FixedColumnWidth(80),   // Precio
        4: const pw.FixedColumnWidth(45),   // Stock
      },
      children: [
        // Header de la tabla
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0E0E0)),
          children: [
            _buildTableHeader('Img'),
            _buildTableHeader('Nombre'),
            _buildTableHeader('Descripción'),
            _buildTableHeader('Precio (Gs)'),
            _buildTableHeader('Stock'),
          ],
        ),
        // Filas de productos
        ...productos.asMap().entries.map((entry) {
          final index = entry.key;
          final prod = entry.value;
          final isAlt = index % 2 == 1;
          return _buildProductRow(prod, imagenesCache, isAlt);
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.TableRow _buildProductRow(
    Map<String, dynamic> prod,
    Map<String, pw.MemoryImage> imagenesCache,
    bool isAlt,
  ) {
    final urlImg = prod['producto_url_img'] as String?;
    final nombre = prod['producto_nombre'] as String? ?? '';
    final descripcion = prod['producto_descripcion'] as String? ?? '';
    final precio = prod['producto_precio'] as int? ?? 0;
    final stock = prod['producto_stock'] as int?;

    return pw.TableRow(
      decoration: isAlt ? pw.BoxDecoration(color: _altRowBg) : null,
      children: [
        // Imagen
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          height: 40,
          child: urlImg != null && imagenesCache.containsKey(urlImg)
              ? pw.Image(imagenesCache[urlImg]!, fit: pw.BoxFit.cover)
              : pw.Center(
                  child: pw.Text('—', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ),
        ),
        // Nombre
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            nombre,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        // Descripción
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            descripcion.length > 80 ? '${descripcion.substring(0, 80)}...' : descripcion,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            maxLines: 3,
          ),
        ),
        // Precio
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _formatearPrecio(precio),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
        // Stock
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            stock != null ? stock.toString() : '—',
            style: pw.TextStyle(
              fontSize: 9,
              color: stock != null && stock > 0 ? PdfColors.green700 : PdfColors.red700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Dispara la descarga del PDF en web
  void descargarPdf(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Formatea un número como precio con separador de miles
  String _formatearPrecio(int precio) {
    return precio.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Formatea la fecha actual
  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
