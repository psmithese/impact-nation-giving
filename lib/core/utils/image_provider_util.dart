import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getImageProvider(String url) {
  if (url.startsWith('data:image')) {
    final base64String = url.split(',').last;
    return MemoryImage(base64Decode(base64String));
  }
  return NetworkImage(url);
}

Widget buildImageWidget(String url, {BoxFit? fit}) {
  if (url.startsWith('data:image')) {
    final base64String = url.split(',').last;
    return Image.memory(base64Decode(base64String), fit: fit);
  }
  return Image.network(url, fit: fit);
}
