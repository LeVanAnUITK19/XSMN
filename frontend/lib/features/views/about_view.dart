import 'package:flutter/material.dart';
import '../../core/constants/app_config.dart';

/// Màn hình Giới thiệu ứng dụng
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giới Thiệu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/XSMN_image.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConfig.appName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(26, 240, 17, 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Phiên bản ${AppConfig.appVersion}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 200, 10, 0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Mô tả
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Ứng dụng tra cứu kết quả Xổ Số Miền Nam nhanh chóng, '
                'tiện lợi và chính xác. Hỗ trợ xem kết quả theo ngày, '
                'dò vé số, lịch mở thưởng và thống kê dò vé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Tính năng nổi bật
            _InfoSection(
              title: 'Tính Năng',
              items: const [
                _InfoItem(icon: Icons.table_chart, text: 'Xem kết quả xổ số theo ngày'),
                _InfoItem(icon: Icons.confirmation_number, text: 'Dò vé số tự động'),
                _InfoItem(icon: Icons.calendar_month, text: 'Lịch mở thưởng theo tuần'),
                _InfoItem(icon: Icons.history, text: 'Lịch sử dò vé lưu cục bộ'),
                _InfoItem(icon: Icons.bar_chart, text: 'Thống kê dò vé chi tiết'),
                _InfoItem(icon: Icons.zoom_in, text: 'Phóng to từng đài dễ đọc'),
                _InfoItem(icon: Icons.share, text: 'Chia sẻ kết quả dạng ảnh'),
              ],
            ),
            const SizedBox(height: 16),

            // Liên hệ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Liên hệ',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConfig.supportEmail,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 18,
                        color: const Color.fromARGB(255, 240, 17, 1)),
                    const SizedBox(width: 10),
                    Text(item.text, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});
}
