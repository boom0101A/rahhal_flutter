import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../domain/entities/document_entity.dart';
import '../cubit/document_cubit.dart';
import '../cubit/document_state.dart';

class DocumentsScreen extends StatefulWidget {
  final String tripId;
  const DocumentsScreen({super.key, required this.tripId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String _getDocTypeLabel(BuildContext context, String docType) =>
      AppStrings.of(context).documentTypeLabelFor(docType);

  IconData _getDocTypeIcon(String docType) {
    return switch (docType) {
      'passport' => Icons.badge_rounded,
      'visa' => Icons.assignment_turned_in_rounded,
      'ticket' => Icons.local_activity_rounded,
      'booking' => Icons.hotel_rounded,
      _ => Icons.description_rounded,
    };
  }

  Color _getDocTypeColor(String docType) {
    return switch (docType) {
      'passport' => AppColors.accentAmber,
      'visa' => AppColors.accentTurquoise,
      'ticket' => const Color(0xFF9B7FD4),
      'booking' => const Color(0xFF4CAF50),
      _ => AppColors.adaptiveTextSecondary(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<DocumentCubit>()..loadDocuments(widget.tripId),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                onPressed: () => context.go('/trip/${widget.tripId}'),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0D1B2A),
                  size: 20,
                ),
              ),
              title: Text(
                AppStrings.of(context).documentsTitle,
                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: BlocBuilder<DocumentCubit, DocumentsState>(
              builder: (context, state) {
                if (state is DocumentsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accentAmber),
                  );
                }
                if (state is DocumentsError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<DocumentCubit>().loadDocuments(widget.tripId),
                  );
                }
                if (state is DocumentsLoaded) {
                  final docs = state.documents;
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📁', style: TextStyle(fontSize: 72))
                                .animate()
                                .scale(duration: 600.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 20),
                            Text(
                              AppStrings.of(context).documentsEmptyTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.adaptiveTextPrimary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.of(context).documentsEmptySubtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.adaptiveTextSecondary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            GradientButton(
                              label: AppStrings.of(context).documentAddNew,
                              icon: Icons.add_rounded,
                              onPressed: () => _showAddDocumentSheet(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: docs.length,
                        itemBuilder: (ctx, idx) {
                          final doc = docs[idx];
                          return _buildDocumentCard(context, doc);
                        },
                      ),
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: GradientButton(
                          label: AppStrings.of(context).documentAddNew,
                          icon: Icons.add_rounded,
                          onPressed: () => _showAddDocumentSheet(context),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentEntity doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getDocTypeColor(doc.docType);
    final hasExpiry = doc.expiryDate != null;
    final isExpired = hasExpiry && doc.expiryDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getDocTypeIcon(doc.docType), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark ? AppColors.adaptiveTextPrimary(context) : const Color(0xFF0D1B2A),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDocTypeLabel(context, doc.docType),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, doc),
                ),
              ],
            ),
            if (doc.notes != null && doc.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: AppColors.adaptiveBorder(context), height: 1),
              const SizedBox(height: 8),
              Text(
                doc.notes!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.adaptiveTextSecondary(context) : const Color(0xFF4B5563),
                ),
              ),
            ],
            if (hasExpiry) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 14,
                    color: isExpired ? AppColors.error : AppColors.adaptiveTextSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.of(context).documentExpiryOn(DateFormat('yyyy/MM/dd').format(doc.expiryDate!)),
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? AppColors.error : AppColors.adaptiveTextSecondary(context),
                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isExpired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppStrings.of(context).documentExpired,
                        style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (doc.filePath != null && doc.filePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _viewDocumentImage(context, doc.filePath!, doc.title),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.adaptiveBorder(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(doc.filePath!),
                      fit: doc.docType == 'ticket' ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (ctx, e, s) => Container(
                        color: Colors.black12,
                        child: Center(
                          child: Icon(Icons.broken_image_rounded, color: AppColors.adaptiveTextSecondary(ctx)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  void _viewDocumentImage(BuildContext context, String path, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.5,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentEntity doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveBgCard(context),
        title: Text(AppStrings.of(context).documentDeleteTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppStrings.of(context).documentDeleteConfirm(doc.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentCubit>().deleteDocument(widget.tripId, doc.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String docType = 'passport';
    DateTime? expiryDate;
    String? selectedFilePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.adaptiveBgCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.of(context).documentAddTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.of(context).documentTitleLabel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: docType,
                      decoration: InputDecoration(labelText: AppStrings.of(context).documentTypeLabel),
                      items: [
                        DropdownMenuItem(value: 'passport', child: Text(AppStrings.of(context).documentTypeLabelFor('passport'))),
                        DropdownMenuItem(value: 'visa', child: Text(AppStrings.of(context).documentTypeLabelFor('visa'))),
                        DropdownMenuItem(value: 'ticket', child: Text(AppStrings.of(context).documentTypeLabelFor('ticket'))),
                        DropdownMenuItem(value: 'booking', child: Text(AppStrings.of(context).documentTypeLabelFor('booking'))),
                        DropdownMenuItem(value: 'other', child: Text(AppStrings.of(context).documentTypeLabelFor('other'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => docType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.of(context).documentNotesLabel,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        expiryDate == null
                            ? AppStrings.of(context).documentExpiryOptional
                            : AppStrings.of(context).documentExpiryOn(DateFormat('yyyy/MM/dd').format(expiryDate!)),
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.accentAmber),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setSheetState(() => expiryDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(AppStrings.of(context).documentAttachmentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedFilePath != null) ...[
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(selectedFilePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                onPressed: () {
                                  setSheetState(() => selectedFilePath = null);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final file = await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );
                                if (file != null) {
                                  setSheetState(() => selectedFilePath = file.path);
                                }
                              },
                              icon: const Icon(Icons.photo_library_rounded),
                              label: Text(AppStrings.of(context).documentPickGallery),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final file = await _imagePicker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 85,
                                );
                                if (file != null) {
                                  setSheetState(() => selectedFilePath = file.path);
                                }
                              },
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: Text(AppStrings.of(context).documentPickCamera),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: AppStrings.of(context).documentSave,
                      icon: Icons.check_rounded,
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.of(context).documentTitleRequired)),
                          );
                          return;
                        }
                        
                        final doc = DocumentEntity(
                          id: const Uuid().v4(),
                          tripId: widget.tripId,
                          docType: docType,
                          title: titleCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          expiryDate: expiryDate,
                          filePath: selectedFilePath,
                          createdAt: DateTime.now(),
                        );

                        context.read<DocumentCubit>().addDocument(doc);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
