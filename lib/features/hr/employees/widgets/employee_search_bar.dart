import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../providers/hr_employee_providers.dart';

/// Search field shared by the HR Employees and Onboarding screens. Filters
/// client-side against name, ERPNext employee ID, and (Employees screen
/// only) department.
///
/// [queryProvider] lets each screen wire its own StateProvider<String>.
/// Required (not defaulted) because StateProvider instances aren't
/// compile-time constants in Dart, so a default value isn't possible here —
/// both call sites must pass their provider explicitly. This was previously
/// hardcoded to [hrSearchQueryProvider] with no param at all, which meant
/// reusing this widget on the Onboarding screen filtered against the wrong
/// provider — the field updated visually but had no effect on the list,
/// since `hrFilteredOnboardingEntriesProvider` watches a separate
/// `hrOnboardingSearchQueryProvider`. Onboarding now passes that provider
/// explicitly.
class EmployeeSearchBar extends ConsumerStatefulWidget {
  const EmployeeSearchBar({
    super.key,
    required this.queryProvider,
    this.hintText = 'Search employees by name, ID, or department...',
  });

  final StateProvider<String> queryProvider;
  final String hintText;

  @override
  ConsumerState<EmployeeSearchBar> createState() => _EmployeeSearchBarState();
}

class _EmployeeSearchBarState extends ConsumerState<EmployeeSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(widget.queryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasQuery = ref.watch(widget.queryProvider).isNotEmpty;

    return TextField(
      controller: _controller,
      style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
      onChanged: (value) =>
          ref.read(widget.queryProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
        prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
        suffixIcon: hasQuery
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () {
                  _controller.clear();
                  ref.read(widget.queryProvider.notifier).state = '';
                },
              )
            : null,
        filled: true,
        fillColor: cs.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.secondary, width: 1.5),
        ),
      ),
    );
  }
}
