import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_form_page.dart';
import 'student_year.dart';

class StudentsPage extends StatefulWidget {
  final int? initialYearFilter;

  const StudentsPage({super.key, this.initialYearFilter});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  late int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYearFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.isEmpty) return true;

    final searchableText = [
      data['fullName'],
      data['studentNumber'],
      data['course'],
      data['yearLevel'],
      data['email'],
    ].map((value) => value?.toString() ?? '').join(' ').toLowerCase();

    return searchableText.contains(_searchText);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Future<void> _openStudent(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormPage(
          documentId: document.id,
          initialData: document.data(),
        ),
      ),
    );
  }

  Future<void> _deleteStudent(
    CollectionReference<Map<String, dynamic>> collection,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final name = document.data()['fullName']?.toString() ?? 'this student';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 32,
        ),
        title: const Text('Delete student?'),
        content: Text('Delete $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await collection.doc(document.id).delete();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('fullName').snapshots(),
      builder: (context, snapshot) {
        final allDocuments = snapshot.data?.docs ?? [];
        final matchingDocuments = allDocuments.where((document) {
          final data = document.data();
          return _matchesSearch(data) &&
              (_selectedYear == null ||
                  studentYearNumber(data['yearLevel']) == _selectedYear);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your students',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    snapshot.hasData
                        ? '${allDocuments.length} ${allDocuments.length == 1 ? 'student' : 'students'} in your records'
                        : 'Manage and find your student records',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search students',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                            ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                children: [
                  _yearFilterChip(label: 'All', year: null),
                  for (var year = 1; year <= 4; year++)
                    _yearFilterChip(label: _yearLabel(year), year: year),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snapshot.hasError) {
                    return const _StudentsMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Couldn’t load students',
                      message: 'Please check your connection and try again.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (allDocuments.isEmpty) {
                    return const _StudentsMessage(
                      icon: Icons.school_outlined,
                      title: 'No students yet',
                      message: 'Add your first student to start building your records.',
                    );
                  }
                  if (matchingDocuments.isEmpty) {
                    return _StudentsMessage(
                      icon: Icons.search_off,
                      title: _searchText.isNotEmpty
                          ? 'No matches found'
                          : 'No students in this year',
                      message: _searchText.isNotEmpty
                          ? 'Try another name, number, course, or email.'
                          : 'Choose another year to view student records.',
                      action: _selectedYear != null
                          ? TextButton.icon(
                              onPressed: () =>
                                  setState(() => _selectedYear = null),
                              icon: const Icon(Icons.filter_list_off),
                              label: const Text('Show all years'),
                            )
                          : TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear search'),
                            ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: matchingDocuments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final document = matchingDocuments[index];
                      final data = document.data();
                      final name =
                          data['fullName']?.toString().trim().isNotEmpty == true
                          ? data['fullName'].toString().trim()
                          : 'Unnamed student';
                      final studentNumber =
                          data['studentNumber']?.toString() ?? '';
                      final course = data['course']?.toString() ?? '';
                      final yearLevel = data['yearLevel']?.toString() ?? '';
                      final email = data['email']?.toString() ?? '';

                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          onTap: () => _openStudent(document),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.primary,
                            child: Text(
                              _initials(name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (studentNumber.isNotEmpty)
                                  Text(
                                    studentNumber,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                if (course.isNotEmpty || yearLevel.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      [
                                            course,
                                            if (yearLevel.isNotEmpty)
                                              'Year $yearLevel',
                                          ]
                                          .where((value) => value.isNotEmpty)
                                          .join('  ·  '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (email.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          isThreeLine: course.isNotEmpty || email.isNotEmpty,
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Student options',
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _openStudent(document);
                              } else if (action == 'delete') {
                                _deleteStudent(collection, document);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Delete'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _yearLabel(int year) {
    final suffix = switch (year) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
    return '$year$suffix Year';
  }

  Widget _yearFilterChip({required String label, required int? year}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedYear == year,
        onSelected: (_) => setState(() => _selectedYear = year),
      ),
    );
  }
}

class _StudentsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _StudentsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
