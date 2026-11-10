import 'package:flutter/foundation.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final Map<String, int> cart = {};
  Map<String, dynamic> profile = {};
  double distanceKm = 1.8; // later: compute from shop <-> customer lat/lng

  int qty(String id) => cart[id] ?? 0;
  int get count => cart.values.fold(0, (a, b) => a + b);
  List<Product> get items => kProducts.where((p) => cart.containsKey(p.id)).toList();
  int get itemTotal => items.fold(0, (a, p) => a + p.price * qty(p.id));
  int get fee => cart.isEmpty ? 0 : 15 + (distanceKm * 5).round();
  int get total => itemTotal + fee;

  void change(String id, int d) {
    final n = qty(id) + d;
    if (n <= 0) {
      cart.remove(id);
    } else {
      cart[id] = n;
    }
    notifyListeners();
  }

  void clear() {
    cart.clear();
    notifyListeners();
  }

  void setProfile(Map<String, dynamic> p) {
    profile = p;
    notifyListeners();
  }

  void reset() {
    cart.clear();
    profile = {};
    notifyListeners();
  }
}
