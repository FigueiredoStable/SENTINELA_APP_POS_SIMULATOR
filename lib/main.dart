import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/routes/route_generator.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/secure_storage_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GetIt.I.registerSingleton<NavigationService>(NavigationService());
  runApp(const SentinelaApp());
}

class SentinelaApp extends StatelessWidget {
  const SentinelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      locale: const Locale('pt', 'BR'),
      title: 'Sentinela Spolus',
      navigatorKey: GetIt.I<NavigationService>().navigatorKey,
      navigatorObservers: [GetIt.I<NavigationService>()],
      onGenerateRoute: RouteGenerator.generateRoutes,
      initialRoute: '/splashscreen',
      builder: (context, child) {
        return MaintenanceTapArea(child: child!);
      },
    );
  }
}

class MaintenanceTapArea extends StatefulWidget {
  final Widget child;

  const MaintenanceTapArea({super.key, required this.child});

  @override
  State<MaintenanceTapArea> createState() => _MaintenanceTapAreaState();
}

class _MaintenanceTapAreaState extends State<MaintenanceTapArea> {
  int _tapCount = 0;
  Timer? _resetTimer;

  void _handleTap(TapDownDetails details) {
    final size = MediaQuery.of(context).size;
    final dx = details.globalPosition.dx;
    final dy = details.globalPosition.dy;

    // Verifica se foi no canto inferior esquerdo (10% largura, 20% altura)
    final isBottomLeft = dx < size.width * 0.2 && dy > size.height * 0.8;

    if (!isBottomLeft) return;

    _tapCount++;

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0;
    });

    if (_tapCount >= 7) {
      _tapCount = 0;
      _resetTimer?.cancel();
      _showMaintenanceDialog();
    }
  }

  void _showMaintenanceDialog() {
    String input = '';
    bool wrongPassword = false;
    final navigatorContext = GetIt.I<NavigationService>().navigatorKey.currentContext!;

    showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modo de Manutenção'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.98,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(left: wrongPassword ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: i < input.length ? Colors.black : Colors.grey[300], shape: BoxShape.circle),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children:
                          List.generate(9, (i) {
                            final number = (i + 1).toString();
                            return _buildKey(number, () {
                              if (input.length < 6) {
                                setState(() {
                                  input += number;
                                  wrongPassword = false;
                                });
                              }
                            });
                          })..addAll([
                            _buildKey('←', () {
                              if (input.isNotEmpty) {
                                setState(() {
                                  input = input.substring(0, input.length - 1);
                                  wrongPassword = false;
                                });
                              }
                            }, color: Colors.red),
                            _buildKey('0', () {
                              if (input.length < 6) {
                                setState(() {
                                  input += '0';
                                  wrongPassword = false;
                                });
                              }
                            }),
                            _buildKey('OK', () async {
                              // get pass from secure storage
                              final maintenancePassword = await SecureStorageKey.main.instance.read(key: 'maintenance_code');
                              if (input == maintenancePassword) {
                                GetIt.I<NavigationService>().pop();
                                const platform = MethodChannel('maintenance_channel');
                                try {
                                  await platform.invokeMethod('openSettings');
                                } on PlatformException catch (e) {
                                  log('Erro ao abrir configurações: $e');
                                }
                              } else {
                                setState(() {
                                  input = '';
                                  wrongPassword = true;
                                });
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(navigatorContext).showSnackBar(const SnackBar(content: Text('Senha incorreta'), backgroundColor: Colors.red));
                              }
                            }, color: Colors.blueAccent[700]),
                          ]),
                    ),

                    // cancel button
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        GetIt.I<NavigationService>().pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w900),
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

  Widget _buildKey(String label, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(60, 60),
        backgroundColor: color ?? Constants.spolusDarkTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: _handleTap, child: widget.child),
    );
  }
}
