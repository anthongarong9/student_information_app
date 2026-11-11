import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EnrollPage extends StatelessWidget {
  final VoidCallback onViewStudents;

  const EnrollPage({super.key, required this.onViewStudents});

  static const _courses = [
    _Course('BSIT', 'Information Technology', Icons.computer_outlined),
    _Course('BSCS', 'Computer Science', Icons.code_rounded),
    _Course('BSCPE', 'Computer Engineering', Icons.memory_outlined),
    _Course('BSCRIM', 'Criminology', Icons.local_police_outlined),
    _Course('BSCHTM', 'Hospitality & Tourism', Icons.hotel_outlined),
    _Course('BSBA', 'Business Administration', Icons.business_center_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final students = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: students.snapshots(),
      builder: (context, snapshot) {
        final counts = {for (final course in _courses) course.code: 0};
        for (final document in snapshot.data?.docs ?? []) {
          final code = document
              .data()['course']
              ?.toString()
              .trim()
              .toUpperCase();
          if (code != null && counts.containsKey(code)) {
            counts[code] = counts[code]! + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          Color.lerp(colorScheme.primary, Colors.black, 0.2)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find your course',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a program, then select a saved student to enroll.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.84,
                                      ),
                                    ),
                              ),
                              if (snapshot.hasData) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${snapshot.data!.docs.length} student records',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.school_rounded,
                          size: 62,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Available courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a course to view and enroll saved students.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return _CourseCard(
                        course: course,
                        studentCount: counts[course.code] ?? 0,
                        onEnroll: () =>
                            _showCourseRoster(context, students, course),
                      );
                    },
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Course counts are unavailable right now.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCourseRoster(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> students,
    _Course course,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _CourseRosterPage(
          students: students,
          course: course,
          onViewStudents: onViewStudents,
        ),
      ),
    );
  }
}

class _Course {
  final String code;
  final String name;
  final IconData icon;

  const _Course(this.code, this.name, this.icon);
}

class _CourseCard extends StatelessWidget {
  final _Course course;
  final int studentCount;
  final VoidCallback onEnroll;

  const _CourseCard({
    required this.course,
    required this.studentCount,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEnroll,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(course.icon, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                course.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Text(
                  course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRosterPage extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> students;
  final _Course course;
  final VoidCallback onViewStudents;

  const _CourseRosterPage({
    required this.students,
    required this.course,
    required this.onViewStudents,
  });

  @override
  State<_CourseRosterPage> createState() => _CourseRosterPageState();
}

class _CourseRosterPageState extends State<_CourseRosterPage> {
  String? _updatingStudentId;

  Future<void> _enrollStudent(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final currentCourse = data['course']?.toString().trim() ?? '';
    final name = data['fullName']?.toString() ?? 'this student';

    if (currentCourse.isNotEmpty) return;

    setState(() => _updatingStudentId = document.id);
    try {
      await widget.students.doc(document.id).update({
        'course': widget.course.code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name enrolled in ${widget.course.code}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enroll student: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingStudentId = null);
    }
  }

  Future<void> _unenrollStudent(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final name = document.data()['fullName']?.toString() ?? 'this student';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll student?'),
        content: Text('Remove $name from ${widget.course.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingStudentId = document.id);
    try {
      await widget.students.doc(document.id).update({
        'course': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name unenrolled from ${widget.course.code}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unenroll student: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingStudentId = null);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _studentPanel({
    required String title,
    required IconData icon,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    required bool isEnrolled,
    required bool scrollable,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget studentCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
      final data = document.data();
      final name = data['fullName']?.toString().trim().isNotEmpty == true
          ? data['fullName'].toString().trim()
          : 'Unnamed student';
      final studentNumber = data['studentNumber']?.toString() ?? '';
      final isUpdating = _updatingStudentId == document.id;

      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.primary,
            child: Text(
              _initials(name),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            studentNumber.isEmpty ? 'No student number' : studentNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton.filledTonal(
            tooltip: isEnrolled ? 'Unenroll student' : 'Enroll student',
            onPressed: _updatingStudentId != null
                ? null
                : () => isEnrolled
                      ? _unenrollStudent(document)
                      : _enrollStudent(document),
            icon: isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isEnrolled ? Icons.remove_circle_outline : Icons.add),
          ),
        ),
      );
    }

    final content = students.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            child: Column(
              children: [
                Text(
                  isEnrolled
                      ? 'No students enrolled in this course yet.'
                      : 'No unassigned students available.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (!isEnrolled) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onViewStudents();
                    },
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Go to Student Records'),
                  ),
                ],
              ],
            ),
          )
        : scrollable
        ? ListView.separated(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            itemCount: students.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => studentCard(students[index]),
          )
        : Column(
            children: [
              for (var index = 0; index < students.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                studentCard(students[index]),
              ],
            ],
          );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${students.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (scrollable) Expanded(child: content) else content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Enroll in ${widget.course.code}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.course.icon, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Choose a saved student to enroll',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: widget.students.orderBy('fullName').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load saved students.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final documents = snapshot.data!.docs;
                    final enrolledStudents = documents
                        .where(
                          (document) =>
                              document
                                  .data()['course']
                                  ?.toString()
                                  .trim()
                                  .toUpperCase() ==
                              widget.course.code,
                        )
                        .toList();
                    final availableStudents = documents
                        .where(
                          (document) =>
                              (document.data()['course']?.toString().trim() ??
                                      '')
                                  .isEmpty,
                        )
                        .toList();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 700) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _studentPanel(
                                  title: 'Enrolled',
                                  icon: Icons.check_circle_outline,
                                  students: enrolledStudents,
                                  isEnrolled: true,
                                  scrollable: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _studentPanel(
                                  title: 'Available students',
                                  icon: Icons.person_add_alt_1,
                                  students: availableStudents,
                                  isEnrolled: false,
                                  scrollable: true,
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView(
                          children: [
                            _studentPanel(
                              title: 'Enrolled',
                              icon: Icons.check_circle_outline,
                              students: enrolledStudents,
                              isEnrolled: true,
                              scrollable: false,
                            ),
                            const SizedBox(height: 20),
                            _studentPanel(
                              title: 'Available students',
                              icon: Icons.person_add_alt_1,
                              students: availableStudents,
                              isEnrolled: false,
                              scrollable: false,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
