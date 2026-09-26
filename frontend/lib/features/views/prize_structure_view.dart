import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/lottery/prize_rule.dart';

/// Màn hình Cơ cấu giải thưởng XSMN
class PrizeStructureView extends StatelessWidget {
  const PrizeStructureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Cơ cấu giải thưởng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Nguồn dữ liệu',
            onPressed: () => _showSourceDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMainPrizesSection(),
          const SizedBox(height: 16),
          _buildSpecialPrizesSection(),
          const SizedBox(height: 16),
          _buildTaxSection(),
          const SizedBox(height: 16),
          _buildDisclaimerSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 17, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CƠ CẤU GIẢI THƯỞNG XSMN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vé truyền thống • Mệnh giá 10.000đ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Cập nhật / kiểm chứng lần cuối: ${XsmnPrizeRules.ruleLastVerifiedAt}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Giải chính ──────────────────────────────────────────────

  Widget _buildMainPrizesSection() {
    return _Section(
      title: 'GIẢI CHÍNH',
      icon: Icons.emoji_events,
      children: [
        _PrizeCard(
          rule: XsmnPrizeRules.specialPrize,
          highlight: true,
        ),
        _PrizeCard(rule: XsmnPrizeRules.firstPrize),
        _PrizeCard(rule: XsmnPrizeRules.secondPrize),
        _PrizeCard(rule: XsmnPrizeRules.thirdPrize),
        _PrizeCard(rule: XsmnPrizeRules.fourthPrize),
        _PrizeCard(rule: XsmnPrizeRules.fifthPrize),
        _PrizeCard(rule: XsmnPrizeRules.sixthPrize),
        _PrizeCard(rule: XsmnPrizeRules.seventhPrize),
        _PrizeCard(rule: XsmnPrizeRules.eighthPrize),
      ],
    );
  }

  // ── Giải phụ ────────────────────────────────────────────────

  Widget _buildSpecialPrizesSection() {
    return _Section(
      title: 'GIẢI PHỤ',
      icon: Icons.stars,
      children: [
        _SpecialPrizeCard(
          code: XsmnPrizeRules.specialSecondaryPrize.code,
          name: XsmnPrizeRules.specialSecondaryPrize.name,
          amount: XsmnPrizeRules.specialSecondaryPrize.amount,
          count: XsmnPrizeRules.specialSecondaryPrize.count,
          condition: XsmnPrizeRules.specialSecondaryPrize.condition,
          detail: 'Trùng 5 số cuối Giải Đặc Biệt nhưng khác số đầu tiên (hàng trăm nghìn).',
        ),
        const SizedBox(height: 8),
        _SpecialPrizeCard(
          code: XsmnPrizeRules.encouragementPrize.code,
          name: XsmnPrizeRules.encouragementPrize.name,
          amount: XsmnPrizeRules.encouragementPrize.amount,
          count: XsmnPrizeRules.encouragementPrize.count,
          condition: XsmnPrizeRules.encouragementPrize.condition,
          detail: 'Giống số đầu Giải Đặc Biệt và chỉ sai đúng một trong 5 chữ số còn lại.',
        ),
      ],
    );
  }

  // ── Thuế TNCN ───────────────────────────────────────────────

