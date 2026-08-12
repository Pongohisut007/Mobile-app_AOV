import 'package:flutter/material.dart';

class CommunityCategoryHeader extends StatelessWidget {
  const CommunityCategoryHeader({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final bool isTablet = size.shortestSide >= 600;
    final bool isLandscape = size.width > size.height;

    // --------------------------------------------------
    // Responsive Header Height
    // --------------------------------------------------

    double expandedHeight;

    if (isTablet) {
      // iPad
      expandedHeight = isLandscape ? 300 : 400;
    } else {
      // Phone
      if (size.width >= 400) {
        expandedHeight = 270;
      } else {
        expandedHeight = 240;
      }
    }

    // --------------------------------------------------
    // Responsive Icon Size
    // --------------------------------------------------

    final double iconSize = isTablet ? 28 : 24;

    // --------------------------------------------------
    // Responsive Overlay
    // --------------------------------------------------

    final double overlayOpacity = isTablet ? 0.18 : 0.22;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,

      backgroundColor: const Color.fromARGB(
        255,
        245,
        244,
        244,
      ),

      iconTheme: IconThemeData(
        color: Colors.white,
        size: iconSize,
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // --------------------------------------------------
              // Background Image
              // --------------------------------------------------

              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,

                // Loading
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: isTablet ? 32 : 24,
                      height: isTablet ? 32 : 24,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },

                // Error
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: isTablet ? 56 : 42,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),

              // --------------------------------------------------
              // Dark Overlay
              // --------------------------------------------------

              Container(
                color: Colors.black.withValues(
                  alpha: overlayOpacity,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}