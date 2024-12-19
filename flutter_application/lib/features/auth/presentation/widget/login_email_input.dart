import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/widgets/email_text_field.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart';

/// An email input field widget for the login form
///
/// Uses [EmailTextField] component and integrates with [LoginCubit]
/// for state management and validation.
class LoginEmailInput extends StatelessWidget {
  const LoginEmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, String?>(
      selector: (state) =>
          state.email.displayError != null ? "Invalid email address" : null,
      builder: (context, errorText) {
        return EmailTextField(
          onChanged: context.read<LoginCubit>().emailChanged,
          textInputAction: TextInputAction.done,
          errorText: errorText,
        );
      },
    );
  }
}
