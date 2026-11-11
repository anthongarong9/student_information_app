import 'package:flutter/material.dart';

import 'account_settings_page.dart';
import 'dashboard_page.dart';
import 'enroll_page.dart';
import 'student_form_page.dart';
import 'students_page.dart';
import 'term_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0 = Home, 1 = Students, 2 = Enroll, 3 = Term, 4 = Account
  int _selectedIndex = 0;
  int? _studentsYearFilter;

  // The title shown in the app bar for each tab.
  final List<String> _titles = const [
    'Home',
    'Student Records',
    'Enroll',
    'Term',
    'Account Settings',
  ];

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectStudentYear(int year) {
    setState(() {
      _studentsYearFilter = year;
      _selectedIndex = 1;
    });
  }

  void _addStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onViewStudents: () => _selectTab(1),
        onAddStudent: _addStudent,
        onSelectYear: _selectStudentYear,
      ),
      StudentsPage(
        key: ValueKey(_studentsYearFilter),
        initialYearFilter: _studentsYearFilter,
      ),
      EnrollPage(onViewStudents: () => _selectTab(1)),
      const TermPage(),
      const AccountSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Student Hub',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            Text(
              _titles[_selectedIndex],
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),

      // The screen for the selected tab
      body: pages[_selectedIndex],

      // The Add Student button only appears on the Students tab
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _addStudent,
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1),
            label: 'Enroll',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Term',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
