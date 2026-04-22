import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import '../../widgets/my_drawer.dart';
import '../../widgets/my_resultTable.dart';
import '../../../core/utils/transform_data.dart';
import '../../../core/models/result_model.dart';
import '../viewModels/home_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../widgets/my_singleChoise.dart';
import '../../widgets/wait_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../widgets/auto_check.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageView> {
  late ResultViewModel vm;
  String selected = 'full';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repaintKey = GlobalKey();
  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    vm = ResultViewModel();
    vm.addListener(_update);
    vm.load();
  }

  void _update() {
    if (vm.notFound) {
      vm.notFound = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          _scaffoldKey.currentContext ?? context,
        ).showSnackBar(
          const SnackBar(
            content: Text('Không có dữ liệu cho ngày này'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_update);
    super.dispose();
  }

  Future<void> _shareAsImage(String displayDate) async {
    try {
      final provinces = vm.result!.provinces;
      final tableData = transformData(provinces, selected);

      // Capture toàn bộ widget (kể cả phần ngoài màn hình)
      final bytes = await _screenshotController.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: _buildFullTable(provinces, tableData, displayDate),
            ),
          ),
        ),
        pixelRatio: 2.0,
        context: context,
      );

      final safeDate = DateFormat('yyyy-MM-dd').format(vm.currentDate);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/xsmn_$safeDate.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Kết quả Xổ Số Miền Nam - $displayDate');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chia sẻ: $e')));
      }
    }
  }

  Widget _buildFullTable(
    List<ProvinceResult> provinces,
    List<Map<String, dynamic>> tableData,
    String date,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tiêu đề ngày
          Container(
            color: const Color.fromARGB(255, 243, 244, 161),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Kết quả XSMN - $date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Header
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _tableCell('Giải', isHeader: true)),
                ...provinces.map(
                  (p) => Expanded(
                    flex: 4,
                    child: _tableCell(p.province, isHeader: true),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...tableData.map((row) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _tableCell(row['label'], isHeader: true),
                  ),
                  ...row['values'].map<Widget>((v) {
                    return Expanded(
                      flex: 4,
                      child: _tableCell(
                        v,
                        isG8: row['label'] == 'G8',
                        isDB: row['label'] == 'DB',
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isG8 = false,
    bool isDB = false,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        color: isHeader ? Colors.yellow.shade100 : Colors.white,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 13 : 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w900,
          color: isG8 || isDB ? Colors.red : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Scaffold(body: Center(child: WaitPage()));
    }

    if (vm.error != null) {
      return Scaffold(
        key: _scaffoldKey,
        body: Center(child: Text(vm.error!)),
      );
    }

    if (vm.result == null) {
      return Scaffold(
        key: _scaffoldKey,
        body: const Center(child: Text('Không có dữ liệu')),
      );
    }

    final provinces = vm.result!.provinces;
    final tableData = transformData(provinces, selected);
    final dt = vm.result!.date.toLocal();

    final date = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Xổ Số Miền Nam",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          const SizedBox(width: 12),
        ],

        backgroundColor: const Color.fromARGB(255, 240, 17, 1),
      ),
      drawer: const MyDrawer(),

      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: const Color.fromARGB(255, 243, 244, 161),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('vi', 'VN'),
                      );

                      if (pickedDate != null) {
                        vm.loadByDate(pickedDate); // 👈 reload thật
                      }
                    },
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    onPressed: () => _shareAsImage(date),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  // 👉 vuốt phải → ngày sau
                  final next = vm.currentDate.add(const Duration(days: 1));

                  if (next.isAfter(DateTime.now())) return;

                  vm.loadByDate(next);
                } else if (details.primaryVelocity! > 0) {
                  // 👉 vuốt trái → ngày trước
                  final prev = vm.currentDate.subtract(const Duration(days: 1));
                  vm.loadByDate(prev);
                }
              },
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  child: ResultTable(
                    provinces: provinces,
                    tableData: tableData,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Color.fromARGB(255, 243, 244, 161),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  SingleChoice(
                    value: 'full',
                    groupValue: selected,
                    label: 'Đầy đủ',
                    onChanged: (val) {
                      setState(() => selected = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  SingleChoice(
                    value: '3',
                    groupValue: selected,
                    label: '3 số',
                    onChanged: (val) {
                      setState(() => selected = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  SingleChoice(
                    value: '2',
                    groupValue: selected,
                    label: '2 số',
                    onChanged: (val) {
                      setState(() => selected = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Container(
              height: 60,
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => showCheckTicketDialog(context, vm),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Dò Vé Số',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}
