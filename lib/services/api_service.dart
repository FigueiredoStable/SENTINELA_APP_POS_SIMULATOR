import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final SupabaseClient client;

  ApiService(this.client);

  // Acesso fácil ao Auth e Database
  SupabaseClient get supabase => client;
  GoTrueClient get auth => client.auth;
  SupabaseQueryBuilder table(String name) => client.from(name);

  // Métodos utilitários globais
  Future<PostgrestResponse> rpc(String fnName, {Map<String, dynamic>? params}) {
    return client.rpc(fnName, params: params);
  }
}
