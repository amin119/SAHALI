import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ReportFormProvider extends ChangeNotifier {
  static const _tunisCenter = LatLng(36.8065, 10.1815);

  int? categoryIndex;
  int? categoryId;
  String? categoryLabel;
  IconData? categoryIcon;
  Color? categoryColor;

  File? photo;

  LatLng location = _tunisCenter;

  String description = '';

  void setCategory(int index, String label, IconData icon, Color color, {int? id}) {
    categoryIndex = index;
    categoryId = id;
    categoryLabel = label;
    categoryIcon = icon;
    categoryColor = color;
    notifyListeners();
  }

  void setPhoto(File? file) {
    photo = file;
    notifyListeners();
  }

  void setLocation(LatLng loc) {
    location = loc;
    notifyListeners();
  }

  void setDescription(String text) {
    description = text;
    notifyListeners();
  }

  void reset() {
    categoryIndex = null;
    categoryId = null;
    categoryLabel = null;
    categoryIcon = null;
    categoryColor = null;
    photo = null;
    location = _tunisCenter;
    description = '';
    notifyListeners();
  }

  bool get isComplete =>
      categoryIndex != null && description.trim().length >= 20;
}
