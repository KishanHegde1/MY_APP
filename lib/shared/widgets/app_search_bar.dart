import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    this.controller,
    this.onChanged,
    this.hintText = 'Search',
    super.key,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search),
    ),
  );
}
