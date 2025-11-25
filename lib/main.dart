import 'package:drivio_app/common/constants/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:drivio_app/common/widgets/auth_gate.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initApp() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // ✅ Initialize tile caching
  await FMTCObjectBoxBackend().initialise();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app
  await initApp();

  // ✅ Check if store exists before creating
  final store = FMTCStore('mapStore');
  final storeExists = await store.manage.ready;

  if (!storeExists) {
    await store.manage.create();
    debugPrint('✅ Created new map store');
  } else {
    debugPrint('ℹ️ Map store already exists');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // AuthGate will provide providers
      routes: AppRoutes.routes,
    );
  }
}
