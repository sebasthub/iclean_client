import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_address.dart';
import '../services/address_service.dart';

class AddressController extends ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<UserAddress> _addresses = [];
  List<UserAddress> get addresses => _addresses;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _addressService.fetchMyAddresses();
    } catch (e) {
      _errorMessage = 'Erro ao carregar endereços: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveAddress(UserAddress address) async {
    _isSaving = true;
    notifyListeners();

    try {
      if (address.id == null) {
        await _addressService.createAddress(address);
      } else {
        await _addressService.updateAddress(address);
      }
      await fetchAddresses(); // Recarrega para atualizar estado
      return null;
    } catch (e) {
      return 'Erro ao salvar endereço: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAddress(String id) async {
    _isSaving = true;
    notifyListeners();

    try {
      await _addressService.deleteAddress(id);
      await fetchAddresses();
      return null;
    } catch (e) {
      return 'Erro ao excluir endereço: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> setDefault(String id) async {
    _isSaving = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await _addressService.setDefault(id, userId);
      await fetchAddresses();
      return null;
    } catch (e) {
      return 'Erro ao definir como padrão: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
