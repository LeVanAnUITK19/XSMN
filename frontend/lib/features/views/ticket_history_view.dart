import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/ticket_history_model.dart';
import '../../core/services/database_service.dart';

/// Màn hình Lịch sử dò vé
class TicketHistoryView extends StatefulWidget {
  const TicketHistoryView({super.key});

  @override
  State<TicketHistoryView> createState() => _TicketHistoryViewState();
}

class _TicketHistoryViewState extends State<TicketHistoryView> {
  List<TicketHistory> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.instance.getAllTicketHistories();
    if (mounted) {
      setState(() {
        _histories = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseService.instance.deleteTicketHistory(id);
    _loadHistories();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tất cả?'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử dò vé?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.clearAllTicketHistories();
      _loadHistories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Sử Dò Vé',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_histories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Xóa tất cả',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử dò vé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy sử dụng chức năng Dò Vé Số\ntrên màn hình chính',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _histories.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _HistoryCard(
        history: _histories[i],
        onDelete: () => _deleteItem(_histories[i].id!),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TicketHistory history;
  final VoidCallback onDelete;

  const _HistoryCard({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(
      DateTime.parse(history.drawDate),
    );
    final checkedStr = DateFormat('HH:mm dd/MM/yyyy').format(history.checkedAt);

    return Container(
      decoration: BoxDecoration(
        color: history.isWin ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: history.isWin ? Colors.green.shade300 : Colors.grey.shade200,
          width: history.isWin ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Badge trạng thái
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: history.isWin
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                history.isWin ? Icons.emoji_events : Icons.close,
                color: history.isWin ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        history.ticketNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (history.isWin && history.prizeName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            history.prizeName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${history.station}  •  $dateStr',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Dò lúc $checkedStr',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            // Nút xóa
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: onDelete,
              tooltip: 'Xóa',
            ),
          ],
        ),
      ),
    );
  }
}
