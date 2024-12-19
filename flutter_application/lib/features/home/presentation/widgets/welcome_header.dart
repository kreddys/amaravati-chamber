// lib/features/home/presentation/widgets/welcome_header.dart
import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/widgets/app_card.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.s16),
          Text(
            'Amaravati Chamber is your trusted source for local news and updates from Amaravati, Andhra Pradesh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}
