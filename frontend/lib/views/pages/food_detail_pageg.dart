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
    _foodFuture = FoodRepository().fetchFoods().then((foods) {
      return foods.firstWhere((p) => p.idfoods == widget.foodsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Detail - ID: ${widget.foodsId}')),
      
    );
  }
}
