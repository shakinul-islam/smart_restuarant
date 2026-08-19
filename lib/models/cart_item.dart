import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  // Updated to support discount price
  double get effectivePrice =>
      menuItem.discountPrice > 0 ? menuItem.discountPrice : menuItem.price;

  double get totalPrice => effectivePrice * quantity;
}
