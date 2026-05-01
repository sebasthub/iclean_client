import 'package:flutter/material.dart';
import '../models/service_order.dart';
import '../controllers/order_controller.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderListController _listController = OrderListController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listController.fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<ServiceOrder> _filterByStatus(List<String> statuses) {
    return _listController.orders.where((o) => statuses.contains(o.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _listController,
          builder: (context, _) {
            final agendados = _filterByStatus(['pending', 'accepted', 'in_progress']);
            final finalizados = _filterByStatus(['completed', 'cancelled']);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Meus Serviços',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: 'Todos (${_listController.orders.length})'),
                      Tab(text: 'Agendados (${agendados.length})'),
                      Tab(text: 'Finalizados (${finalizados.length})'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Body
                Expanded(
                  child: _listController.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : _listController.errorMessage != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrderList(_listController.orders),
                            _buildOrderList(agendados),
                            _buildOrderList(finalizados),
                          ],
                        ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar pedidos',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _listController.fetchOrders,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'Tentar Novamente',
                style: TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<ServiceOrder> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum serviço encontrado',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _listController.fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(
            order: orders[index],
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: orders[index]),
                ),
              );
              // Recarrega ao voltar (caso tenha cancelado)
              _listController.fetchOrders();
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card individual de pedido
// ---------------------------------------------------------------------------
class _OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Ícone do tipo de limpeza
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _cleaningIcon(order.cleaningType),
                color: _statusColor(order.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleaningLabel(order.cleaningType),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildSubtitle(order),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Preço e Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${order.estimatedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(ServiceOrder o) {
    if (o.urgencyType == 'agora') return 'Imediato';
    if (o.scheduledDate != null) {
      final d = o.scheduledDate!;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return 'Agendado';
  }

  static String _cleaningLabel(String type) {
    switch (type) {
      case 'padrao':
        return 'Limpeza Padrão';
      case 'pesada':
        return 'Limpeza Pesada';
      case 'pos_obra':
        return 'Pós-Obra';
      default:
        return type;
    }
  }

  static IconData _cleaningIcon(String type) {
    switch (type) {
      case 'padrao':
        return Icons.cleaning_services;
      case 'pesada':
        return Icons.wash;
      case 'pos_obra':
        return Icons.handyman;
      default:
        return Icons.cleaning_services;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceito';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
