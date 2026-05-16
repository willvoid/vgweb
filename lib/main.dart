import 'package:flutter/material.dart';
import 'package:myapp/src/model/dao/configurations.dart';
import 'package:myapp/src/pages/home_page.dart';
import 'package:myapp/src/pages/login_page.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Configurations.mSupabaseUrl,
    anonKey: Configurations.mSupabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'VG Mueblería',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Si hay sesión, vamos al Home, si no, al Login
      home: session == null ? LoginPage() : HomePage(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}



