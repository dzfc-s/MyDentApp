import 'dart:convert';

import 'package:flutter/material.dart';

// Returns the dialog's Future so a caller that needs to navigate away right
// after showing it can `await` this first — popping the underlying screen
// immediately (fire-and-forget) tears the dialog down before it's ever seen
// (see PaymentScreen for the bug this caused: the error alert flashed and
// vanished together with the screen behind it, in one frame).
Future<void> alertBox(BuildContext context, String title, String content) {
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

void alertBoxMoveBack(BuildContext context, String title, String content) {
  showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Ok')),
            ],
          ));
}

Image imageFromBase64String(String base64Image) {
  return Image.memory(
    base64Decode(base64Image),
    height: 400,
    width: 400,
    fit: BoxFit.cover,
  );
}

MemoryImage ImageFromBase64StringWithoutDimnesions(String base64Image) {
  return MemoryImage(
    base64Decode(base64Image),
  );
}

Image placeholderImage() {
  return Image.asset(
    "assets/images/product_placeholder.jpg",
    height: 400,
    width: 400,
    fit: BoxFit.cover,
  );
}


 const String mField = "Ovo polje je obavezno";

const String numericField = "Ovo polje mora biti broj";