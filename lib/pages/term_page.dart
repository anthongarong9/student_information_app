import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TermPage extends StatefulWidget {
  const TermPage({super.key});

  @override
  State<TermPage> createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {
  String? _savingTerm;

  Future<void> _setCurrentTerm(String term) async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _savingTerm = term);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'currentTerm': term,
        'termUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the current term: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingTerm = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final colorScheme = Theme.of(context).colorScheme;
    final userDocument = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load the current term: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final currentTerm = snapshot.data?.data()?['currentTerm'] as String?;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                                'Academic term',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose which term is currently active.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 54,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.event_available_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current term',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading...'
                                      : currentTerm ?? 'Not set yet',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (currentTerm != null)
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select a term',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your choice is saved to your account and will be remembered.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  for (final term in const ['1st Term', '2nd Term']) ...[
                    _TermOptionCard(
                      term: term,
                      selected: currentTerm == term,
                      saving: _savingTerm == term,
                      disabled:
                          _savingTerm != null ||
                          snapshot.connectionState == ConnectionState.waiting,
                      onSelect: () => _setCurrentTerm(term),
                    ),
                    if (term == '1st Term') const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TermOptionCard extends StatelessWidget {
  final String term;
  final bool selected;
  final bool saving;
  final bool disabled;
  final VoidCallback onSelect;

  const _TermOptionCard({
    required this.term,
    required this.selected,
    required this.saving,
    required this.disabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selected || disabled ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: selected ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected ? 'Currently active' : 'Set as current term',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (saving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (selected)
                Icon(Icons.check_circle, color: colorScheme.primary)
              else
                FilledButton.tonal(
                  onPressed: disabled ? null : onSelect,
                  child: const Text('Set term'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
