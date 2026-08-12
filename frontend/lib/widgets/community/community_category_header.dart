import 'package:flutter/material.dart';

class CommunityCategoryHeader extends StatelessWidget {
  const CommunityCategoryHeader({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: const Color.fromARGB(255, 245, 244, 244),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          );
        },
      ),
    );
  }
}