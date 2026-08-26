import 'dart:convert';

import 'package:flutter/material.dart';

// Returns the showDialog future so callers can await it before navigating away —
// otherwise a pop right after calling this tears the dialog down unread.
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


 const String mField = "Ovo polje je obavezno";

const String numericField = "Ovo polje mora biti broj";