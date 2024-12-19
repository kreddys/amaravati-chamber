import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/widgets/form_wrapper.dart';
import 'package:amaravati_chamber/core/widgets/app_card.dart';

class AuthFormLayout extends StatelessWidget {
  final Widget? logo;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget> formContent;

  const AuthFormLayout({
    super.key,
    this.logo,
    this.title,
    this.subtitle,
    required this.formContent,
  });

  @override
  Widget build(BuildContext context) {
    return FormWrapper(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null) ...[
                    logo!,
                    const SizedBox(height: Spacing.s24),
                  ],
                  if (title != null) ...[
                    title!,
                    const SizedBox(height: Spacing.s32),
                  ],
                  if (subtitle != null) ...[
                    subtitle!,
                    const SizedBox(height: Spacing.s16),
                  ],
                  ...formContent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
