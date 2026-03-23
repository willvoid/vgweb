import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Para iconos de redes

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 700;
          return isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 30),
                    _buildContactSection(),
                    const SizedBox(height: 30),
                    _buildLinksSection(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildLogoSection()),
                    Expanded(child: _buildContactSection()),
                    Expanded(child: _buildLinksSection()),
                  ],
                );
        },
      ),
    );
  }

  /// Sección 1: Logo, descripción y redes
  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aquí podés cambiar tu logo:
        Image.asset(
          "assets/images/logo.jpg", //reemplazá con tu imagen
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        const Text(
          'Somos VG Mueblería, el lado bueno de la vida. Contamos con los mejores productos, al mejor precio.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.facebook,
                color: const Color.fromARGB(255, 88, 23, 23),
              ),
              onPressed: () {
                launch(
                  'https://www.facebook.com/p/Muebles-VG-61579206785241/',
                );
              },
            ),
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.instagram,
                color: const Color.fromARGB(255, 88, 23, 23),
              ),
              onPressed: () {
                launch(
                  'https://www.instagram.com/vgmuebleriapy?igsh=MXNkeDRtaHc1N2JzdA==',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Sección 2: Contacto
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacto',
          style: TextStyle(
            color: const Color.fromARGB(255, 88, 23, 23),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Icon(
              Icons.phone,
              color: const Color.fromARGB(255, 88, 23, 23),
            ),
            SizedBox(width: 8),
            Text('+595 985 255566', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  /// Sección 3: Enlaces útiles
  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enlaces Útiles',
          style: TextStyle(
            color: const Color.fromARGB(255, 88, 23, 23),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 60,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Contacto'),
                Text('Sucursales'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Bases y condiciones'),
                Text('Política de Entrega'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
