import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_address_button.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_adress_email_input.dart';
import 'package:amaravati_chamber/core/widgets/auth_form_layout.dart';

class ChangeEmailAddressForm extends StatelessWidget {
  const ChangeEmailAddressForm({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      logo: Image.asset(
        'assets/images/logo.png',
        height: 100,
        width: 100,
      ),
      title: Text(
        "Amaravati Chamber",
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
      subtitle: Column(
        children: [
          const Text(
            "You will be required to confirm an email change to new email address.",
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      formContent: const [
        ChangeEmailAddressEmailInput(),
        SizedBox(height: Spacing.s16),
        ChangeEmailAddressButton(),
      ],
    );
  }
}
