/// Lịch mở thưởng XSMN — dữ liệu cố định, không cần gọi API
class ScheduleData {
  ScheduleData._();

  /// weekday: DateTime.monday = 1 ... DateTime.sunday = 7
  static const Map<int, DaySchedule> schedule = {
    DateTime.monday: DaySchedule(
      dayName: 'Thứ Hai',
      provinces: ['TP. Hồ Chí Minh', 'Đồng Tháp', 'Cà Mau'],
    ),
    DateTime.tuesday: DaySchedule(
      dayName: 'Thứ Ba',
      provinces: ['Bến Tre', 'Vũng Tàu', 'Bạc Liêu'],
    ),
    DateTime.wednesday: DaySchedule(
      dayName: 'Thứ Tư',
      provinces: ['Đồng Nai', 'Cần Thơ', 'Sóc Trăng'],
    ),
    DateTime.thursday: DaySchedule(
      dayName: 'Thứ Năm',
      provinces: ['Tây Ninh', 'An Giang', 'Bình Thuận'],
    ),
    DateTime.friday: DaySchedule(
      dayName: 'Thứ Sáu',
      provinces: ['Vĩnh Long', 'Bình Dương', 'Trà Vinh'],
    ),
    DateTime.saturday: DaySchedule(
      dayName: 'Thứ Bảy',
      provinces: ['TP. Hồ Chí Minh', 'Long An', 'Bình Phước', 'Hậu Giang'],
    ),
    DateTime.sunday: DaySchedule(
      dayName: 'Chủ Nhật',
      provinces: ['Tiền Giang', 'Kiên Giang', 'Đà Lạt'],
    ),
  };
}

class DaySchedule {
  final String dayName;
  final List<String> provinces;
  const DaySchedule({required this.dayName, required this.provinces});
}
