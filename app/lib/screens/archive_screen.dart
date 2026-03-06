import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/folder_tile.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.8),
                border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Archive',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.slate900),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.slate900),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.create_new_folder, color: AppColors.white),
                            label: Text(
                              'New Folder',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primaryShadow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.upload_file, color: AppColors.primary),
                            label: Text(
                              'Upload',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'YOUR FOLDERS',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Folder list
                    const FolderTile(
                      icon: Icons.folder_outlined,
                      name: 'Recent Prescriptions',
                      modifiedDate: 'Modified 2 days ago',
                      itemCount: '12 items',
                    ),
                    const SizedBox(height: 12),
                    const FolderTile(
                      icon: Icons.science_outlined,
                      name: 'Lab Results',
                      modifiedDate: 'Modified 1 week ago',
                      itemCount: '8 items',
                    ),
                    const SizedBox(height: 12),
                    const FolderTile(
                      icon: Icons.medication_outlined,
                      name: 'Chronic Meds',
                      modifiedDate: 'Modified 3 hours ago',
                      itemCount: '4 items',
                    ),
                    const SizedBox(height: 12),
                    const FolderTile(
                      icon: Icons.vaccines_outlined,
                      name: 'Vaccination Records',
                      modifiedDate: 'Modified Jan 2024',
                      itemCount: '2 items',
                    ),

                    const SizedBox(height: 32),

                    // Storage card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cloud Storage',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                              Text(
                                '65% Used',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: LinearProgressIndicator(
                              value: 0.65,
                              backgroundColor: AppColors.slate200,
                              color: AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upgrade for more space and automated document sorting.',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom nav
            BottomNavBar(
              currentTab: NavTab.archive,
              onTabSelected: (tab) => _navigateToTab(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, NavTab tab) {
    switch (tab) {
      case NavTab.home:
        Navigator.pushReplacementNamed(context, '/welcome');
        break;
      case NavTab.chat:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case NavTab.alerts:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case NavTab.archive:
        break;
    }
  }
}
