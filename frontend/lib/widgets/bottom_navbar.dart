import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_event.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final pageBloc = context.read<PageBloc>();
    final selectedPage = context.watch<PageBloc>().state.selectedPage;

    return BottomNavigationBar(
      currentIndex: selectedPage,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,

      onTap: (index) {
        pageBloc.add(PageChangeEvent(index));
      },

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "",
        ),
      ],
    );
  }
}