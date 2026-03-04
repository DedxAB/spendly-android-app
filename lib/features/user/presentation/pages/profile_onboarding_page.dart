import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/features/user/data/repositories/user_profile_repository_impl.dart';
import 'package:spendly/features/user/presentation/providers/user_profile_provider.dart';

class ProfileOnboardingPage extends ConsumerStatefulWidget {
  const ProfileOnboardingPage({super.key});

  @override
  ConsumerState<ProfileOnboardingPage> createState() =>
      _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends ConsumerState<ProfileOnboardingPage> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _isSubmitting = true);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final fallback = profile?.name ?? 'User';
    await ref
        .read(userProfileRepositoryProvider)
        .completeOnboarding(
          name: _nameController.text.trim().isEmpty
              ? fallback
              : _nameController.text.trim(),
        );
    if (mounted) context.go('/home');
  }

  Future<void> _skip() async {
    setState(() => _isSubmitting = true);
    await ref.read(userProfileRepositoryProvider).completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'What should we call you?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isSubmitting ? null : _continue(),
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _continue,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _skip,
                  child: const Text('Skip for now'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
