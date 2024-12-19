import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart';
import 'package:formz/formz.dart';
import 'package:amaravati_chamber/core/widgets/app_button.dart';

class ChangeEmailAddressButton extends StatelessWidget {
  const ChangeEmailAddressButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChangeEmailAddressCubit, ChangeEmailAddressState>(
      builder: (context, state) {
        return AppButton(
          text: 'Send instructions',
          isLoading: state.status.isInProgress,
          onPressed: state.isValid
              ? () {
                  context.closeKeyboard();
                  context.read<ChangeEmailAddressCubit>().submitForm();
                }
              : null,
        );
      },
    );
  }
}
