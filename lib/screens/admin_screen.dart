import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/database_service.dart';
import '../models/menu_item.dart';
import 'admin_settings.dart';

class AdminScreen extends StatefulWidget {
  final String restaurantId;

  const AdminScreen({super.key, required this.restaurantId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();

  String _searchQuery = '';
  bool _isAvailable = true;

  String _selectedCategory = 'Fast Food';
  final List<String> _categories = [
    'Fast Food',
    'Pizza',
    'Beverages',
    'Dessert',
    'Main Course',
  ];

  // ================= NEW: Multi-Image State =================
  List<XFile> _selectedImages = [];
  List<Uint8List> _imageBytesList = [];
  int _coverImageIndex = 0; // Which image to show as Cover
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final DatabaseService _dbService = DatabaseService();

  // ===================== ADD ITEM LOGIC =====================
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      List<Uint8List> bytesList = [];
      for (var img in images) {
        bytesList.add(await img.readAsBytes());
      }
      setState(() {
        _selectedImages.addAll(images);
        _imageBytesList.addAll(bytesList);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytesList.removeAt(index);
      if (_coverImageIndex >= _selectedImages.length) {
        _coverImageIndex = 0;
      }
    });
  }

  Future<void> _uploadAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showMessage('Please select at least one image!', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> uploadedUrls = [];
      // Upload all selected images
      for (var file in _selectedImages) {
        String? url = await _cloudinaryService.uploadImage(file);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isEmpty) throw Exception('Failed to upload images');

      String coverUrl = uploadedUrls[_coverImageIndex];

      bool success = await _dbService.addMenuItem(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        discountPrice: _discountController.text.trim().isEmpty
            ? 0.0
            : double.parse(_discountController.text.trim()),
        prepTime: _prepTimeController.text.trim().isEmpty
            ? 15
            : int.parse(_prepTimeController.text.trim()),
        isAvailable: _isAvailable,
        category: _selectedCategory,
        imageUrl: coverUrl, // Single cover image
        imageUrls: uploadedUrls, // Multi images array
        restaurantId: widget.restaurantId,
      );

      if (success) {
        _showMessage('Menu Item Added Successfully!', Colors.green);
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        _discountController.clear();
        _prepTimeController.clear();
        setState(() {
          _selectedImages.clear();
          _imageBytesList.clear();
          _coverImageIndex = 0;
          _selectedCategory = 'Fast Food';
          _isAvailable = true;
          _selectedIndex = 0;
        });
      } else {
        throw Exception('Failed to save to database');
      }
    } catch (e) {
      _showMessage(e.toString(), Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ===================== EDIT/DELETE LOGIC =====================
  void _deleteItem(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this food item?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(MenuItem item) {
    TextEditingController nameCtrl = TextEditingController(text: item.name);
    TextEditingController descCtrl = TextEditingController(
      text: item.description,
    );
    TextEditingController priceCtrl = TextEditingController(
      text: item.price.toString(),
    );
    TextEditingController discountCtrl = TextEditingController(
      text: item.discountPrice > 0 ? item.discountPrice.toString() : '',
    );
    TextEditingController prepTimeCtrl = TextEditingController(
      text: item.prepTime.toString(),
    );

    String category = item.category;
    bool isAvail = item.isAvailable;
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Edit Menu Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Discount Price',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: prepTimeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prep Time (Min)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _categories.contains(category)
                              ? category
                              : _categories.first,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => category = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text(
                      'Available Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isAvail ? 'Currently Available' : 'Currently Unavailable',
                    ),
                    value: isAvail,
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => isAvail = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        setDialogState(() => isUpdating = true);
                        bool success = await _dbService
                            .updateMenuItem(item.id, {
                              'name': nameCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'price':
                                  double.tryParse(priceCtrl.text.trim()) ??
                                  item.price,
                              'discountPrice':
                                  double.tryParse(discountCtrl.text.trim()) ??
                                  0.0,
                              'prepTime':
                                  int.tryParse(prepTimeCtrl.text.trim()) ?? 15,
                              'isAvailable': isAvail,
                              'category': category,
                            });
                        setDialogState(() => isUpdating = false);

                        if (success) {
                          Navigator.pop(ctx);
                          _showMessage(
                            'Item updated successfully',
                            Colors.green,
                          );
                        } else {
                          _showMessage('Failed to update item', Colors.red);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  // ===================== UI BUILDERS =====================
  Widget _buildMenuList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search food items...',
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: _dbService.getMenuItems(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              if (snapshot.hasError)
                return const Center(child: Text('Error loading menu items'));

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'No menu items found.\nAdd some from the "Add Item" tab!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              List<MenuItem> filteredItems = items
                  .where(
                    (item) => item.name.toLowerCase().contains(_searchQuery),
                  )
                  .toList();
              filteredItems.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

              Map<String, List<MenuItem>> categorizedItems = {};
              for (var item in filteredItems) {
                if (!categorizedItems.containsKey(item.category))
                  categorizedItems[item.category] = [];
                categorizedItems[item.category]!.add(item);
              }

              if (filteredItems.isEmpty)
                return const Center(
                  child: Text(
                    'No matching items found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: categorizedItems.keys.length,
                itemBuilder: (context, index) {
                  String category = categorizedItems.keys.elementAt(index);
                  List<MenuItem> categoryItems = categorizedItems[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      ...categoryItems.map((item) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            ),
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
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (item.discountPrice > 0) ...[
                                            Text(
                                              '\$${item.discountPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '\$${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ] else ...[
                                            Text(
                                              '\$${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.timer_outlined,
                                                  size: 12,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${item.prepTime} min',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isAvailable
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.isAvailable
                                                  ? 'Available'
                                                  : 'Unavailable',
                                              style: TextStyle(
                                                fontSize: 10,
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
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _showEditDialog(item),
                                    ),
                                    const SizedBox(height: 16),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteItem(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Food Item',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ================= NEW: Multi Image Upload Box =================
                GestureDetector(
                  onTap: _isUploading ? null : _pickImages,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: _imageBytesList.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            itemCount: _imageBytesList.length,
                            itemBuilder: (context, index) {
                              bool isCover = index == _coverImageIndex;
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _coverImageIndex = index,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isCover
                                              ? Colors.deepPurple
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _imageBytesList[index],
                                          width: 100,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
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
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: Colors.deepPurple.withOpacity(0.7),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to select multiple images',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_imageBytesList.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Tap on an image to set as Cover Photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.fastfood_outlined),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter food name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          labelText: 'Price (\$)',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter price' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          labelText: 'Discount Price (\$)',
                          hintText: 'Optional',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.local_offer_outlined),
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
                        controller: _prepTimeController,
                        keyboardType: TextInputType.number,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          labelText: 'Prep Time (Mins)',
                          hintText: 'e.g. 15',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.timer_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: _isUploading
                            ? null
                            : (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Item Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      _isAvailable
                          ? 'Customers can order this'
                          : 'Hidden/Out of stock',
                    ),
                    value: _isAvailable,
                    activeColor: Colors.deepPurple,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isUploading
                        ? const Text(
                            'Uploading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Upload to Menu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildMenuList(),
      _buildAddItemForm(),
      AdminSettingsTab(restaurantId: widget.restaurantId),
    ];

    final List<String> titles = [
      'Menu Management',
      'Add New Food',
      'Admin Settings',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              activeIcon: Icon(Icons.restaurant_menu, size: 28),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle, size: 28),
              label: 'Add Item',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings, size: 28),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
