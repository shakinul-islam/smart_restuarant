class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountPrice;
  final String imageUrl; // Cover Image
  final List<String> imageUrls; // NEW: Multiple Images
  final String category;
  final bool isAvailable;
  final int prepTime;
  final String restaurantId;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice = 0.0,
    required this.imageUrl,
    this.imageUrls = const [], // NEW
    required this.category,
    this.isAvailable = true,
    this.prepTime = 15,
    required this.restaurantId,
  });

  factory MenuItem.fromMap(Map<String, dynamic> data, String documentId) {
    return MenuItem(
      id: documentId,
      name: data['name'] ?? 'Unknown Item',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      // ফায়ারবেস থেকে মাল্টিপল ইমেজের লিস্ট নেওয়া, না থাকলে শুধু কভার ইমেজটাই লিস্টে রাখা
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : [data['imageUrl'] ?? ''],
      category: data['category'] ?? 'Uncategorized',
      isAvailable: data['isAvailable'] ?? true,
      prepTime: data['prepTime'] ?? 15,
      restaurantId: data['restaurant_id'] ?? 'Unknown',
    );
  }
}
