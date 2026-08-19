import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/cart_provider.dart';

class CustomerFoodDetailsSheet extends StatefulWidget {
  final MenuItem item;
  final String restaurantId;

  const CustomerFoodDetailsSheet({
    super.key,
    required this.item,
    required this.restaurantId,
  });

  @override
  State<CustomerFoodDetailsSheet> createState() =>
      _CustomerFoodDetailsSheetState();
}

class _CustomerFoodDetailsSheetState extends State<CustomerFoodDetailsSheet> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _getEffectivePrice(MenuItem item) {
    return item.discountPrice > 0 ? item.discountPrice : item.price;
  }

  void _nextImage() {
    if (_currentImageIndex < widget.item.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no multiple images exist, use the single cover image
    final List<String> images = widget.item.imageUrls.isNotEmpty
        ? widget.item.imageUrls
        : [widget.item.imageUrl];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // ================= Multi-Image Slider with Arrows =================
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: images.length,
                    itemBuilder: (ctx, i) {
                      return Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),

                // Close Button
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Left Arrow
                if (images.length > 1 && _currentImageIndex > 0)
                  Positioned(
                    left: 10,
                    top: 130,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _previousImage,
                      ),
                    ),
                  ),

                // Right Arrow
                if (images.length > 1 && _currentImageIndex < images.length - 1)
                  Positioned(
                    right: 10,
                    top: 130,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _nextImage,
                      ),
                    ),
                  ),

                // Dot Indicators
                if (images.length > 1)
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.deepOrange
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ================= Details Section =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${_getEffectivePrice(widget.item).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Preparation: ${widget.item.prepTime} mins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // ================= Add to Cart Button =================
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      bool isInCart = cart.items.containsKey(widget.item.id);
                      int qty = isInCart
                          ? cart.items[widget.item.id]!.quantity
                          : 0;
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: isInCart
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.deepOrange,
                                      size: 40,
                                    ),
                                    onPressed: () =>
                                        cart.removeSingleItem(widget.item.id),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.deepOrange,
                                      size: 40,
                                    ),
                                    onPressed: () => cart.addItem(widget.item),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: widget.item.isAvailable
                                    ? () => cart.addItem(widget.item)
                                    : null,
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
