import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import '../create_open_match_for_all_courts_controller.dart';

class ChangeLocationBottomSheet extends StatelessWidget {
  final CreateOpenMatchForAllCourtsController controller;
  
  const ChangeLocationBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Change Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            fadeDivider(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingLocations.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryColor),
                  );
                }

                final locations = controller.locationsData.value?.data;
                if (locations == null || locations.isEmpty) {
                  return const Center(child: Text('No locations available'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.3)),
                  itemBuilder: (context, index) {
                    final location = locations[index];

                    return Obx(() {
                      final isSelected = controller.selectedCityId.value == location.id;

                      return InkWell(
                        onTap: () {
                          controller.selectedCityId.value = location.id ?? '';
                        },
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xffE8ECFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  location.name ?? '',
                                  style: Get.textTheme.bodyLarge!.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppColors.primaryColor : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final isEnabled = controller.selectedCityId.value.isNotEmpty;
                final isLoading = controller.isUpdatingLocation.value;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled ? const Color(0xff2C3EBB) : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (isEnabled && !isLoading)
                        ? () async {
                      final selectedId = controller.selectedCityId.value;
                      final success = await controller.updateUserLocation(selectedId);
                      if (success) {
                        Navigator.pop(context);
                      }
                    }
                        : null,
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 16,
                        color: isEnabled ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
