import 'package:flutter/material.dart';
import '../../core/constants/schedule_data.dart';

/// Màn hình Lịch mở thưởng XSMN
class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Mở Thưởng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: 7,
        separatorBuilder: (context, i) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final weekday = index + 1;
          final day = ScheduleData.schedule[weekday]!;
          final isToday = weekday == today;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color.fromARGB(255, 255, 243, 205)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? const Color.fromARGB(255, 240, 17, 1)
                    : Colors.grey.shade300,
                width: isToday ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên thứ
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.dayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? const Color.fromARGB(255, 240, 17, 1)
                                : Colors.black87,
                          ),
                        ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 240, 17, 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Hôm nay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Danh sách tỉnh
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: day.provinces
                          .map((province) => _ProvinceChip(
                                province: province,
                                isToday: isToday,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProvinceChip extends StatelessWidget {
  final String province;
  final bool isToday;

  const _ProvinceChip({required this.province, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isToday
            ? const Color.fromARGB(26, 240, 17, 1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? const Color.fromARGB(102, 240, 17, 1)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        province,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isToday
              ? const Color.fromARGB(255, 200, 10, 0)
              : Colors.black87,
        ),
      ),
    );
  }
}
