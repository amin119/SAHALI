import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ReportFormProvider extends ChangeNotifier {
  static const _tunisCenter = LatLng(36.8065, 10.1815);
  static const maxPhotos = 5;

  int? categoryIndex;
  int? categoryId;
  String? categoryLabel;
  IconData? categoryIcon;
  Color? categoryColor;

  List<File> photos = [];

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

  void addPhoto(File file) {
    if (photos.length < maxPhotos) {
      photos = [...photos, file];
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    photos = [...photos]..removeAt(index);
    notifyListeners();
  }

  // Legacy single-photo setter used by old code paths
  void setPhoto(File? file) {
    if (file == null) {
      photos = [];
    } else if (photos.isEmpty) {
      photos = [file];
    } else {
      photos = [file, ...photos.skip(1)];
    }
    notifyListeners();
  }

  File? get photo => photos.isEmpty ? null : photos.first;

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
    photos = [];
    location = _tunisCenter;
    description = '';
    notifyListeners();
  }

  bool get isComplete =>
      categoryIndex != null && description.trim().length >= 20;
}
