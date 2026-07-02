import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'features/marketplace/data/repositories/marketplace_repository.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HussamEnterpriseApp());
}

class HussamEnterpriseApp extends StatelessWidget {
  const HussamEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => MarketplaceRepository(),
      child: BlocProvider(
        create: (context) => MarketplaceBloc(context.read<MarketplaceRepository>()),
        child: MaterialApp(
          title: 'Hussam Sovereign Platform',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              secondary: Color(0xFF7000FF),
              surface: Color(0xFF0A0E17),
            ),
          ),
          home: const SovereignLoginPage(),
        ),
      ),
    );
  }
}
