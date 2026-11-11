import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_year.dart';

class StudentFormPage extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? initialData;

  const StudentFormPage({super.key, this.documentId, this.initialData});

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _yearLevel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _number = TextEditingController(text: d['studentNumber'] ?? '');
    _name = TextEditingController(text: d['fullName'] ?? '');
    _yearLevel = studentYearNumber(d['yearLevel'])?.toString();
    _email = TextEditingController(text: d['email'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [_number, _name, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
    final data = <String, dynamic>{
      'studentNumber': _number.text.trim(),
      'fullName': _name.text.trim(),
      'yearLevel': '${_yearLevel!}${_yearSuffix(_yearLevel!)} Year',
      'email': _email.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.documentId == null) {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(widget.documentId).update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _yearSuffix(String year) {
    return switch (year) {
      '1' => 'st',
      '2' => 'nd',
      '3' => 'rd',
      _ => 'th',
    };
  }

  Widget _yearField() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _yearLevel,
        decoration: InputDecoration(
          labelText: 'Year Level',
          prefixIcon: const Icon(Icons.school_outlined),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
        items: [
          for (var year = 1; year <= 4; year++)
            DropdownMenuItem(
              value: '$year',
              child: Text('$year${_yearSuffix('$year')} Year'),
            ),
        ],
        onChanged: (value) => setState(() => _yearLevel = value),
        validator: (value) => value == null ? 'Select a year level' : null,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool email = false,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return '$label is required';
          if (email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.documentId != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Student' : 'Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_outlined : Icons.person_add,
                          color: colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Update student details'
                                  : 'Create a student record',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter the student information below.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Student information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 18),
                          _field(
                            _number,
                            'Student Number',
                            icon: Icons.badge_outlined,
                          ),
                          _field(
                            _name,
                            'Full Name',
                            icon: Icons.person_outline,
                            textCapitalization: TextCapitalization.words,
                          ),
                          _yearField(),
                          _field(
                            _email,
                            'Email',
                            email: true,
                            icon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isEditing
                                          ? Icons.check_rounded
                                          : Icons.person_add_alt_1,
                                    ),
                              label: Text(
                                _saving
                                    ? 'Saving...'
                                    : isEditing
                                    ? 'Save Changes'
                                    : 'Add Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Student information is stored securely.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
