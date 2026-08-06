import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/food_repository.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({super.key, required this.foodsId});

  final String foodsId;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color accentOrange = Color(0xFFF57C00);

  late Future<Food> _foodFuture;

  @override
  void initState() {
    super.initState();
    _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
  }

  void _reload() {
    setState(() {
      _foodFuture = FoodRepository().fetchFoodById(widget.foodsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag_outlined, color: primaryRed),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryRed, accentOrange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Buy Now",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Food>(
        future: _foodFuture,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryRed,
                strokeWidth: 3,
              ),
            );
          }

          if (state.hasError || !state.hasData) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: accentOrange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.error?.toString() ?? 'ไม่พบข้อมูลเมนูนี้',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                            ),
                            child: const Text("ย้อนกลับ"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _reload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("ลองอีกครั้ง"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final food = state.data!;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // รูปอาหาร
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        decoration: const BoxDecoration(
                          color: Color(0xfffff3e0), // ส้มอ่อน แทนเทา
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: primaryRed),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: Center(
                          child: Hero(
                            tag: food.idfoods,
                            child: food.filePathImage.isEmpty
                                ? _imagePlaceholder()
                                : Image.network(
                                    food.filePathImage,
                                    height: 240,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 240,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: primaryRed,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 33),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xfffff3e0), // ส้มอ่อน แทนเทา
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _info(_minutes(food.preparationMinutes), "prep"),
                              _info(_minutes(food.cookingMinutes), "cook"),
                              _info(
                                food.servingCount?.toString() ?? "-",
                                "servings",
                              ),
                              _info(food.difficulty ?? "-", "level"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          food.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const SizedBox(
      height: 240,
      child: Center(
        child: Icon(Icons.restaurant, size: 64, color: accentOrange),
      ),
    );
  }

  String _minutes(int? value) => value == null ? "-" : "$value น.";

  Widget _info(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}