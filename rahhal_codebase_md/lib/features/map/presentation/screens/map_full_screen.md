# ملف كود Dart: lib\features\map\presentation\screens\map_full_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../cubit/map_cubit.dart';
import '../widgets/map_tab.dart';

class MapFullScreen extends StatelessWidget {
  final String tripId;

  const MapFullScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MapCubit>()..loadMapData(tripId),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          title: Text(
            'مسار الرحلة الكامل',
            style: AppTextStyles.headlineMedium,
          ),
          centerTitle: true,
        ),
        body: MapTab(tripId: tripId),
      ),
    );
  }
}

```
