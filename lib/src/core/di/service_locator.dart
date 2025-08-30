import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/services/api_service.dart';
import 'package:sentinela_app_pos_simulator/services/internet_connection_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> setupLocator() async {
  // * FlutterSecureStorage dividido em 4 instancias separando os tipos de dados por logica e criticidade
  GetIt.I.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'sentinela_storage')),
    instanceName: 'storageMain',
  );

  GetIt.I.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'sentinela_storage_transactions')),
    instanceName: 'storageTransactions',
  );

  GetIt.I.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'sentinela_storage_products')),
    instanceName: 'storageProducts',
  );

  GetIt.I.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'sentinela_storage_commands')),
    instanceName: 'storageCommands',
  );

  // * Logger mais completo para debug
  GetIt.I.registerLazySingleton<LoggerService>(() => LoggerService());

  // * Supabase platform
  await Supabase.initialize(
    url: 'https://nmhyclmkvjmoqimtlths.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5taHljbG1rdmptb3FpbXRsdGhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDUwOTUwNDksImV4cCI6MjAyMDY3MTA0OX0.hKgPYOC5FKaDktLzH9XkJw90crueH2qFtSDYuugBmRo',
  );
  final supabase = Supabase.instance.client;
  GetIt.I.registerSingleton<ApiService>(ApiService(supabase));
  GetIt.I.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // * HomeController
  GetIt.I.registerSingleton<HomeController>(HomeController(), dispose: (instance) => instance.disposeHomeController());

  // * Inicializando o serviço para verificar a conexão com a internet
  final internetCheckService = InternetCheckConnectionService();
  await internetCheckService.init();
  GetIt.I.registerSingleton<InternetCheckConnectionService>(internetCheckService);

  GetIt.I<LoggerService>().i('✅ Todas as dependências estão prontas!');
}
