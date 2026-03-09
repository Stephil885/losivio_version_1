import 'package:flutter/material.dart';
import '../models/Streamer_model.dart';

enum LiveLayoutType {
  solo,
  duo,
  trio,
  quad,
}

LiveLayoutType resolveLayout(List<StreamerModel> streamers) {
  switch (streamers.length) {
    case 1:
      return LiveLayoutType.solo;
    case 2:
      return LiveLayoutType.duo;
    case 3:
      return LiveLayoutType.trio;
    default:
      return LiveLayoutType.quad;
  }
}
