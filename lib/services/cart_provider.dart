import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  // A map to store cart items with the menu item ID as the key
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  // Get total number of unique items in cart
  int get itemCount => _items.length;

  // Calculate the total bill for all items in the cart (Updated for Discount)
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      // ডিসকাউন্ট থাকলে সেটি দিয়ে হিসাব হবে, না থাকলে রেগুলার দাম
      double effectivePrice = cartItem.menuItem.discountPrice > 0
          ? cartItem.menuItem.discountPrice
          : cartItem.menuItem.price;

      total += effectivePrice * cartItem.quantity;
    });
    return total;
  }

  // Add item to cart or increase quantity if it already exists
  void addItem(MenuItem item) {
    if (_items.containsKey(item.id)) {
      _items.update(
        item.id,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(item.id, () => CartItem(menuItem: item));
    }
    notifyListeners(); // Notify UI to rebuild
  }

  // Removes a single quantity of an item from the cart
  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) return;

    if (_items[id]!.quantity > 1) {
      _items.update(
        id,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(id); // If quantity is 1, remove it completely
    }
    notifyListeners();
  }

  // Remove a specific item entirely from the cart
  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  // Clear the whole cart (used after a successful order)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
