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
      body: FutureBuilder<Food>(
        future: _foodFuture,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                        color: Colors.grey,
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
                            child: const Text("ย้อนกลับ"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _reload,
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
                          color: Color(0xfff5f5f5),
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
                            icon: const Icon(Icons.arrow_back),
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
                                    errorBuilder: (_, _, _) =>
                                        _imagePlaceholder(),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 240,
                                        child: Center(
                                          child: CircularProgressIndicator(),
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

                        const SizedBox(height: 8),

                        const SizedBox(height: 25),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
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
        child: Icon(Icons.restaurant, size: 64, color: Colors.grey),
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
