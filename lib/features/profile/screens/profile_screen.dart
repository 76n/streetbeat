import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        appBar: AppBar(title: const Text('Profile')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading;
              final email = switch (state) {
                AuthAuthenticated u => u.user.email ?? '',
                _ => '',
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: loading
                        ? null
                        : () => context.read<AuthBloc>().add(
                              const AuthSignOut(),
                            ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text('Sign out'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
