import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/widgets/email_text_field.dart';
import 'package:amaravati_chamber/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart';
import 'package:amaravati_chamber/core/value_objects/email_value_object.dart';

class ChangeEmailAddressEmailInput extends StatelessWidget {
  const ChangeEmailAddressEmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChangeEmailAddressCubit, ChangeEmailAddressState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return EmailTextField(
          onChanged: (email) =>
              context.read<ChangeEmailAddressCubit>().emailChanged(email),
          errorText: state.email.displayError?.message,
          textInputAction: TextInputAction.done,
        );
      },
    );
  }
}
