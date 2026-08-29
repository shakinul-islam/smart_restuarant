import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../models/menu_item.dart';
import 'admin_settings.dart';
import 'admin_add_item.dart';
import 'admin_dashboard_tab.dart';
import 'login_screen.dart';
import 'super_admin_payment.dart'; // NEW: Developer Payment File Import

class AdminScreen extends StatefulWidget {
  final String restaurantId;

  const AdminScreen({super.key, required this.restaurantId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // ================= NEW: VALUENOTIFIERS FOR SUPER SMOOTH UI =================
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String> _selectedCategoryFilter = ValueNotifier('All');

  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Prevents jump shaking

  late Stream<List<MenuItem>> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = _dbService.getMenuItems(widget.restaurantId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _selectedCategoryFilter.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===================== DELETE LOGIC =====================
  void _deleteItem(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Food Item',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this food item permanently?',
          style: TextStyle(fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _dbService.deleteMenuItem(docId);
              if (success) {
                _showMessage('Item deleted successfully', Colors.green);
              } else {
                _showMessage('Failed to delete item', Colors.red);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SHOW EDIT DIALOG =====================
  void _showEditDialog(MenuItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditItemDialog(
        item: item,
        restaurantId: widget.restaurantId,
        dbService: _dbService,
        onSuccess: () =>
            _showMessage('Item updated successfully!', Colors.green),
        onError: (e) => _showMessage(e, Colors.red),
      ),
    );
  }

  // ===================== CATEGORY MORE BOTTOM SHEET =====================
  void _showAllCategoriesSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'All Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: _selectedCategoryFilter,
                builder: (context, selectedCat, _) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((cat) {
                      bool isSelected = selectedCat == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.deepPurple,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          _selectedCategoryFilter.value = cat;
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ===================== SMALL & SMART GRID CARD =====================
  Widget _buildSmallGridCard(MenuItem item) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEditDialog(item),
        onLongPress: () => _deleteItem(item.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE SECTION
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stk) => Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // INFO SECTION
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (item.discountPrice > 0) ...[
                          Text(
                            '৳${item.discountPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '৳${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '৳${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.prepTime > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item.prepTime}m',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isAvailable
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.isAvailable ? 'Available' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 9,
                              color: item.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MENU LIST BUILDER =====================
  Widget _buildMenuList() {
    return Column(
      children: [
        // ================= SEARCH BAR =================
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          color: Colors.grey[50],
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery.value = value.toLowerCase();
            },
            decoration: InputDecoration(
              hintText: 'Search food items...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
          ),
        ),

        // ================= LIVE DATA STREAM =================
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              }
              if (snapshot.hasError)
                return const Center(child: Text('Error loading menu items'));

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No menu items found.\nClick "Add Food" to create your menu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              // Pre-calculate categories
              List<String> uniqueCategories = items
                  .map((e) => e.category)
                  .toSet()
                  .toList();
              uniqueCategories.sort(
                (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
              );
              List<String> allCategories = ['All', ...uniqueCategories];

              return ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _selectedCategoryFilter,
                    builder: (context, selectedCat, _) {
                      // Search Filter Processing
                      List<MenuItem> searchedItems = items
                          .where(
                            (item) => item.name.toLowerCase().contains(query),
                          )
                          .toList();
                      searchedItems.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );

                      return Column(
                        children: [
                          // ================= CATEGORY ROW =================
                          Container(
                            width: double.infinity,
                            color: Colors.grey[50],
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: allCategories.take(6).map((
                                        category,
                                      ) {
                                        bool isSelected =
                                            selectedCat == category;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(category),
                                            selected: isSelected,
                                            selectedColor: Colors.deepPurple,
                                            backgroundColor: Colors.white,
                                            labelStyle: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? Colors.deepPurple
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            onSelected: (selected) {
                                              _selectedCategoryFilter.value =
                                                  category;
                                              if (_scrollController
                                                  .hasClients) {
                                                _scrollController.jumpTo(0);
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                if (allCategories.length > 6)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: InkWell(
                                      onTap: () => _showAllCategoriesSheet(
                                        allCategories,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          size: 20,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ================= FULLY RESPONSIVE GRID (NO SHAKE) =================
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                List<Widget> slivers = [];
                                List<String> categoriesToShow =
                                    selectedCat == 'All'
                                    ? uniqueCategories
                                    : [selectedCat];

                                for (String cat in categoriesToShow) {
                                  List<MenuItem> catItems = searchedItems
                                      .where((e) => e.category == cat)
                                      .toList();
                                  if (catItems.isEmpty) continue;

                                  // Category Header
                                  slivers.add(
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          20,
                                          16,
                                          12,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              cat,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.deepPurple
                                                    .withOpacity(0.2),
                                                thickness: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  // Responsive Grid
                                  slivers.add(
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 260,
                                              mainAxisExtent: 220,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                            ),
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          return _buildSmallGridCard(
                                            catItems[index],
                                          );
                                        }, childCount: catItems.length),
                                      ),
                                    ),
                                  );
                                }

                                if (slivers.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No items match your filter.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                return CustomScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  slivers: [
                                    ...slivers,
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 100),
                                    ), // Bottom padding for FAB
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_settings')
          .doc(widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );

        bool isActive = true;
        String notice = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('is_active')) isActive = data['is_active'];
          if (data.containsKey('notice_message'))
            notice = data['notice_message'];
        }

        if (!isActive) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'Subscription Suspended',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your access to the Admin Panel has been temporarily suspended. Please clear your dues or contact the system administrator to reactivate your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ================= NEW: PAY DEVELOPER BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SuperAdminPaymentScreen(
                                restaurantId: widget.restaurantId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text(
                          'Pay Developer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= EXISTING LOGOUT BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final AuthService authService = AuthService();
                          await authService.logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ================= INDEXED STACK KEEPS STATE SMOOTH =================
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              _selectedIndex == 0
                  ? 'Menu Management'
                  : _selectedIndex == 1
                  ? 'Restaurant Dashboard'
                  : 'System Settings',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            bottom: notice.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      width: double.infinity,
                      color: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: Colors.brown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              notice,
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildMenuList(),
              AdminDashboardTab(restaurantId: widget.restaurantId),
              AdminSettingsTab(restaurantId: widget.restaurantId),
            ],
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text(
                              'Add New Food',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          body: AdminAddItem(
                            restaurantId: widget.restaurantId,
                            onSaved: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Food',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )
              : null,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey[400],
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_menu_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_menu, size: 28),
                  ),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard, size: 28),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.settings_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.settings, size: 28),
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================================
// PROFESSIONAL EDIT DIALOG
// =========================================================================

class _EditItemDialog extends StatefulWidget {
  final MenuItem item;
  final String restaurantId;
  final DatabaseService dbService;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _EditItemDialog({
    required this.item,
    required this.restaurantId,
    required this.dbService,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discountCtrl;
  late TextEditingController prepTimeCtrl;
  late String category;
  late bool isAvail;
  bool isUpdating = false;

  List<String> _existingUrls = [];
  List<XFile> _newSelectedImages = [];
  List<Uint8List> _newImageBytes = [];
  String _coverUrl = '';
  int? _newCoverIndex;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.item.name);
    descCtrl = TextEditingController(text: widget.item.description);
    priceCtrl = TextEditingController(text: widget.item.price.toString());
    discountCtrl = TextEditingController(
      text: widget.item.discountPrice > 0
          ? widget.item.discountPrice.toString()
          : '',
    );
    prepTimeCtrl = TextEditingController(
      text: widget.item.prepTime > 0 ? widget.item.prepTime.toString() : '',
    );

    category = widget.item.category;
    isAvail = widget.item.isAvailable;

    _existingUrls = List<String>.from(
      widget.item.imageUrls.isNotEmpty
          ? widget.item.imageUrls
          : [widget.item.imageUrl],
    );
    _coverUrl = widget.item.imageUrl;
  }

  Future<void> _pickNewImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      List<Uint8List> bytesList = [];
      for (var img in images) {
        bytesList.add(await img.readAsBytes());
      }
      setState(() {
        _newSelectedImages.addAll(images);
        _newImageBytes.addAll(bytesList);
      });
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingUrls.remove(url);
      if (_coverUrl == url) {
        if (_existingUrls.isNotEmpty) {
          _coverUrl = _existingUrls.first;
        } else if (_newSelectedImages.isNotEmpty) {
          _coverUrl = '';
          _newCoverIndex = 0;
        } else {
          _coverUrl = '';
        }
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
      _newImageBytes.removeAt(index);
      if (_newCoverIndex == index) {
        _newCoverIndex = null;
        if (_existingUrls.isNotEmpty) {
          _coverUrl = _existingUrls.first;
        } else if (_newSelectedImages.isNotEmpty) {
          _newCoverIndex = 0;
        }
      } else if (_newCoverIndex != null && _newCoverIndex! > index) {
        _newCoverIndex = _newCoverIndex! - 1;
      }
    });
  }

  void _setCoverExisting(String url) {
    setState(() {
      _coverUrl = url;
      _newCoverIndex = null;
    });
  }

  void _setCoverNew(int index) {
    setState(() {
      _coverUrl = '';
      _newCoverIndex = index;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingUrls.isEmpty && _newSelectedImages.isEmpty) {
      widget.onError('Please add at least one image for the food item.');
      return;
    }

    setState(() => isUpdating = true);

    try {
      List<String> finalUploadedUrls = List.from(_existingUrls);
      String finalCoverUrl = _coverUrl;

      for (int i = 0; i < _newSelectedImages.length; i++) {
        String? uploadedUrl = await _cloudinaryService.uploadImage(
          _newSelectedImages[i],
        );
        if (uploadedUrl != null) {
          finalUploadedUrls.add(uploadedUrl);
          if (_newCoverIndex == i) finalCoverUrl = uploadedUrl;
        }
      }

      if (finalCoverUrl.isEmpty && finalUploadedUrls.isNotEmpty) {
        finalCoverUrl = finalUploadedUrls.first;
      }

      int prepT = int.tryParse(prepTimeCtrl.text.trim()) ?? 0;

      bool success = await widget.dbService.updateMenuItem(widget.item.id, {
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()) ?? widget.item.price,
        'discountPrice': double.tryParse(discountCtrl.text.trim()) ?? 0.0,
        'prepTime': prepT,
        'isAvailable': isAvail,
        'category': category,
        'imageUrl': finalCoverUrl,
        'imageUrls': finalUploadedUrls,
      });

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        widget.onError('Database update failed');
      }
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.deepPurple.withOpacity(0.04),
      prefixIcon: Icon(icon, color: Colors.deepPurple.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.deepPurple.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Menu Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: isUpdating ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Manager
                      const Text(
                        'Manage Images',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap an image to set as thumbnail (Star).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            ..._existingUrls.map((url) {
                              bool isCover = _coverUrl == url;
                              return GestureDetector(
                                onTap: () => _setCoverExisting(url),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isCover
                                                ? Colors.deepPurple
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            url,
                                            width: 85,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isCover)
                                        const Positioned(
                                          top: 5,
                                          left: 5,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 24,
                                          ),
                                        ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeExistingImage(url),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            ...List.generate(_newSelectedImages.length, (
                              index,
                            ) {
                              bool isCover = _newCoverIndex == index;
                              return GestureDetector(
                                onTap: () => _setCoverNew(index),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isCover
                                                ? Colors.deepPurple
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            _newImageBytes[index],
                                            width: 85,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isCover)
                                        const Positioned(
                                          top: 5,
                                          left: 5,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 24,
                                          ),
                                        ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeNewImage(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: _pickNewImages,
                              child: Container(
                                width: 85,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: nameCtrl,
                        decoration: _buildInputDecoration(
                          'Food Name',
                          Icons.fastfood_outlined,
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: _buildInputDecoration(
                          'Description',
                          Icons.description_outlined,
                        ).copyWith(alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Price (৳)',
                                Icons.attach_money,
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Discount Price (৳)',
                                Icons.local_offer_outlined,
                                hint: 'Optional',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: prepTimeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Prep Time (Mins)',
                                Icons.timer_outlined,
                                hint: 'Leave empty to hide',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('restaurant_settings')
                                  .doc(widget.restaurantId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                List<String> defaultCats = [
                                  'Fast Food',
                                  'Pizza',
                                  'Beverages',
                                  'Dessert',
                                  'Main Course',
                                ];
                                List<String> customCats = [];
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>;
                                  if (data.containsKey('custom_categories')) {
                                    customCats = List<String>.from(
                                      data['custom_categories'],
                                    );
                                  }
                                }
                                List<String> allCats = [
                                  ...defaultCats,
                                  ...customCats,
                                ];
                                if (!allCats.contains(category))
                                  allCats.add(category);

                                return DropdownButtonFormField<String>(
                                  value: category,
                                  decoration: _buildInputDecoration(
                                    'Category',
                                    Icons.category_outlined,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down_circle,
                                    color: Colors.deepPurple,
                                  ),
                                  items: allCats
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => category = val!),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.1),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            title: const Text(
                              'Available Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              isAvail
                                  ? 'Currently Available in Menu'
                                  : 'Hidden from Menu',
                            ),
                            value: isAvail,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.redAccent,
                            onChanged: (val) => setState(() => isAvail = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../models/menu_item.dart';
import 'admin_settings.dart';
import 'admin_add_item.dart';
import 'admin_dashboard_tab.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final String restaurantId;

  const AdminScreen({super.key, required this.restaurantId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // ================= NEW: VALUENOTIFIERS FOR SUPER SMOOTH UI =================
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String> _selectedCategoryFilter = ValueNotifier('All');

  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Prevents jump shaking

  late Stream<List<MenuItem>> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = _dbService.getMenuItems(widget.restaurantId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _selectedCategoryFilter.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===================== DELETE LOGIC =====================
  void _deleteItem(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Food Item',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this food item permanently?',
          style: TextStyle(fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _dbService.deleteMenuItem(docId);
              if (success) {
                _showMessage('Item deleted successfully', Colors.green);
              } else {
                _showMessage('Failed to delete item', Colors.red);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SHOW EDIT DIALOG =====================
  void _showEditDialog(MenuItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditItemDialog(
        item: item,
        restaurantId: widget.restaurantId,
        dbService: _dbService,
        onSuccess: () =>
            _showMessage('Item updated successfully!', Colors.green),
        onError: (e) => _showMessage(e, Colors.red),
      ),
    );
  }

  // ===================== CATEGORY MORE BOTTOM SHEET =====================
  void _showAllCategoriesSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'All Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: _selectedCategoryFilter,
                builder: (context, selectedCat, _) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((cat) {
                      bool isSelected = selectedCat == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.deepPurple,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          _selectedCategoryFilter.value = cat;
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ===================== SMALL & SMART GRID CARD =====================
  Widget _buildSmallGridCard(MenuItem item) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEditDialog(item),
        onLongPress: () => _deleteItem(item.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE SECTION
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stk) => Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // INFO SECTION
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (item.discountPrice > 0) ...[
                          Text(
                            '৳${item.discountPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '৳${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '৳${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.prepTime > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item.prepTime}m',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isAvailable
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.isAvailable ? 'Available' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 9,
                              color: item.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MENU LIST BUILDER =====================
  Widget _buildMenuList() {
    return Column(
      children: [
        // ================= SEARCH BAR =================
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          color: Colors.grey[50],
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery.value = value.toLowerCase();
            },
            decoration: InputDecoration(
              hintText: 'Search food items...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
          ),
        ),

        // ================= LIVE DATA STREAM =================
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              }
              if (snapshot.hasError)
                return const Center(child: Text('Error loading menu items'));

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No menu items found.\nClick "Add Food" to create your menu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              // Pre-calculate categories
              List<String> uniqueCategories = items
                  .map((e) => e.category)
                  .toSet()
                  .toList();
              uniqueCategories.sort(
                (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
              );
              List<String> allCategories = ['All', ...uniqueCategories];

              return ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _selectedCategoryFilter,
                    builder: (context, selectedCat, _) {
                      // Search Filter Processing
                      List<MenuItem> searchedItems = items
                          .where(
                            (item) => item.name.toLowerCase().contains(query),
                          )
                          .toList();
                      searchedItems.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );

                      return Column(
                        children: [
                          // ================= CATEGORY ROW =================
                          Container(
                            width: double.infinity,
                            color: Colors.grey[50],
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: allCategories.take(6).map((
                                        category,
                                      ) {
                                        bool isSelected =
                                            selectedCat == category;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(category),
                                            selected: isSelected,
                                            selectedColor: Colors.deepPurple,
                                            backgroundColor: Colors.white,
                                            labelStyle: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? Colors.deepPurple
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            onSelected: (selected) {
                                              _selectedCategoryFilter.value =
                                                  category;
                                              if (_scrollController
                                                  .hasClients) {
                                                _scrollController.jumpTo(0);
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                if (allCategories.length > 6)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: InkWell(
                                      onTap: () => _showAllCategoriesSheet(
                                        allCategories,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          size: 20,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ================= FULLY RESPONSIVE GRID =================
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                List<Widget> slivers = [];
                                List<String> categoriesToShow =
                                    selectedCat == 'All'
                                    ? uniqueCategories
                                    : [selectedCat];

                                for (String cat in categoriesToShow) {
                                  List<MenuItem> catItems = searchedItems
                                      .where((e) => e.category == cat)
                                      .toList();
                                  if (catItems.isEmpty) continue;

                                  // Category Header
                                  slivers.add(
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          20,
                                          16,
                                          12,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              cat,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.deepPurple
                                                    .withOpacity(0.2),
                                                thickness: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  // Responsive Grid
                                  slivers.add(
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 280,
                                              mainAxisExtent: 220,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                            ),
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          return _buildSmallGridCard(
                                            catItems[index],
                                          );
                                        }, childCount: catItems.length),
                                      ),
                                    ),
                                  );
                                }

                                if (slivers.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No items match your filter.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                return CustomScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  slivers: [
                                    ...slivers,
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 100),
                                    ), // Bottom padding for FAB
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ================= RESTORED: STREAMBUILDER FOR KILL SWITCH =================
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_settings')
          .doc(widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        bool isActive = true;
        String notice = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('is_active')) isActive = data['is_active'];
          if (data.containsKey('notice_message'))
            notice = data['notice_message'];
        }

        // ================= BLOCK SCREEN UI =================
        if (!isActive) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'Subscription Suspended',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your access to the Admin Panel has been temporarily suspended. Please clear your dues or contact the system administrator to reactivate your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final AuthService authService = AuthService();
                        await authService.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ================= NORMAL ADMIN UI =================
        final List<Widget> pages = [
          _buildMenuList(),
          AdminDashboardTab(restaurantId: widget.restaurantId),
          AdminSettingsTab(restaurantId: widget.restaurantId),
        ];

        final List<String> titles = [
          'Menu Management',
          'Restaurant Dashboard',
          'System Settings',
        ];

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              titles[_selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            bottom: notice.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      width: double.infinity,
                      color: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: Colors.brown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              notice,
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          body: IndexedStack(index: _selectedIndex, children: pages),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text(
                              'Add New Food',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          body: AdminAddItem(
                            restaurantId: widget.restaurantId,
                            onSaved: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Food',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )
              : null,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey[400],
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_menu_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_menu, size: 28),
                  ),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard, size: 28),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.settings_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.settings, size: 28),
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================================
// PROFESSIONAL EDIT DIALOG
// =========================================================================

class _EditItemDialog extends StatefulWidget {
  final MenuItem item;
  final String restaurantId;
  final DatabaseService dbService;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _EditItemDialog({
    required this.item,
    required this.restaurantId,
    required this.dbService,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discountCtrl;
  late TextEditingController prepTimeCtrl;
  late String category;
  late bool isAvail;
  bool isUpdating = false;

  List<String> _existingUrls = [];
  List<XFile> _newSelectedImages = [];
  List<Uint8List> _newImageBytes = [];
  String _coverUrl = '';
  int? _newCoverIndex;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.item.name);
    descCtrl = TextEditingController(text: widget.item.description);
    priceCtrl = TextEditingController(text: widget.item.price.toString());
    discountCtrl = TextEditingController(
      text: widget.item.discountPrice > 0
          ? widget.item.discountPrice.toString()
          : '',
    );
    prepTimeCtrl = TextEditingController(
      text: widget.item.prepTime > 0 ? widget.item.prepTime.toString() : '',
    );

    category = widget.item.category;
    isAvail = widget.item.isAvailable;

    _existingUrls = List<String>.from(
      widget.item.imageUrls.isNotEmpty
          ? widget.item.imageUrls
          : [widget.item.imageUrl],
    );
    _coverUrl = widget.item.imageUrl;
  }

  Future<void> _pickNewImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      List<Uint8List> bytesList = [];
      for (var img in images) {
        bytesList.add(await img.readAsBytes());
      }
      setState(() {
        _newSelectedImages.addAll(images);
        _newImageBytes.addAll(bytesList);
      });
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingUrls.remove(url);
      if (_coverUrl == url) {
        if (_existingUrls.isNotEmpty) {
          _coverUrl = _existingUrls.first;
        } else if (_newSelectedImages.isNotEmpty) {
          _coverUrl = '';
          _newCoverIndex = 0;
        } else {
          _coverUrl = '';
        }
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
      _newImageBytes.removeAt(index);
      if (_newCoverIndex == index) {
        _newCoverIndex = null;
        if (_existingUrls.isNotEmpty) {
          _coverUrl = _existingUrls.first;
        } else if (_newSelectedImages.isNotEmpty) {
          _newCoverIndex = 0;
        }
      } else if (_newCoverIndex != null && _newCoverIndex! > index) {
        _newCoverIndex = _newCoverIndex! - 1;
      }
    });
  }

  void _setCoverExisting(String url) {
    setState(() {
      _coverUrl = url;
      _newCoverIndex = null;
    });
  }

  void _setCoverNew(int index) {
    setState(() {
      _coverUrl = '';
      _newCoverIndex = index;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingUrls.isEmpty && _newSelectedImages.isEmpty) {
      widget.onError('Please add at least one image for the food item.');
      return;
    }

    setState(() => isUpdating = true);

    try {
      List<String> finalUploadedUrls = List.from(_existingUrls);
      String finalCoverUrl = _coverUrl;

      for (int i = 0; i < _newSelectedImages.length; i++) {
        String? uploadedUrl = await _cloudinaryService.uploadImage(
          _newSelectedImages[i],
        );
        if (uploadedUrl != null) {
          finalUploadedUrls.add(uploadedUrl);
          if (_newCoverIndex == i) finalCoverUrl = uploadedUrl;
        }
      }

      if (finalCoverUrl.isEmpty && finalUploadedUrls.isNotEmpty) {
        finalCoverUrl = finalUploadedUrls.first;
      }

      int prepT = int.tryParse(prepTimeCtrl.text.trim()) ?? 0;

      bool success = await widget.dbService.updateMenuItem(widget.item.id, {
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()) ?? widget.item.price,
        'discountPrice': double.tryParse(discountCtrl.text.trim()) ?? 0.0,
        'prepTime': prepT,
        'isAvailable': isAvail,
        'category': category,
        'imageUrl': finalCoverUrl,
        'imageUrls': finalUploadedUrls,
      });

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        widget.onError('Database update failed');
      }
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.deepPurple.withOpacity(0.04),
      prefixIcon: Icon(icon, color: Colors.deepPurple.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.deepPurple.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Menu Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: isUpdating ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Manager
                      const Text(
                        'Manage Images',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap an image to set as thumbnail (Star).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            ..._existingUrls.map((url) {
                              bool isCover = _coverUrl == url;
                              return GestureDetector(
                                onTap: () => _setCoverExisting(url),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isCover
                                                ? Colors.deepPurple
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            url,
                                            width: 85,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isCover)
                                        const Positioned(
                                          top: 5,
                                          left: 5,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 24,
                                          ),
                                        ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeExistingImage(url),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            ...List.generate(_newSelectedImages.length, (
                              index,
                            ) {
                              bool isCover = _newCoverIndex == index;
                              return GestureDetector(
                                onTap: () => _setCoverNew(index),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isCover
                                                ? Colors.deepPurple
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            _newImageBytes[index],
                                            width: 85,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isCover)
                                        const Positioned(
                                          top: 5,
                                          left: 5,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 24,
                                          ),
                                        ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeNewImage(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: _pickNewImages,
                              child: Container(
                                width: 85,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: nameCtrl,
                        decoration: _buildInputDecoration(
                          'Food Name',
                          Icons.fastfood_outlined,
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: _buildInputDecoration(
                          'Description',
                          Icons.description_outlined,
                        ).copyWith(alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Price (৳)',
                                Icons.attach_money,
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Discount Price (৳)',
                                Icons.local_offer_outlined,
                                hint: 'Optional',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: prepTimeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                'Prep Time (Mins)',
                                Icons.timer_outlined,
                                hint: 'Leave empty to hide',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('restaurant_settings')
                                  .doc(widget.restaurantId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                List<String> defaultCats = [
                                  'Fast Food',
                                  'Pizza',
                                  'Beverages',
                                  'Dessert',
                                  'Main Course',
                                ];
                                List<String> customCats = [];
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>;
                                  if (data.containsKey('custom_categories')) {
                                    customCats = List<String>.from(
                                      data['custom_categories'],
                                    );
                                  }
                                }
                                List<String> allCats = [
                                  ...defaultCats,
                                  ...customCats,
                                ];
                                if (!allCats.contains(category))
                                  allCats.add(category);

                                return DropdownButtonFormField<String>(
                                  value: category,
                                  decoration: _buildInputDecoration(
                                    'Category',
                                    Icons.category_outlined,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down_circle,
                                    color: Colors.deepPurple,
                                  ),
                                  items: allCats
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => category = val!),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.1),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            title: const Text(
                              'Available Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              isAvail
                                  ? 'Currently Available in Menu'
                                  : 'Hidden from Menu',
                            ),
                            value: isAvail,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.redAccent,
                            onChanged: (val) => setState(() => isAvail = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
