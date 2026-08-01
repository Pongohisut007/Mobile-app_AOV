import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/user/user_bloc.dart';
import 'package:flutter_application_1/bloc/user/user_even.dart';
import 'package:flutter_application_1/bloc/user/user_state.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void initState() {
    super.initState();
    context.read<Userbloc>().add(FetchUserEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "Our Users",
            style: Theme.of(context).textTheme.headlineMedium,
          ), // Text
          Expanded(
            child: BlocBuilder<Userbloc, UserState>(
              builder: (context, state) {
                // handle initial state
                if (state is UserInit) {
                  return const Center(child: Text("Initial Loading..."));
                }
                // handle loading state
                if (state is Userloading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // handle loaded state
                if (state is Userloaded) {
                  return ListView.builder(
                    itemCount: state.user.length,
                    itemBuilder: (context, index) {
                      final user = state.user[index];
                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : "?",
                            ),
                          ), // CircleAvatar
                          title: Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // Text
                          subtitle: Text(user.email),
                        ), // ListTile
                      ); // Card
                    },
                  );
                }
                // handle error state
                if (state is UserError) {
                  return Center(child: Text(state.message));
                }
                // return empty widget
                return const SizedBox.shrink();
              },
            ), // BlocBuilder
          ), // Expanded
        ],
      ), // Column
    ); // Container
  }
}