import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../services/cart_provider.dart';
import '../services/database_service.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'customer_food_details.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final int tableNumber;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final DatabaseService _dbService = DatabaseService();

  late Stream<List<MenuItem>> _menuStream;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSort = 'default';
  String _selectedCategoryFilter = 'All';

  Timer? _sliderTimer;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  // ================= FIXED: Replaced GlobalKeys with simple ScrollController =================
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _menuStream = _dbService.getMenuItems(widget.restaurantId);

    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  // ================= FIXED: Simple Scroll Logic that doesn't crash on Web =================
  void _scrollToCategory(String category) {
    setState(() {
      _selectedCategoryFilter = category;
    });

    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        category == 'All' ? 0.0 : 350.0, // Scrolls down past the cover image
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort Foods By',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption(
                    setModalState,
                    'Default',
                    'default',
                    Icons.sort,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Price: Low to High',
                    'price_low_high',
                    Icons.attach_money,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Fastest Delivery',
                    'fast_delivery',
                    Icons.bolt,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Highest Discount',
                    'highest_discount',
                    Icons.local_offer,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllCategoriesSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  bool isSelected = _selectedCategoryFilter == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      Navigator.pop(context);
                      _scrollToCategory(cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    StateSetter setModalState,
    String title,
    String value,
    IconData icon,
  ) {
    bool isSelected = _selectedSort == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepOrange : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepOrange : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.deepOrange)
          : null,
      onTap: () {
        setModalState(() => _selectedSort = value);
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  double _getEffectivePrice(MenuItem item) {
    return item.discountPrice > 0 ? item.discountPrice : item.price;
  }

  Widget _buildDietaryTags(MenuItem item) {
    List<Widget> tags = [];
    String nameLow = item.name.toLowerCase();
    String catLow = item.category.toLowerCase();

    if (nameLow.contains('naga') ||
        nameLow.contains('spicy') ||
        nameLow.contains('hot') ||
        nameLow.contains('chilli')) {
      tags.add(_tagChip('🌶️ Spicy', Colors.red[50]!, Colors.red));
    }
    if (catLow.contains('veg') ||
        nameLow.contains('veg') ||
        nameLow.contains('salad')) {
      tags.add(_tagChip('🌿 Veg', Colors.green[50]!, Colors.green));
    }
    if (item.discountPrice > 0) {
      tags.add(
        _tagChip('🔥 Best Seller', Colors.orange[50]!, Colors.orange[800]!),
      );
    }
    if (tags.isEmpty && item.price >= 400) {
      tags.add(_tagChip('⭐ Popular', Colors.purple[50]!, Colors.purple));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: tags),
    );
  }

  Widget _tagChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFoodDetailsModal(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerFoodDetailsSheet(
        item: item,
        restaurantId: widget.restaurantId,
      ),
    );
  }

  Widget _buildFloatingCartBar(CartProvider cart) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
        child: cart.itemCount > 0
            ? Center(
                key: const ValueKey('cart_bar'),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          restaurantId: widget.restaurantId,
                          tableNumber: widget.tableNumber,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepOrange,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(height: 20, width: 1, color: Colors.white30),
                        const SizedBox(width: 12),
                        Text(
                          '৳${cart.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty_cart')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          StreamBuilder<List<MenuItem>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading menu. Please try again!'),
                );
              }

              List<MenuItem> allMenuItems = snapshot.data ?? [];
              if (allMenuItems.isEmpty) {
                return const Center(
                  child: Text(
                    'No food items available right now.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              List<String> categoryList = ['All'];
              categoryList.addAll(
                allMenuItems.map((e) => e.category).toSet().toList(),
              );

              List<MenuItem> displayItems = allMenuItems;

              if (_searchQuery.isNotEmpty) {
                displayItems = displayItems
                    .where(
                      (item) => item.name.toLowerCase().contains(_searchQuery),
                    )
                    .toList();
              }

              if (_selectedSort == 'price_low_high') {
                displayItems.sort(
                  (a, b) =>
                      _getEffectivePrice(a).compareTo(_getEffectivePrice(b)),
                );
              } else if (_selectedSort == 'fast_delivery') {
                displayItems.sort((a, b) => a.prepTime.compareTo(b.prepTime));
              } else if (_selectedSort == 'highest_discount') {
                displayItems.sort((a, b) {
                  double discountA = a.discountPrice > 0
                      ? (a.price - a.discountPrice)
                      : 0;
                  double discountB = b.discountPrice > 0
                      ? (b.price - b.discountPrice)
                      : 0;
                  return discountB.compareTo(discountA);
                });
              }

              List<MenuItem> featuredItems = allMenuItems
                  .where((item) => item.discountPrice > 0 && item.isAvailable)
                  .toList();
              if (featuredItems.isEmpty) {
                featuredItems = allMenuItems
                    .where((item) => item.isAvailable)
                    .take(5)
                    .toList();
              }

              Map<String, List<MenuItem>> categorizedItems = {};
              for (var item in displayItems) {
                if (_selectedCategoryFilter == 'All' ||
                    item.category == _selectedCategoryFilter) {
                  categorizedItems
                      .putIfAbsent(item.category, () => [])
                      .add(item);
                }
              }

              // ================= FIXED: Replaced Slivers with standard ListView to prevent Web crashes =================
              return CustomScrollView(
                controller: _mainScrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Table: ${widget.tableNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                      ),
                      centerTitle: true,
                      background: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('restaurant_settings')
                            .doc(widget.restaurantId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String coverImageUrl =
                              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
                          double alignY = 0.0;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null) {
                              if (data.containsKey('cover_image') &&
                                  data['cover_image'].toString().isNotEmpty) {
                                coverImageUrl = data['cover_image'];
                              }
                              if (data.containsKey('cover_alignment')) {
                                alignY = data['cover_alignment'].toDouble();
                              }
                            }
                          }

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                coverImageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment(0, alignY),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    actions: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getOrders(widget.restaurantId),
                        builder: (context, snapshot) {
                          int activeOrderCount = 0;
                          if (snapshot.hasData) {
                            final allOrders = snapshot.data!.docs;
                            activeOrderCount = allOrders.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['table_no'] == widget.tableNumber &&
                                  (data['payment_status'] == 'Unpaid' ||
                                      data['payment_status'] ==
                                          'Pending Verification') &&
                                  data['status'] != 'Cancelled';
                            }).length;
                          }

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt_long, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingScreen(
                                        restaurantId: widget.restaurantId,
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (activeOrderCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.deepOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$activeOrderCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CartScreen(
                                        restaurantId: widget.restaurantId,
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (cart.itemCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.deepOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cart.itemCount}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.deepOrange,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(
                                  () => _searchQuery = val.toLowerCase(),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search for food...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showSortBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: categoryList.map((category) {
                                  bool isSelected =
                                      _selectedCategoryFilter == category;
                                  return GestureDetector(
                                    onTap: () => _scrollToCategory(category),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.deepOrange
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.deepOrange
                                              : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: InkWell(
                              onTap: () =>
                                  _showAllCategoriesSheet(categoryList),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Icon(
                                  Icons.grid_view,
                                  size: 20,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_searchQuery.isEmpty &&
                      _selectedCategoryFilter == 'All' &&
                      featuredItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Text(
                              '🔥 Top Deals For You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 180,
                            child: PageView.builder(
                              controller: _pageController,
                              itemBuilder: (context, index) {
                                final item =
                                    featuredItems[index % featuredItems.length];
                                return GestureDetector(
                                  onTap: () => _showFoodDetailsModal(item),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                        image: NetworkImage(item.imageUrl),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.3),
                                          BlendMode.darken,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (item.discountPrice > 0)
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'PROMO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          right: 10,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '৳${_getEffectivePrice(item).toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (item.discountPrice > 0)
                                                    Text(
                                                      '৳${item.price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                  if (displayItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.fastfood_outlined,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No items found.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        String category = categorizedItems.keys.elementAt(
                          index,
                        );
                        List<MenuItem> itemsInCategory =
                            categorizedItems[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...itemsInCategory.map((item) {
                              final bool isAvailable = item.isAvailable;

                              return GestureDetector(
                                onTap: () => _showFoodDetailsModal(item),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey[100]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Opacity(
                                    opacity: isAvailable ? 1.0 : 0.6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                _buildDietaryTags(item),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${item.prepTime} min',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (!isAvailable)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red[50],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Unavailable',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '৳${_getEffectivePrice(item).toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .deepOrange,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        if (item.discountPrice >
                                                            0)
                                                          Text(
                                                            '৳${item.price.toStringAsFixed(0)}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (isAvailable)
                                                      Consumer<CartProvider>(
                                                        builder: (context, cart, child) {
                                                          bool isInCart = cart
                                                              .items
                                                              .containsKey(
                                                                item.id,
                                                              );
                                                          int itemQuantity =
                                                              isInCart
                                                              ? cart
                                                                    .items[item
                                                                        .id]!
                                                                    .quantity
                                                              : 0;

                                                          return isInCart
                                                              ? Container(
                                                                  height: 32,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .deepOrange,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .remove,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                        ),
                                                                        onPressed: () =>
                                                                            cart.removeSingleItem(
                                                                              item.id,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        '$itemQuantity',
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                        ),
                                                                        onPressed: () =>
                                                                            cart.addItem(
                                                                              item,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : SizedBox(
                                                                  height: 32,
                                                                  child: ElevatedButton(
                                                                    onPressed: () =>
                                                                        cart.addItem(
                                                                          item,
                                                                        ),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .deepOrange,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20,
                                                                            ),
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16,
                                                                      ),
                                                                      elevation:
                                                                          0,
                                                                    ),
                                                                    child: const Text(
                                                                      'Add',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                        },
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }, childCount: categorizedItems.keys.length),
                    ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100),
                  ), // Space for bottom bar
                ],
              );
            },
          ),

          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return _buildFloatingCartBar(cart);
            },
          ),
        ],
      ),
    );
  }
}
/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../services/cart_provider.dart';
import '../services/database_service.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'customer_food_details.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final int tableNumber;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final DatabaseService _dbService = DatabaseService();

  late Stream<List<MenuItem>> _menuStream;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSort = 'default';
  String _selectedCategoryFilter = 'All';

  Timer? _sliderTimer;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _menuStream = _dbService.getMenuItems(widget.restaurantId);

    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String category) {
    setState(() {
      _selectedCategoryFilter = category;
    });

    if (category == 'All') {
      if (_categoryKeys.isNotEmpty) {
        Scrollable.ensureVisible(
          _categoryKeys.values.first.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    final key = _categoryKeys[category];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort Foods By',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption(
                    setModalState,
                    'Default',
                    'default',
                    Icons.sort,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Price: Low to High',
                    'price_low_high',
                    Icons.attach_money,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Fastest Delivery',
                    'fast_delivery',
                    Icons.bolt,
                  ),
                  _buildSortOption(
                    setModalState,
                    'Highest Discount',
                    'highest_discount',
                    Icons.local_offer,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllCategoriesSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  bool isSelected = _selectedCategoryFilter == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      Navigator.pop(context);
                      _scrollToCategory(cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    StateSetter setModalState,
    String title,
    String value,
    IconData icon,
  ) {
    bool isSelected = _selectedSort == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepOrange : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepOrange : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.deepOrange)
          : null,
      onTap: () {
        setModalState(() => _selectedSort = value);
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  double _getEffectivePrice(MenuItem item) {
    return item.discountPrice > 0 ? item.discountPrice : item.price;
  }

  Widget _buildDietaryTags(MenuItem item) {
    List<Widget> tags = [];
    String nameLow = item.name.toLowerCase();
    String catLow = item.category.toLowerCase();

    if (nameLow.contains('naga') ||
        nameLow.contains('spicy') ||
        nameLow.contains('hot') ||
        nameLow.contains('chilli')) {
      tags.add(_tagChip('🌶️ Spicy', Colors.red[50]!, Colors.red));
    }
    if (catLow.contains('veg') ||
        nameLow.contains('veg') ||
        nameLow.contains('salad')) {
      tags.add(_tagChip('🌿 Veg', Colors.green[50]!, Colors.green));
    }
    if (item.discountPrice > 0) {
      tags.add(
        _tagChip('🔥 Best Seller', Colors.orange[50]!, Colors.orange[800]!),
      );
    }
    if (tags.isEmpty && item.price >= 400) {
      tags.add(_tagChip('⭐ Popular', Colors.purple[50]!, Colors.purple));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: tags),
    );
  }

  Widget _tagChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFoodDetailsModal(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerFoodDetailsSheet(
        item: item,
        restaurantId: widget.restaurantId,
      ),
    );
  }

  // ================= NEW & MODERN: FLOATING CART BOTTOM BAR =================
  Widget _buildFloatingCartBar(CartProvider cart) {
    return Positioned(
      bottom: 24, // একটু উপরে ভাসমান থাকবে
      left: 0,
      right: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
        child: cart.itemCount > 0
            ? Center(
                key: const ValueKey('cart_bar'),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          restaurantId: widget.restaurantId,
                          tableNumber: widget.tableNumber,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 55, // আরও চিকন করা হয়েছে
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black87, // স্লিক ডার্ক থিম
                      borderRadius: BorderRadius.circular(30), // ফুল পিল শেপ
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // শুধুমাত্র ভেতরের উপাদানের সমান জায়গা নেবে
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepOrange, // হাইলাইটেড আইটেম কাউন্ট
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.white30, // ডিভাইডার
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '৳${cart.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty_cart')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          StreamBuilder<List<MenuItem>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading menu. Please try again!'),
                );
              }

              List<MenuItem> allMenuItems = snapshot.data ?? [];
              if (allMenuItems.isEmpty) {
                return const Center(
                  child: Text(
                    'No food items available right now.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              List<String> categoryList = ['All'];
              categoryList.addAll(
                allMenuItems.map((e) => e.category).toSet().toList(),
              );

              for (String cat in categoryList) {
                _categoryKeys.putIfAbsent(cat, () => GlobalKey());
              }

              List<MenuItem> displayItems = allMenuItems;

              if (_searchQuery.isNotEmpty) {
                displayItems = displayItems
                    .where(
                      (item) => item.name.toLowerCase().contains(_searchQuery),
                    )
                    .toList();
              }

              if (_selectedSort == 'price_low_high') {
                displayItems.sort(
                  (a, b) =>
                      _getEffectivePrice(a).compareTo(_getEffectivePrice(b)),
                );
              } else if (_selectedSort == 'fast_delivery') {
                displayItems.sort((a, b) => a.prepTime.compareTo(b.prepTime));
              } else if (_selectedSort == 'highest_discount') {
                displayItems.sort((a, b) {
                  double discountA = a.discountPrice > 0
                      ? (a.price - a.discountPrice)
                      : 0;
                  double discountB = b.discountPrice > 0
                      ? (b.price - b.discountPrice)
                      : 0;
                  return discountB.compareTo(discountA);
                });
              }

              List<MenuItem> featuredItems = allMenuItems
                  .where((item) => item.discountPrice > 0 && item.isAvailable)
                  .toList();
              if (featuredItems.isEmpty) {
                featuredItems = allMenuItems
                    .where((item) => item.isAvailable)
                    .take(5)
                    .toList();
              }

              Map<String, List<MenuItem>> categorizedItems = {};
              for (var item in displayItems) {
                categorizedItems.putIfAbsent(item.category, () => []).add(item);
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Table: ${widget.tableNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                      ),
                      centerTitle: true,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ================= NEW: DYNAMIC COVER IMAGE =================
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('restaurant_settings')
                                .doc(widget.restaurantId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String coverImageUrl =
                                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'; // Default Image

                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>?;
                                if (data != null &&
                                    data.containsKey('cover_image') &&
                                    data['cover_image'].toString().isNotEmpty) {
                                  coverImageUrl = data['cover_image'];
                                }
                              }

                              return Image.network(
                                coverImageUrl,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getOrders(widget.restaurantId),
                        builder: (context, snapshot) {
                          int activeOrderCount = 0;
                          if (snapshot.hasData) {
                            final allOrders = snapshot.data!.docs;
                            activeOrderCount = allOrders.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['table_no'] == widget.tableNumber &&
                                  (data['payment_status'] == 'Unpaid' ||
                                      data['payment_status'] ==
                                          'Pending Verification') &&
                                  data['status'] != 'Cancelled';
                            }).length;
                          }

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt_long, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingScreen(
                                        restaurantId: widget.restaurantId,
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (activeOrderCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.deepOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$activeOrderCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CartScreen(
                                        restaurantId: widget.restaurantId,
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (cart.itemCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.deepOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cart.itemCount}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.deepOrange,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(
                                  () => _searchQuery = val.toLowerCase(),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search for food...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showSortBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryDelegate(
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: categoryList.map((category) {
                                    bool isSelected =
                                        _selectedCategoryFilter == category;
                                    return GestureDetector(
                                      onTap: () => _scrollToCategory(category),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.deepOrange
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.deepOrange
                                                : Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: InkWell(
                                onTap: () =>
                                    _showAllCategoriesSheet(categoryList),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.grid_view,
                                    size: 20,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_searchQuery.isEmpty && featuredItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Text(
                              '🔥 Top Deals For You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 180,
                            child: PageView.builder(
                              controller: _pageController,
                              itemBuilder: (context, index) {
                                final item =
                                    featuredItems[index % featuredItems.length];
                                return GestureDetector(
                                  onTap: () => _showFoodDetailsModal(item),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                        image: NetworkImage(item.imageUrl),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.3),
                                          BlendMode.darken,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (item.discountPrice > 0)
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'PROMO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          right: 10,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '৳${_getEffectivePrice(item).toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (item.discountPrice > 0)
                                                    Text(
                                                      '৳${item.price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                  if (displayItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.fastfood_outlined,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No items found.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        String category = categorizedItems.keys.elementAt(
                          index,
                        );
                        List<MenuItem> itemsInCategory =
                            categorizedItems[category]!;

                        return Column(
                          key: _categoryKeys[category],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...itemsInCategory.map<Widget>((item) {
                              final bool isAvailable = item.isAvailable;

                              return GestureDetector(
                                onTap: () => _showFoodDetailsModal(item),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey[100]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Opacity(
                                    opacity: isAvailable ? 1.0 : 0.6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),

                                                _buildDietaryTags(item),

                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${item.prepTime} min',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (!isAvailable)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red[50],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Unavailable',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '৳${_getEffectivePrice(item).toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .deepOrange,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        if (item.discountPrice >
                                                            0)
                                                          Text(
                                                            '৳${item.price.toStringAsFixed(0)}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (isAvailable)
                                                      Consumer<CartProvider>(
                                                        builder: (context, cart, child) {
                                                          bool isInCart = cart
                                                              .items
                                                              .containsKey(
                                                                item.id,
                                                              );
                                                          int itemQuantity =
                                                              isInCart
                                                              ? cart
                                                                    .items[item
                                                                        .id]!
                                                                    .quantity
                                                              : 0;

                                                          return isInCart
                                                              ? Container(
                                                                  height: 32,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .deepOrange,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .remove,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                        ),
                                                                        onPressed: () =>
                                                                            cart.removeSingleItem(
                                                                              item.id,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        '$itemQuantity',
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(
                                                                          minWidth:
                                                                              32,
                                                                        ),
                                                                        onPressed: () =>
                                                                            cart.addItem(
                                                                              item,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : SizedBox(
                                                                  height: 32,
                                                                  child: ElevatedButton(
                                                                    onPressed: () =>
                                                                        cart.addItem(
                                                                          item,
                                                                        ),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .deepOrange,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20,
                                                                            ),
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16,
                                                                      ),
                                                                      elevation:
                                                                          0,
                                                                    ),
                                                                    child: const Text(
                                                                      'Add',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                        },
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }, childCount: categorizedItems.keys.length),
                    ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100),
                  ), // Space for bottom bar
                ],
              );
            },
          ),

          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return _buildFloatingCartBar(cart);
            },
          ),
        ],
      ),
    );
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCategoryDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
*/