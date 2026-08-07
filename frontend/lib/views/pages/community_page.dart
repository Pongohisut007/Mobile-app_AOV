import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/widgets/community/category_card.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();

    final categoryBloc = context.read<CategoryBloc>();
    final state = categoryBloc.state;

    if (state is! CategoryLoaded &&
        state is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];

                return CategoryCard(
                  category: category,
                );
              },
            );
          } else if (state is CategoryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is CategoryError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          return const Center(
            child: Text('No data available.'),
          );
        },
      ),
    );
  }
}