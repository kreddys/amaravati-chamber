import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 100,
          width: 100,
        ),
        const SizedBox(height: Spacing.s24),
        Text(
          "Amaravati Chamber",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
