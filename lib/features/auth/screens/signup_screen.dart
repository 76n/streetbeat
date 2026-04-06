import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/activity_type.dart';
import '../models/race_goal_option.dart';
import '../models/weekly_goal_runs.dart';
import '../widgets/auth_gradient_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  ActivityType _activity = ActivityType.runner;
  WeeklyGoalRuns _weekly = WeeklyGoalRuns.three;
  RaceGoalOption _race = RaceGoalOption.none;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthError,
      listener: (context, state) {
        final msg = (state as AuthError).message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.card,
            content: Text(msg),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login'),
          ),
          title: const Text('Create account'),
        ),
        extendBodyBehindAppBar: true,
        body: AuthGradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join StreetBeat',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us how you move — we will tune the experience.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Your name',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!v.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'I am a',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ActivityType>(
                      segments: const [
                        ButtonSegment(
                          value: ActivityType.runner,
                          label: Text('Runner'),
                          icon: Icon(Icons.directions_run, size: 18),
                        ),
                        ButtonSegment(
                          value: ActivityType.walker,
                          label: Text('Walker'),
                          icon: Icon(Icons.directions_walk, size: 18),
                        ),
                      ],
                      selected: {_activity},
                      onSelectionChanged: (s) {
                        setState(() => _activity = s.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Weekly goal',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WeeklyGoalRuns.values.map((g) {
                        final selected = _weekly == g;
                        return ChoiceChip(
                          label: Text('${g.count} / week'),
                          selected: selected,
                          onSelected: (_) => setState(() => _weekly = g),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.35),
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Race goal (optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RaceGoalOption.values.map((r) {
                        final selected = _race == r;
                        return FilterChip(
                          label: Text(r.label),
                          selected: selected,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _race = r;
                              } else if (_race == r) {
                                _race = RaceGoalOption.none;
                              }
                            });
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.35),
                          checkmarkColor: AppColors.textPrimary,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final loading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          AuthSignUp(
                                            name: _name.text,
                                            email: _email.text,
                                            password: _password.text,
                                            activityType: _activity,
                                            weeklyGoalRuns: _weekly,
                                            raceGoal: _race,
                                          ),
                                        );
                                  }
                                },
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Text('Create Account'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
