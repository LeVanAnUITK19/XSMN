import 'package:flutter/material.dart';

class WaitPage extends StatelessWidget {
  const WaitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/XSMN_image.png',
                height: size.height * 0.3, // responsive khi xoay ngang
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              const Text(
                'Xổ Số Miền Nam',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}