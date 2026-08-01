import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Row(
              children: [
                Icon(Icons.search),
                SizedBox(width: 10),
                Text(
                  "Search food",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.notifications_none),
        )
      ],
    );
  }
}