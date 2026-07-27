import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/injection.dart';
import '../../features/auth/data/local_avatar_service.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// The user's picture, wherever it needs to appear (Profile header, Settings).
///
/// Resolution order: a locally-saved photo (see [LocalAvatarService]) takes
/// priority over Google's [UserEntity.photoUrl], which takes priority over a
/// plain initials circle. Rebuilds automatically whenever the local avatar
/// changes, so picking a new photo on the Profile screen is reflected on
/// Settings too without any manual refresh wiring.
class UserAvatar extends StatelessWidget {
  final UserEntity? user;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocalAvatarService.version,
      builder: (context, _, __) {
        return FutureBuilder(
          // Keyed by `version` so switching the notifier restarts the future
          // instead of FutureBuilder reusing a completed one from before.
          key: ValueKey(LocalAvatarService.version.value),
          future: sl<LocalAvatarService>().currentAvatar(),
          builder: (context, snapshot) {
            final localFile = snapshot.data;
            final photoUrl = user?.photoUrl;
            final initials = user?.initials ?? '؟';

            ImageProvider? image;
            if (localFile != null) {
              image = FileImage(localFile);
            } else if (photoUrl != null && photoUrl.isNotEmpty) {
              image = NetworkImage(photoUrl);
            }

            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? AppColors.accentAmber,
              backgroundImage: image,
              child: image == null
                  ? Text(
                      initials,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.black,
                        fontSize: radius * 0.55,
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
