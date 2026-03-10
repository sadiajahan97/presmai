import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/folder_tile.dart';
import '../widgets/presmai_app_bar.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const PresmaiAppBar(
              title: 'Archive',
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
      case NavTab.chat:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case NavTab.alerts:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case NavTab.archive:
        break;
      case NavTab.profile:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
