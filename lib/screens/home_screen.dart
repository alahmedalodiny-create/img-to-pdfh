import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'image_to_pdf_screen.dart';
import 'scanner_screen.dart';
import 'files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ImageToPdfScreen(),
    ScannerScreen(),
    FilesScreen(),
  ];

  final List<String> _titles = [
    'تحويل إلى PDF',
    'الماسح الضوئي',
    'الملفات',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'تحويل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'ماسح',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'الملفات',
          ),
        ],
      ),
    );
  }
}
