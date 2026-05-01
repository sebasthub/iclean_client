import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  Future<Map<String, dynamic>?> fetchCep(String cep) async {
    final cepApenasNumeros = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepApenasNumeros.length != 8) return null;

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepApenasNumeros/json/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          return {
            'logradouro': data['logradouro'] ?? '',
            'bairro': data['bairro'] ?? '',
            'cidade': data['localidade'] ?? '',
            'estado': data['uf'] ?? '',
          };
        }
      }
    } catch (e) {
      // Ignora erro ou pode logar, deixaremos a Controller lidar com o null
    }
    
    return null;
  }
}
