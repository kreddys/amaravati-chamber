import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_email_input.dart';
import 'package:amaravati_chamber/core/widgets/app_card.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_header.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Form(
      // Add Form widget if you need form validation
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Spacing.s16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoginHeader(),
                  SizedBox(height: Spacing.s32),
                  LoginEmailInput(),
                  SizedBox(height: Spacing.s16),
                  LoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
