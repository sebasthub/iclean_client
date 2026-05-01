import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/premium_button.dart';
import '../widgets/selection_card.dart';
import '../models/service_order.dart';
import '../services/order_service.dart';

class ServiceFlowScreen extends StatefulWidget {
  const ServiceFlowScreen({super.key});

  @override
  State<ServiceFlowScreen> createState() => _ServiceFlowScreenState();
}

class _ServiceFlowScreenState extends State<ServiceFlowScreen> {
  final PageController _pageController = PageController();
  final OrderService _orderService = OrderService();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Respostas do formulário
  String? _urgencyType; // 'agendar' ou 'agora'
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String? _cleaningType; // 'padrao', 'pesada', 'pos_obra'
  int _bedrooms = 1;
  int _bathrooms = 1;
  File? _securityVideo; // Vídeo opcional de segurança
  bool _isLoading = false;

  void _nextPage() {
    if (_currentPage == 0) {
      if (_urgencyType == null) {
        _showError('Selecione uma opção de urgência.');
        return;
      }
      if (_urgencyType == 'agendar' &&
          (_scheduledDate == null || _scheduledTime == null)) {
        _showError('Por favor, selecione a data e o horário do agendamento.');
        return;
      }
    }
    if (_currentPage == 1 && _cleaningType == null) {
      _showError('Selecione o tipo de limpeza.');
      return;
    }

    // Finalização
    if (_currentPage == 4) {
      _finishFlow();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_currentPage == 0) {
      Navigator.of(context).pop();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double _calculateTotal() {
    double basePrice = 100.0;
    if (_cleaningType == 'pesada') basePrice = 180.0;
    if (_cleaningType == 'pos_obra') basePrice = 300.0;

    double sizeMultiplier = (_bedrooms * 20.0) + (_bathrooms * 30.0);
    double total = basePrice + sizeMultiplier;
    if (_urgencyType == 'agora') total += 50.0;
    return total;
  }

  Future<void> _finishFlow() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Monta a data agendada combinando data + hora
      DateTime? scheduledDateTime;
      if (_urgencyType == 'agendar' &&
          _scheduledDate != null &&
          _scheduledTime != null) {
        scheduledDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      String? uploadedVideoUrl;
      if (_securityVideo != null) {
        uploadedVideoUrl = await _orderService.uploadOrderVideo(
          _securityVideo!,
          userId,
        );
      }

      final order = ServiceOrder(
        userId: userId,
        urgencyType: _urgencyType!,
        scheduledDate: scheduledDateTime,
        cleaningType: _cleaningType!,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        estimatedPrice: _calculateTotal(),
        videoUrl: uploadedVideoUrl,
      );

      await _orderService.createOrder(order);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('Pedido Confirmado!', textAlign: TextAlign.center),
            ],
          ),
          content: const Text(
            'Estamos buscando o melhor profissional para a sua faxina. Você será notificado em breve!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                text: 'Voltar para o Mapa',
                onPressed: () {
                  Navigator.of(context).pop(); // fecha modal
                  Navigator.of(context).pop(); // volta pra home
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header e Botão de Voltar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _previousPage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey[200],
                      color: Colors.black,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // Corpo do Wizard
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),

            // Rodapé com botão de Continuar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PremiumButton(
                text: _currentPage == 4 ? 'Confirmar Pedido' : 'Continuar',
                isLoading: _isLoading,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PASSO 1: Urgência
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Qual é a\nsua urgência?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha como deseja prosseguir com o seu pedido de faxina.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),

          SelectionCard(
            title: 'Agendar',
            subtitle: 'Marque para outro dia. É mais econômico.',
            icon: Icons.calendar_month,
            isSelected: _urgencyType == 'agendar',
            onTap: () => setState(() => _urgencyType = 'agendar'),
          ),

          // Campos de Data/Hora se "Agendar" for selecionado
          if (_urgencyType == 'agendar')
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 60),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() => _scheduledDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: Colors.black87),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledDate == null
                                  ? 'Escolher Data'
                                  : '${_scheduledDate!.day.toString().padLeft(2, '0')}/${_scheduledDate!.month.toString().padLeft(2, '0')}/${_scheduledDate!.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() => _scheduledTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledTime == null
                                  ? 'Horário'
                                  : _scheduledTime!.format(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          SelectionCard(
            title: 'Preciso Agora',
            subtitle: 'Enviaremos alguém imediatamente. Possui taxa adicional.',
            icon: Icons.flash_on,
            isSelected: _urgencyType == 'agora',
            onTap: () => setState(() {
              _urgencyType = 'agora';
              _scheduledDate = null;
              _scheduledTime = null;
            }),
          ),
        ],
      ),
    );
  }

  // PASSO 2: Tipo de Limpeza
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Qual tipo de\nlimpeza?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o serviço que melhor atende à sua necessidade de hoje.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),

          SelectionCard(
            title: 'Limpeza Padrão',
            subtitle:
                'Ideal para a manutenção do dia a dia. Inclui varrer, passar pano e tirar pó.',
            icon: Icons.cleaning_services,
            isSelected: _cleaningType == 'padrao',
            onTap: () => setState(() => _cleaningType = 'padrao'),
          ),
          const SizedBox(height: 16),
          SelectionCard(
            title: 'Limpeza Pesada',
            subtitle:
                'Foco em sujeiras difíceis, gordura e detalhes minuciosos.',
            icon: Icons.wash,
            isSelected: _cleaningType == 'pesada',
            onTap: () => setState(() => _cleaningType = 'pesada'),
          ),
          const SizedBox(height: 16),
          SelectionCard(
            title: 'Pós-Obra',
            subtitle:
                'Remoção de poeira de gesso, respingos de tinta e resíduos de construção.',
            icon: Icons.handyman,
            isSelected: _cleaningType == 'pos_obra',
            onTap: () => setState(() => _cleaningType = 'pos_obra'),
          ),
        ],
      ),
    );
  }

  // PASSO 3: Tamanho
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Tamanho\ndo imóvel',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isso nos ajuda a calcular o tempo estimado e o valor do serviço.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),

          // Contador Quartos
          _buildCounterRow(
            title: 'Quartos',
            icon: Icons.bed,
            value: _bedrooms,
            onIncrement: () => setState(() => _bedrooms++),
            onDecrement: () => setState(() {
              if (_bedrooms > 0) _bedrooms--;
            }),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),

          // Contador Banheiros
          _buildCounterRow(
            title: 'Banheiros',
            icon: Icons.bathtub,
            value: _bathrooms,
            onIncrement: () => setState(() => _bathrooms++),
            onDecrement: () => setState(() {
              if (_bathrooms > 0) _bathrooms--;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required IconData icon,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: Colors.black87),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: value > 0 ? Colors.black : Colors.grey,
              iconSize: 32,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.black,
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  // PASSO 4: Vídeo de Segurança (Opcional)
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Vídeo de\nSegurança',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Totalmente opcional. Grave um vídeo curto do ambiente para ajudar nossos profissionais a se prepararem. O vídeo será guardado por segurança durante 30 dias.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (_securityVideo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Vídeo anexado com sucesso!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _securityVideo = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            SelectionCard(
              title: 'Gravar Vídeo',
              subtitle: 'Use a câmera do seu celular agora.',
              icon: Icons.videocam,
              isSelected: false,
              onTap: () => _pickVideo(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            SelectionCard(
              title: 'Escolher da Galeria',
              subtitle: 'Selecione um vídeo já gravado.',
              icon: Icons.video_library,
              isSelected: false,
              onTap: () => _pickVideo(ImageSource.gallery),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        setState(() {
          _securityVideo = File(video.path);
        });
      }
    } catch (e) {
      _showError('Erro ao selecionar o vídeo: $e');
    }
  }

  // PASSO 5: Resumo e Valor Fictício
  Widget _buildStep5() {
    final total = _calculateTotal();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Resumo do\nPedido',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confira os detalhes antes de confirmar.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryLine(
                  'Urgência',
                  _urgencyType == 'agora'
                      ? 'Imediato (+ Taxa)'
                      : (_scheduledDate != null && _scheduledTime != null)
                      ? '${_scheduledDate!.day.toString().padLeft(2, '0')}/${_scheduledDate!.month.toString().padLeft(2, '0')} às ${_scheduledTime!.format(context)}'
                      : 'Agendado',
                ),
                const Divider(height: 24),
                _buildSummaryLine(
                  'Limpeza',
                  _cleaningType == 'padrao'
                      ? 'Padrão'
                      : _cleaningType == 'pesada'
                      ? 'Pesada'
                      : 'Pós-Obra',
                ),
                const Divider(height: 24),
                _buildSummaryLine(
                  'Tamanho',
                  '$_bedrooms Quartos, $_bathrooms Banh.',
                ),
                const Divider(height: 32, color: Colors.black26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Estimado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
