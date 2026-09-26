import 'package:flutter/material.dart';
import '../../core/services/database_service.dart';

/// Màn hình Thống kê dò vé — tính toán hoàn toàn từ SQLite
class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  TicketStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final stats = await DatabaseService.instance.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống Kê Dò Vé',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null || _stats!.total == 0
              ? _buildEmptyState()
              : _buildStats(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 90, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'Chưa có dữ liệu thống kê',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sử dụng chức năng Dò Vé Số để bắt đầu\ntích lũy thống kê của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade400),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Thống kê được tính từ lịch sử dò vé lưu trên máy, không cần kết nối mạng.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats!;
    final winPct = (s.winRate * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tổng quan
          _SectionTitle(title: 'Tổng Quan'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.confirmation_number,
                  label: 'Tổng lần dò',
                  value: '${s.total}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events,
                  label: 'Số vé trúng',
                  value: '${s.totalWins}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.close,
                  label: 'Không trúng',
                  value: '${s.totalLosses}',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.percent,
                  label: 'Tỷ lệ trúng',
                  value: '$winPct%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          // Biểu đồ đơn giản
          const SizedBox(height: 20),
          _SectionTitle(title: 'Tỷ Lệ Trúng / Không Trúng'),
          const SizedBox(height: 10),
          _WinRateBar(wins: s.totalWins, total: s.total),

          // Thống kê theo đài
          if (s.byStation.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(title: 'Thống Kê Theo Đài'),
            const SizedBox(height: 10),
            ...s.byStation.map((st) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StationRow(stat: st),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _WinRateBar extends StatelessWidget {
  final int wins;
  final int total;

  const _WinRateBar({required this.wins, required this.total});

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0.0 : wins / total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _BarLegend(color: Colors.green, label: 'Trúng ($wins)'),
              const Spacer(),
              _BarLegend(
                  color: Colors.grey.shade400,
                  label: 'Không trúng (${total - wins})'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (rate > 0)
                    Flexible(
                      flex: (rate * 1000).round(),
                      child: Container(color: Colors.green),
                    ),
                  if (rate < 1)
                    Flexible(
                      flex: ((1 - rate) * 1000).round(),
                      child: Container(color: Colors.grey.shade300),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _BarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _StationRow extends StatelessWidget {
  final StationStat stat;
  const _StationRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final winRate =
        stat.total == 0 ? 0.0 : stat.wins / stat.total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              stat.station,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${stat.total} lần',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text(
                      '${stat.wins} trúng',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(winRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        if (winRate > 0)
                          Flexible(
                            flex: (winRate * 100).round(),
                            child: Container(color: Colors.green),
                          ),
                        if (winRate < 1)
                          Flexible(
                            flex: ((1 - winRate) * 100).round(),
                            child: Container(color: Colors.grey.shade200),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
