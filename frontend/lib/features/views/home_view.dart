import 'package:flutter/material.dart';
import '../../widgets/my_drawer.dart';
import '../../widgets/my_resultTable.dart';
import '../../../core/utils/transform_data.dart';
import '../viewModels/home_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../widgets/my_singleChoise.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageView> {
  late ResultViewModel vm;
  String selected = 'full';

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
        ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }

    final provinces = vm.result!.provinces;
    final tableData = transformData(provinces, selected);
    final dt = vm.result!.date.toLocal();

    final date = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);

    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // handle click
            },
          ),
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
                    onPressed: () {
                      // handle share
                    },
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
              child: Container(
                color: Colors.white,
                child: ResultTable(provinces: provinces, tableData: tableData),
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
              height: 70,
              child: const Center(child: Text('Ads')),
            ),
          ),
        ],
      ),
    );
  }
}
