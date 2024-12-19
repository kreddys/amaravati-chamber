import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/widgets/form_wrapper.dart';
import 'package:amaravati_chamber/core/widgets/app_card.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_address_button.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_adress_email_input.dart';

class ChangeEmailAddressForm extends StatelessWidget {
  const ChangeEmailAddressForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormWrapper(
      child: Center(
        child: SingleChildScrollView(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: Spacing.s24),
                _buildTitle(context),
                const SizedBox(height: Spacing.s32),
                _buildSubtitle(context),
                const SizedBox(height: Spacing.s16),
                const ChangeEmailAddressEmailInput(),
                const SizedBox(height: Spacing.s16),
                const ChangeEmailAddressButton(),
              ],
            ),
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

  Widget _buildSubtitle(BuildContext context) => Column(
        children: [
          Text(
            "Change email address",
            style: context.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.s16),
          const Text(
            "You will be required to confirm an email change to new email address.",
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      );
}
