import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityToggle;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