  Widget _buildTaxSection() {
    return _Section(
      title: 'THUẾ & THỰC NHẬN',
      icon: Icons.calculate_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Thuế thu nhập cá nhân',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Theo quy định hiện hành từ 01/07/2026:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              _taxBullet('Tổng tiền trúng ≤ 20 triệu / vé / kỳ: không phát sinh thuế TNCN.'),
              _taxBullet('Tổng tiền trúng > 20 triệu: thuế = 10% × (phần vượt 20 triệu).'),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Text(
                'Ví dụ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              _taxExample('30 triệu', 'thuế 1 triệu → thực nhận 29 triệu'),
              _taxExample('50 triệu', 'thuế 3 triệu → thực nhận 47 triệu'),
              _taxExample('2 tỷ', 'thuế 198 triệu → thực nhận 1,802 tỷ'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  'Trường hợp một vé trúng nhiều giải, tổng giá trị '
                  'các giải của vé được cộng lại trước khi tính thuế.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _taxBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _taxExample(String amount, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3, left: 8),
      child: Row(
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Text(' → ', style: TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              result,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ──────────────────────────────────────────────

  Widget _buildDisclaimerSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Lưu ý',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Các khoản phí khác (phí chuyển khoản, phí dịch vụ khi đổi qua đại lý...) '
            'có thể phụ thuộc đơn vị trả thưởng, ngân hàng hoặc đại lý và không được '
            'ứng dụng tự động khấu trừ nếu chưa có căn cứ chính thức.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Thông tin mang tính hỗ trợ tra cứu. Việc trả thưởng thực tế căn cứ '
            'vào vé gốc và quy định của đơn vị xổ số phát hành.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Dialog nguồn dữ liệu ────────────────────────────────────

  void _showSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.source_outlined, color: Color.fromARGB(255, 240, 17, 1)),
            SizedBox(width: 8),
            Text('Nguồn dữ liệu', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sourceBlock(
                title: 'Cơ cấu giải / thể lệ',
                items: [
                  'Website chính thức Công ty TNHH MTV XSKT Tây Ninh',
                  'Thể lệ tham gia dự thưởng xổ số truyền thống miền Nam',
                ],
              ),
              const SizedBox(height: 12),
              _sourceBlock(
                title: 'Thuế thu nhập cá nhân',
                items: [
                  'Luật Thuế thu nhập cá nhân hiện hành',
                  'Nghị định 253/2026/NĐ-CP',
                  'Thông tư 87/2026/TT-BTC',
                  'Hiệu lực từ 01/07/2026',
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Ngày kiểm chứng dữ liệu: ${XsmnPrizeRules.ruleLastVerifiedAt}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(
                      'https://xosotayninh.com.vn/trung-thuong/co-cau-giai-thuong');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  'Xem nguồn chính thức →',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
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

  Widget _sourceBlock({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section wrapper ──────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color.fromARGB(255, 240, 17, 1)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 180, 10, 0),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

// ── Card giải chính ──────────────────────────────────────────

class _PrizeCard extends StatelessWidget {
  final PrizeRule rule;
  final bool highlight;

  const _PrizeCard({required this.rule, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isSpecial = rule.code == 'DB';
    final bgColor = isSpecial ? Colors.red.shade50 : Colors.white;
    final borderColor = isSpecial ? Colors.red.shade300 : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tên giải
          SizedBox(
            width: 100,
            child: Text(
              rule.name,
              style: TextStyle(
                fontSize: isSpecial ? 15 : 14,
                fontWeight: isSpecial ? FontWeight.bold : FontWeight.w600,
                color: isSpecial ? Colors.red.shade700 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Giá trị
          Expanded(
            child: Text(
              _formatAmount(rule.amount),
              style: TextStyle(
                fontSize: isSpecial ? 15 : 14,
                fontWeight: FontWeight.bold,
                color: isSpecial ? Colors.red : Colors.black87,
              ),
            ),
          ),
          // Số giải
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCount(rule.winnersPerSeries),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                rule.condition,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return '${val % 1 == 0 ? val.toInt() : val} tỷđ';
    }
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val % 1 == 0 ? val.toInt() : val} triệuđ';
    }
    if (amount >= 1000) {
      final val = amount / 1000;
      return '${val % 1 == 0 ? val.toInt() : val}.000đ';
    }
    return '$amountđ';
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${count ~/ 1000}.000 giải';
    if (count >= 1000) return '${count ~/ 1000}.000 giải';
    return '$count giải';
  }
}

// ── Card giải phụ ────────────────────────────────────────────

class _SpecialPrizeCard extends StatelessWidget {
  final String code;
  final String name;
  final int amount;
  final int count;
  final String condition;
  final String detail;

  const _SpecialPrizeCard({
    required this.code,
    required this.name,
    required this.amount,
    required this.count,
    required this.condition,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final isSecondary = code == 'DB_PHU';
    final accentColor = isSecondary ? Colors.orange : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$count giải',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final val = amount ~/ 1000000;
      return '$val.000.000đ';
    }
    return '$amountđ';
  }
}
