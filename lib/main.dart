import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://caccgejhcryplnmbxgtv.supabase.co',
    anonKey: 'sb_publishable_jPjEYcCbszcJn20vOjMBeQ_4ACHe9Mt', // Masukkan Publishable / Anon Key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah user sudah login sebelumnya
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'IoT Supabase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Jika session ada, langsung buka Dashboard, jika tidak ke Login
      home: session != null ? const DashboardView() : const LoginView(),
    );
  }
}