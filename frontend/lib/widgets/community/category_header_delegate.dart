import 'package:flutter/material.dart';

class CategoryHeaderDelegate 
    extends SliverPersistentHeaderDelegate {

  final Widget child;

  CategoryHeaderDelegate({
    required this.child,
  });


  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }


  @override
  double get maxExtent => 80;


  @override
  double get minExtent => 80;


  @override
  bool shouldRebuild(
    covariant CategoryHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.child != child;
  }
}