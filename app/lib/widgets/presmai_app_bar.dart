import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PresmaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool showBorder;

  const PresmaiAppBar({
    super.key,
    this.title = 'PresMAI',
    this.leading,
    this.trailing,
    this.centerTitle = true,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        border: showBorder
            ? Border(bottom: BorderSide(color: AppColors.slate100, width: 1))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: centerTitle
            ? LayoutBuilder(
                builder: (context, _) {
                  // Center the title relative to the whole app bar width.
                  // This prevents "off-center" titles when `trailing` is wider
                  // than the (optional) `leading`.
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 48),
                          child: leading ?? const SizedBox.shrink(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 48),
                          alignment: Alignment.centerRight,
                          child: trailing ?? const SizedBox.shrink(),
                        ),
                      ),
                      Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    child: leading ?? const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    alignment: Alignment.centerRight,
                    child: trailing ?? const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
  }
}
