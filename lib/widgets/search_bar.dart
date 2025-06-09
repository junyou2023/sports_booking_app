// ========== lib/widgets/search_bar.dart ==========
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class RoundedSearchBar extends StatelessWidget {
  final VoidCallback onFilterTap;
  const RoundedSearchBar({super.key, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,                // demo：只做 UI 点击无输入
      decoration: InputDecoration(
        hintText: 'Find places and things to do',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.tune),
          onPressed: onFilterTap,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

