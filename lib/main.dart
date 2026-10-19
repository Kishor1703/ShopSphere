import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopSphereBootstrap());
}

class ShopSphereBootstrap extends StatefulWidget {
  const ShopSphereBootstrap({super.key});

  @override
  State<ShopSphereBootstrap> createState() => _ShopSphereBootstrapState();
}

class _ShopSphereBootstrapState extends State<ShopSphereBootstrap> {
  late Future<SharedPreferences> _preferences = _loadPreferences();

  Future<SharedPreferences> _loadPreferences() async {
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 15));
    } catch (error, stackTrace) {
      developer.log(
        'Local storage initialization failed',
        name: 'ShopSphere.startup',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _preferences,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(snapshot.data!),
            ],
            child: const ShopSphereApp(),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Could not open local storage.'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() {
                              _preferences = _loadPreferences();
                            }),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );
  }
}
