import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/widgets/app_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return AppButton(
          text: 'Continue',
          isLoading: state.status.isInProgress,
          onPressed: state.isValid
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
