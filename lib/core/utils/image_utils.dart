import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider? safeImageProvider(String path) {
  if (path.startsWith('http')) return NetworkImage(path);
  final file = File(path);
  if (file.existsSync()) return FileImage(file);
  return null;
}
