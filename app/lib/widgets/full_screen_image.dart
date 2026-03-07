import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocal && !kIsWeb
                  ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildErrorState(),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildErrorState(),
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, color: Colors.white54, size: 64),
        SizedBox(height: 16),
        Text(
          'Failed to load image',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
