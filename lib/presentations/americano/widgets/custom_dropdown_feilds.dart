import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';

import '../../../configs/app_colors.dart';
class CustomDropdownField extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double height;
  final IconData? defaultIcon;
  final Map<String, IconData>? itemIcons;
  final String bottomSheetTitle;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.height = 50,
    this.defaultIcon,
    this.itemIcons,
    this.bottomSheetTitle = 'Select Item',
  });

  void _showBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Title
            Text(
              bottomSheetTitle,
              style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Divider(color: AppColors.textColor.withAlpha(40),thickness: 1,),

            // Scrollable list
            Flexible(
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        itemIcons?[e] ?? defaultIcon ?? Icons.arrow_right,
                        color: AppColors.textColor,
                      ),
                      title: Text(e, style: Get.textTheme.labelLarge),
                      onTap: () {
                        Get.back();
                        onChanged(e);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          border: Border.all(color: Colors.grey,width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value?.isNotEmpty == true ? value! : (hint ?? ''),
                style: Get.textTheme.labelLarge?.copyWith(
                  color:AppColors.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textColor),
          ],
        ),
      ),
    );
  }
}
