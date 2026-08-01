import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      height: 50,
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
              ),
              const SizedBox(height: 20),
              // Banner
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Text(
                              "Free Delivery\nFor Spaghetti",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Up to 3 times per day",
                              style: TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lime,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Order Now"),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9",
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Categories
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    CategoryItem(Icons.lunch_dining, "Burger"),
                    CategoryItem(Icons.set_meal, "Chicken"),
                    CategoryItem(Icons.fastfood, "Fries"),
                    CategoryItem(Icons.local_drink, "Drink"),
                    CategoryItem(Icons.icecream, "Dessert"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Recommended",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See More",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 4,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .68,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, index) {
                  return const FoodCard();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const CategoryItem(this.icon, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
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