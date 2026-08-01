import 'package:flutter/material.dart';

class Community extends StatelessWidget {
  const Community({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          "community Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
