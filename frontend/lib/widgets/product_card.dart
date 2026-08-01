import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build the UI for the product card
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: onTap, // Trigger the onTap callback when the card is tapped
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the product image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8.0),
              ), // BorderRadius.vertical
              child: Image.network(
                product.image,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ), // Image.network
            ), // ClipRRect
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the product title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ), // TextStyle
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ), // Text
                  const SizedBox(height: 4),
                  // Display the product price
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ), // TextStyle
                  ), // Text
                ],
              ), // Column
            ), // Padding
          ],
        ), // Column
      ), // InkWell
    ); // Card
  }
}
