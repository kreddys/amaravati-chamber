import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amaravati_chamber/core/widgets/content_card.dart';
import 'package:amaravati_chamber/features/place_listings/presentation/cubit/place_listings_state.dart';
import '../../../../core/widgets/vote_buttons.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final Function(String, VoteType?) onVote;

  const PlaceCard({
    required this.place,
    required this.onVote, // Add this line
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: place.name ?? 'Unnamed Place',
      description: place.address ?? 'No address available',
      date: null,
      tags: place.category != null ? [place.category!] : [],
      onTap: () {
        // TODO: Navigate to detailed Place profile
      },
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Phone Icon
          _buildCircularIcon(
            context: context,
            icon: Icons.phone,
            isAvailable: place.validPhones.isNotEmpty,
            onTap: place.validPhones.isNotEmpty
                ? () async {
                    final url = Uri.parse('tel:${place.validPhones.first}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8), // Added spacing

          // Website Icon
          _buildCircularIcon(
            context: context,
            icon: Icons.language,
            isAvailable: place.validWebsites.isNotEmpty,
            onTap: place.validWebsites.isNotEmpty
                ? () async {
                    final url = Uri.parse(place.validWebsites.first);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8), // Added spacing

          // Facebook Icon
          _buildCircularIcon(
            context: context,
            icon: Icons.facebook,
            isAvailable: place.validSocials.any((s) => s.contains('facebook')),
            onTap: place.validSocials.any((s) => s.contains('facebook'))
                ? () async {
                    final social = place.validSocials
                        .firstWhere((s) => s.contains('facebook'));
                    final url = Uri.parse(social);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8), // Added spacing

          // Google Icon
          _buildCircularIcon(
            context: context,
            icon: Icons.public,
            isAvailable: false,
            onTap: null,
          ),

          const SizedBox(width: 16), // Added spacing
          // Add vote buttons
          VoteButtons(
            entityId: place.uuid ?? '',
            userVote: place.userVote ?? 0,
            upvotes: place.upvotes ?? 0,
            downvotes: place.downvotes ?? 0,
            onVote: (voteType) => onVote(place.uuid ?? '', voteType),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIcon({
    required BuildContext context,
    required IconData icon,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor.withOpacity(0.1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Icon(
                  icon, // Always show the actual icon
                  size: 20,
                  color: isAvailable
                      ? Colors.white
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
          if (!isAvailable)
            Transform.rotate(
              angle: -0.785398, // 45 degrees in radians
              child: Container(
                width: 40,
                height: 2,
                color: Theme.of(context).disabledColor,
              ),
            ),
        ],
      ),
    );
  }
}
