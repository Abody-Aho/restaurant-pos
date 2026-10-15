import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../pos/data/models/category.dart';
import '../../../pos/data/models/item.dart';
import '../../../pos/data/models/item_option.dart';
import '../../../pos/presentation/providers/menu_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

class MenuManagementPage extends ConsumerWidget {
  static const uuid = Uuid();

  const MenuManagementPage({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم القسم (مثل: وجبات عائلية)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final newCat = Category(
                id: uuid.v4(),
                name: nameController.text.trim(),
                iconName: 'restaurant',
                sortOrder: 10,
              );
              await ref.read(menuNotifierProvider.notifier).addCategory(newCat);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showItemFormDialog(
    BuildContext context,
    WidgetRef ref, {
    Item? existingItem,
  }) {
    final themeState = ref.read(themeSettingsProvider);
    final primaryColor = themeState.accentColor.color;
    final categories = ref.read(menuNotifierProvider).categories;

    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final priceController = TextEditingController(
      text: existingItem != null ? '${existingItem.basePrice}' : '',
    );
    String? selectedCatId =
        existingItem?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    String? imagePath = existingItem?.imagePath;
    bool isTopSeller = existingItem?.isTopSeller ?? false;

    // Temporary options lists
    final List<ItemOption> sizes = existingItem?.sizes.toList() ?? [];
    final List<ItemOption> flavors = existingItem?.flavors.toList() ?? [];
    final List<ItemOption> extras = existingItem?.extras.toList() ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              existingItem == null ? 'إضافة صنف جديد' : 'تعديل الصنف',
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    DropdownButtonFormField<String>(
                      value: selectedCatId,
                      decoration: const InputDecoration(
                        labelText: 'القسم',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCatId = val),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصنف',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'السعر الأساسي',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Image Picker Row
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              setState(() => imagePath = picked.path);
                            }
                          },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('اختيار صورة الصنف'),
                        ),
                        const SizedBox(width: 12),
                        if (imagePath != null)
                          const Text(
                            'تم اختيار صورة ✓',
                            style: TextStyle(color: AppColors.success),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('صنف الأكثر مبيعاً (Top Seller)'),
                      value: isTopSeller,
                      activeColor: primaryColor,
                      onChanged: (val) => setState(() => isTopSeller = val),
                    ),

                    const Divider(),
                    const Text(
                      'الأحجام (Sizes)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildOptionGroupManager(
                      groupName: 'size',
                      options: sizes,
                      primaryColor: primaryColor,
                      onAdd: (opt) => setState(() => sizes.add(opt)),
                      onRemove: (id) =>
                          setState(() => sizes.removeWhere((o) => o.id == id)),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'النكهات (Flavors)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildOptionGroupManager(
                      groupName: 'flavor',
                      options: flavors,
                      primaryColor: primaryColor,
                      onAdd: (opt) => setState(() => flavors.add(opt)),
                      onRemove: (id) => setState(
                        () => flavors.removeWhere((o) => o.id == id),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'الإضافات (Extras)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildOptionGroupManager(
                      groupName: 'extra',
                      options: extras,
                      primaryColor: primaryColor,
                      onAdd: (opt) => setState(() => extras.add(opt)),
                      onRemove: (id) =>
                          setState(() => extras.removeWhere((o) => o.id == id)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      priceController.text.trim().isEmpty ||
                      selectedCatId == null)
                    return;

                  final basePrice =
                      double.tryParse(priceController.text.trim()) ?? 0.0;
                  final itemId = existingItem?.id ?? uuid.v4();

                  final allOptions = [...sizes, ...flavors, ...extras].map((
                    opt,
                  ) {
                    return opt.copyWith(itemId: itemId);
                  }).toList();

                  final item = Item(
                    id: itemId,
                    categoryId: selectedCatId!,
                    name: nameController.text.trim(),
                    basePrice: basePrice,
                    imagePath: imagePath,
                    isTopSeller: isTopSeller,
                    options: allOptions,
                  );

                  if (existingItem == null) {
                    await ref.read(menuNotifierProvider.notifier).addItem(item);
                  } else {
                    await ref
                        .read(menuNotifierProvider.notifier)
                        .updateItem(item);
                  }

                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                },
                child: const Text(
                  'حفظ التغييرات',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionGroupManager({
    required String groupName,
    required List<ItemOption> options,
    required Color primaryColor,
    required ValueChanged<ItemOption> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    final optNameCtrl = TextEditingController();
    final optPriceCtrl = TextEditingController();

    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            return Chip(
              label: Text('${opt.optionName} (+${opt.priceModifier})'),
              onDeleted: () => onRemove(opt.id),
            );
          }).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: optNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'الاسم (مثل: كبير / دجاج / جبن)',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: optPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'فارق السعر'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor),
              onPressed: () {
                if (optNameCtrl.text.trim().isEmpty) return;
                final mod = double.tryParse(optPriceCtrl.text.trim()) ?? 0.0;
                onAdd(
                  ItemOption(
                    id: uuid.v4(),
                    itemId: '',
                    groupName: groupName,
                    optionName: optNameCtrl.text.trim(),
                    priceModifier: mod,
                  ),
                );
                optNameCtrl.clear();
                optPriceCtrl.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuNotifierProvider);
    final themeState = ref.watch(themeSettingsProvider);
    final restaurantInfo = ref.watch(restaurantInfoProvider);
    final primaryColor = themeState.accentColor.color;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        title: const Text('إدارة قائمة الأصناف والأقسام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'إضافة قسم',
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة صنف',
            onPressed: () => _showItemFormDialog(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Category Action Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...menuState.categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(cat.name),
                        onDeleted: () async {
                          await ref
                              .read(menuNotifierProvider.notifier)
                              .deleteCategory(cat.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items Management Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: menuState.items.length,
                itemBuilder: (context, index) {
                  final item = menuState.items[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Switch(
                                value: item.isActive,
                                activeThumbColor: primaryColor,
                                onChanged: (val) {
                                  ref
                                      .read(menuNotifierProvider.notifier)
                                      .toggleItemActive(item.id, val);
                                },
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(
                              item.basePrice,
                              currency: restaurantInfo.currency,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الأحجام: ${item.sizes.length} | النكهات: ${item.flavors.length} | الإضافات: ${item.extras.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showItemFormDialog(
                                  context,
                                  ref,
                                  existingItem: item,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                onPressed: () async {
                                  final bool?
                                  isConfirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext ctx) {
                                      return Dialog(
                                        shape: BeveledRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(5),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 28,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              ctx,
                                            ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              24.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.12,
                                                ),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            width: 450,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Colors.red,
                                                    size: 50,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  'تأكيد الحذف',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // نص الرسالة
                                                Text(
                                                  'هل أنت متأكد من رغبتك في حذف هذا العنصر؟ لا يمكن التراجع عن هذه الخطوة.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    OutlinedButton(
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(false),
                                                      child: Text(
                                                        'إلغاء',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 20),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red.shade600,
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true);
                                                      },
                                                      child: const Text(
                                                        'حذف',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  if (isConfirmed == true) {
                                    await ref
                                        .read(menuNotifierProvider.notifier)
                                        .deleteItem(item.id);
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'تم حذف "${item.name}" بنجاح',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          elevation: 3,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة صنف جديد'),
        onPressed: () => _showItemFormDialog(context, ref),
      ),
    );
  }
}
