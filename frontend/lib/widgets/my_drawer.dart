import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/XSMN_image.png'),
            ),
            title: const Text('Xổ Số Miền Nam'),
            backgroundColor: Colors.white,
          ),
          const Center(child: Text('Drawer Content')),
        ],
      ),
    );
  }
}
