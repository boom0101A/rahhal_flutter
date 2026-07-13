import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
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

  String _getDocTypeLabel(BuildContext context, String docType) {
    return switch (docType) {
      'passport' => 'جواز سفر / هوية',
      'visa' => 'تأشيرة دخول',
      'ticket' => 'تذكرة سفر',
      'booking' => 'حجز إقامة / سيارة',
      _ => 'مستند آخر',
    };
  }

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
      _ => AppColors.textSecondary,
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
              title: const Text(
                'مستندات السفر',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
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
                            const Text(
                              'لا توجد مستندات بعد',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'احفظ جوازات سفرك، التأشيرات، وتذاكر الطيران للوصول السريع إليها أثناء السفر.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            GradientButton(
                              label: 'إضافة مستند جديد',
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
                          label: 'إضافة مستند جديد',
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
                          color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDocTypeLabel(context, doc.docType),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              Text(
                doc.notes!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : const Color(0xFF4B5563),
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
                    color: isExpired ? AppColors.error : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تاريخ الانتهاء: ${DateFormat('yyyy/MM/dd').format(doc.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? AppColors.error : AppColors.textSecondary,
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
                      child: const Text(
                        'منتهي',
                        style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
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
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(doc.filePath!),
                      fit: doc.docType == 'ticket' ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (ctx, e, s) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
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
        backgroundColor: AppColors.bgCard,
        title: const Text('حذف المستند', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف "${doc.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentCubit>().deleteDocument(widget.tripId, doc.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
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
      backgroundColor: AppColors.bgCard,
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
                        const Text(
                          'إضافة مستند سفر جديد',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      decoration: const InputDecoration(
                        labelText: 'عنوان المستند (مثال: جواز سفر أحمد)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: docType,
                      decoration: const InputDecoration(labelText: 'نوع المستند'),
                      items: const [
                        DropdownMenuItem(value: 'passport', child: Text('جواز سفر / هوية')),
                        DropdownMenuItem(value: 'visa', child: Text('تأشيرة دخول')),
                        DropdownMenuItem(value: 'ticket', child: Text('تذكرة سفر')),
                        DropdownMenuItem(value: 'booking', child: Text('حجز إقامة / سيارة')),
                        DropdownMenuItem(value: 'other', child: Text('مستند آخر')),
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
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية (اختياري)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        expiryDate == null
                            ? 'تاريخ الانتهاء (اختياري)'
                            : 'تاريخ الانتهاء: ${DateFormat('yyyy/MM/dd').format(expiryDate!)}',
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
                    const Text('صورة المستند / المرفق', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              label: const Text('المعرض'),
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
                              label: const Text('الكاميرا'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'حفظ المستند',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال عنوان للمستند')),
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
