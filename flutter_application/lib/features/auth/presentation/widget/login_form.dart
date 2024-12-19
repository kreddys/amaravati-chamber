import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_email_input.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_header.dart';
import 'package:amaravati_chamber/core/widgets/auth_form_layout.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormLayout(
      title: LoginHeader(),
      formContent: [
        LoginEmailInput(),
        SizedBox(height: Spacing.s16),
        LoginButton(),
      ],
    );
  }
}
