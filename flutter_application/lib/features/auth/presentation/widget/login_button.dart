import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/widgets/app_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart';
import 'package:formz/formz.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';

/// A button widget that handles login form submission
///
/// Uses [AppButton] component and integrates with [LoginCubit]
/// for state management. Disables when form is invalid and shows
/// loading state during submission.
class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, _LoginButtonState>(
      selector: (state) => _LoginButtonState(
        isLoading: state.status == FormzSubmissionStatus.inProgress,
        isValid: state.isValid,
      ),
      builder: (context, buttonState) {
        return AppButton(
          text: 'Continue',
          isLoading: buttonState.isLoading,
          onPressed: buttonState.isValid
              ? () {
                  context.closeKeyboard();
                  context.read<LoginCubit>().submitForm();
                }
              : null,
        );
      },
    );
  }
}

class _LoginButtonState {
  final bool isLoading;
  final bool isValid;

  const _LoginButtonState({
    required this.isLoading,
    required this.isValid,
  });
}
