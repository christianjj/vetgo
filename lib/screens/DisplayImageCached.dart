import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DisplayImageCached extends StatelessWidget {
  final String imageUrl; // Accepting the image URL as a parameter

  DisplayImageCached({required this.imageUrl}); // Constructor to receive the URL
  @override
  Widget build(BuildContext context) {
    print(imageUrl);
    return Scaffold(
      appBar: AppBar(title: Text('Preview')),
      body: Center(
        child: Image.network(imageUrl, fit: BoxFit.cover)
      ),
    );
  }
}