import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_event.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

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
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      showUnselectedLabels: true,

      onTap: (index) {
        pageBloc.add(PageChangeEvent(index));
      },

      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home_rounded),
          label: context.l10n.navHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.groups_outlined),
          activeIcon: const Icon(Icons.groups),
          label: context.l10n.navCommunity,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person_rounded),
          label: context.l10n.navProfile,
        ),
      ],
    );
  }
}
