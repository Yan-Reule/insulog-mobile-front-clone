import 'package:flutter/material.dart';
import 'package:insulog/screens/clock.dart';
import 'package:insulog/screens/home.dart';
import 'package:insulog/screens/options.dart';
import 'package:insulog/screens/report.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final List<Widget> pages = [
    const HomePage(),
    const ClockPage(),
    ReportPage(),
    const OptionsPage(),
    // RegistroPage(),
  ];

  final List<_NavItemData> navItems = const [
    _NavItemData(icon: Icons.home_outlined, label: 'Registros'),
    _NavItemData(icon: Icons.alarm_outlined, label: 'Lembrete'),
    _NavItemData(icon: Icons.description_outlined, label: 'Relatório'),
    _NavItemData(icon: Icons.settings_outlined, label: 'Opções'),
    // _NavItemData(icon: Icons.local_offer_outlined, label: 'Registro'),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const selectedColor = Color(0xFF30A356);
    const unselectedColor = Color(0xFF4D4D4D);

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: size.height * 0.08,
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final isSelected = index == i;

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => index = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 3,
                        width: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: Icon(
                          item.icon,
                          size: 28,
                          color: isSelected ? selectedColor : unselectedColor,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}



