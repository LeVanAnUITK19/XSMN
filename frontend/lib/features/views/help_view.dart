import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_config.dart';

/// Màn hình Trợ giúp & Phản hồi
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  Future<void> _sendFeedback(BuildContext context) async {
    // Dùng ACTION_SENDTO với scheme mailto — hoạt động tốt hơn trên Android
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${Uri.encodeComponent('Phản hồi ứng dụng ${AppConfig.appName}')}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showEmailFallback(context);
      }
    } catch (_) {
      if (context.mounted) _showEmailFallback(context);
    }
  }

  void _showEmailFallback(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Không tìm thấy app email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng gửi email thủ công đến:'),
            const SizedBox(height: 8),
            SelectableText(
              AppConfig.supportEmail,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 200, 10, 0),
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trợ Giúp & Phản Hồi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hướng dẫn
          _SectionHeader(icon: Icons.menu_book, title: 'Hướng Dẫn Sử Dụng'),
          const SizedBox(height: 10),
          _GuideCard(
            icon: Icons.table_chart,
            title: 'Xem kết quả xổ số',
            steps: const [
              'Mở ứng dụng — kết quả ngày mới nhất tự động hiển thị.',
              'Vuốt trái/phải để chuyển sang ngày trước/sau.',
              'Nhấn icon lịch để chọn ngày bất kỳ.',
              'Chọn chế độ hiển thị: Đầy đủ / 3 số / 2 số ở thanh dưới.',
              'Nhấn icon 🔍 trên tên tỉnh để phóng to cột đó.',
              'Nhấn icon chia sẻ để gửi kết quả dạng ảnh.',
            ],
          ),
          const SizedBox(height: 10),
          _GuideCard(
            icon: Icons.confirmation_number,
            title: 'Dò vé số',
            steps: const [
              'Nhấn nút "Dò Vé Số" ở cuối màn hình chính.',
              'Chọn ngày xổ và tỉnh muốn dò.',
              'Nhập 6 chữ số trên vé số của bạn.',
              'Nhấn "Dò Vé" để kiểm tra kết quả.',
              'Kết quả hiển thị ngay lập tức — lịch sử được lưu tự động.',
            ],
          ),
          const SizedBox(height: 10),
          _GuideCard(
            icon: Icons.calendar_month,
            title: 'Xem lịch mở thưởng',
            steps: const [
              'Mở menu Drawer (vuốt phải hoặc nhấn ☰).',
              'Chọn "Lịch mở thưởng".',
              'Ngày hôm nay được highlight màu đỏ.',
              'Xem các đài mở thưởng theo từng thứ trong tuần.',
            ],
          ),

          // FAQ
          const SizedBox(height: 24),
          _SectionHeader(icon: Icons.help_outline, title: 'Câu Hỏi Thường Gặp'),
          const SizedBox(height: 10),
          _FaqCard(
            question: 'Dữ liệu kết quả được lấy từ đâu?',
            answer:
                'Kết quả xổ số được tải từ máy chủ của ứng dụng, cập nhật sau khi các đài mở thưởng (sau 16:30 hàng ngày).',
          ),
          const SizedBox(height: 8),
          _FaqCard(
            question: 'Lịch sử dò vé có được đồng bộ lên mạng không?',
            answer:
                'Không. Lịch sử dò vé chỉ lưu trên thiết bị của bạn, không gửi lên máy chủ.',
          ),
          const SizedBox(height: 8),
          _FaqCard(
            question: 'Tại sao không có dữ liệu ngày tôi chọn?',
            answer:
                'Có thể kết quả chưa được cập nhật, hoặc ngày đó chưa có trong hệ thống. Thử lại sau 16:30 ngày xổ.',
          ),
          const SizedBox(height: 8),
          _FaqCard(
            question: 'Ứng dụng hỗ trợ mấy đài cùng lúc?',
            answer:
                'Tuỳ ngày, có thể hiện 3 hoặc 4 đài. Bạn có thể phóng to từng đài để đọc số dễ hơn.',
          ),

          // Phản hồi
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.feedback, title: 'Gửi Phản Hồi'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn có góp ý, báo lỗi hoặc đề xuất tính năng mới?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${AppConfig.supportEmail}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendFeedback(context),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Gửi Phản Hồi Qua Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 240, 17, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromARGB(255, 240, 17, 1), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}

class _GuideCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<String> steps;
  const _GuideCard(
      {required this.icon, required this.title, required this.steps});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(widget.icon,
              color: const Color.fromARGB(255, 240, 17, 1), size: 22),
          title: Text(widget.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          initiallyExpanded: false,
          onExpansionChanged: (_) {},
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                children: widget.steps
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                      255, 240, 17, 1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading:
              Icon(Icons.quiz_outlined, color: Colors.blue.shade400, size: 20),
          title: Text(question,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(answer,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
