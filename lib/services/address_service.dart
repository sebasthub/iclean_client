import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_address.dart';

class AddressService {
  final _client = Supabase.instance.client;

  /// Busca todos os endereços do usuário logado, ordenado por padrão e data
  Future<List<UserAddress>> fetchMyAddresses() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);

    return (response as List).map((m) => UserAddress.fromMap(m)).toList();
  }

  /// Cria um novo endereço. Se `isDefault` for true, desmarca os outros primeiro.
  Future<UserAddress> createAddress(UserAddress address) async {
    if (address.isDefault) {
      await _clearDefault(address.userId);
    }
    final response = await _client
        .from('user_addresses')
        .insert(address.toMap())
        .select()
        .single();
    return UserAddress.fromMap(response);
  }

  /// Atualiza um endereço existente
  Future<UserAddress> updateAddress(UserAddress address) async {
    if (address.isDefault) {
      await _clearDefault(address.userId);
    }
    final response = await _client
        .from('user_addresses')
        .update(address.toMap())
        .eq('id', address.id!)
        .select()
        .single();
    return UserAddress.fromMap(response);
  }

  /// Remove um endereço
  Future<void> deleteAddress(String id) async {
    await _client.from('user_addresses').delete().eq('id', id);
  }

  /// Define um endereço como padrão (desmarca os demais)
  Future<void> setDefault(String id, String userId) async {
    await _clearDefault(userId);
    await _client
        .from('user_addresses')
        .update({'is_default': true})
        .eq('id', id);
  }

  /// Remove a flag padrão de todos os endereços do usuário
  Future<void> _clearDefault(String userId) async {
    await _client
        .from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
  }
}
