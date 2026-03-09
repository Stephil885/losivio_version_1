import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget buildInputField(IconData icon, String hint, {bool isPassword = false}) {
  return TextField(
    obscureText: isPassword,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.purple),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      suffixIcon: isPassword
          ? const Icon(Icons.visibility_off, color: Colors.black38)
          : null,
    ),
  );
}

Widget buildPrimaryButton(String label) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7F00FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 5,
      ),
      onPressed: () {},
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    ),
  );
}

Widget buildDivider(String text) {
  return Row(
    children: [
      const Expanded(child: Divider(thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
      const Expanded(child: Divider(thickness: 1)),
    ],
  );
}

Widget buildGoogleButton() {
  return Center(
    child: Container(
      width: 180,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(FontAwesomeIcons.google, color: Colors.redAccent, size: 22),
          SizedBox(width: 10),
          Text(
            "Google",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}
