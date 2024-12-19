import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_email_input.dart';
import 'package:amaravati_chamber/core/widgets/app_card.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: Spacing.s24),
              _buildTitle(context),
              const SizedBox(height: Spacing.s32),
              const LoginEmailInput(),
              const SizedBox(height: Spacing.s16),
              const LoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Image.asset(
        'assets/images/logo.png',
        height: 100,
        width: 100,
      );

  Widget _buildTitle(BuildContext context) => Text(
        "Amaravati Chamber",
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      );
}
