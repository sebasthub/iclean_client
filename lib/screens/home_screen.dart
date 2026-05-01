import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/home_drawer.dart';
import '../widgets/action_bottom_sheet.dart';
import 'service_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  // Ponto inicial do mapa
  LatLng _currentPosition = const LatLng(-23.550520, -46.633308);
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceLocation();
  }

  Future<void> _loadDeviceLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização desativados.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão permanentemente negada.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition, 16.0);
      }
    } catch (e) {
      debugPrint('Erro ao buscar localização do dispositivo: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível obter sua localização: $e')),
        );
      }
    }
  }

  void _solicitarServico() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ServiceFlowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};

    String addressText = 'Nenhum endereço informado';
    if (metadata['address'] is Map) {
      final addr = metadata['address'];
      addressText = '${addr['logradouro']}, ${addr['numero']}';
      if (addr['complemento']?.isNotEmpty ?? false) {
        addressText += ' - ${addr['complemento']}';
      }
      addressText +=
          '\n${addr['bairro']}, ${addr['cidade']} - ${addr['estado']}\nCEP: ${addr['cep']}';
    } else if (metadata['address'] is String) {
      addressText = metadata['address'];
    }

    final name = metadata['name'] as String? ?? 'Sem Nome';
    final email = user?.email ?? 'N/A';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      drawer: HomeDrawer(name: name, email: email, addressText: addressText),
      body: Stack(
        children: [
          // 1. Camada de Fundo: O Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.iclean',
              ),
              // Marcador indicando a posição do usuário
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 50,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Feedback visual se estiver carregando a localização do GPS
          if (_isLoadingLocation)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Buscando GPS do aparelho...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. Camada Inferior: Painel de Ação (Bottom Sheet Fixo) extraído para componente
          ActionBottomSheet(onAction: _solicitarServico),
        ],
      ),
    );
  }
}
