import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/views/home_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // Giữ splash screen cho đến khi gọi FlutterNativeSplash.remove()
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());

  // Bỏ splash sau khi Flutter đã render xong frame đầu tiên
  // → chuyển thẳng sang WaitPage (hoặc HomeView nếu có cache)
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomePageView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
