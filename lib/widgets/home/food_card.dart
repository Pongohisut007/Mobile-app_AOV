import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.favorite_border,
              color: Colors.grey.shade400,
            ),
          ),
          Expanded(
            child: Center(
              child: Image.network(
                "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Cheese Burger",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Burger with Patty",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "\$4.50",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.lime,
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}