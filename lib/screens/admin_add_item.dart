import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import '../services/database_service.dart';

class AdminAddItem extends StatefulWidget {
  final String restaurantId;
  final VoidCallback onSaved;

  const AdminAddItem({
    super.key,
    required this.restaurantId,
    required this.onSaved,
  });

  @override
  State<AdminAddItem> createState() => _AdminAddItemState();
}

class _AdminAddItemState extends State<AdminAddItem> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();

  bool _isAvailable = true;
  String? _selectedCategory;

  List<XFile> _selectedImages = [];
  List<Uint8List> _imageBytesList = [];
  int _coverImageIndex = 0;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final DatabaseService _dbService = DatabaseService();

  // Cover Image variables
  bool _isUploadingCover = false;
  double _coverAlignmentY = 0.0;

  // Default cover image (Matches with menu_screen.dart)
  final String _defaultCoverUrl =
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ================= NEW: COVER IMAGE LOGIC =================
  Future<void> _uploadCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploadingCover = true);
      _showMessage('Uploading Cover Image...', Colors.orange);
      try {
        String? url = await _cloudinaryService.uploadImage(image);
        if (url != null) {
          await FirebaseFirestore.instance
              .collection('restaurant_settings')
              .doc(widget.restaurantId)
              .set({
                'cover_image': url,
                'cover_alignment': _coverAlignmentY, // save current alignment
              }, SetOptions(merge: true));
          _showMessage('Cover Image Updated!', Colors.green);
        }
      } catch (e) {
        _showMessage('Failed to upload cover: $e', Colors.red);
      } finally {
        setState(() => _isUploadingCover = false);
      }
    }
  }

  // Save slider value to Firebase ONLY when dragging ends (smooth sliding)
  Future<void> _updateCoverAlignmentInDB(double value) async {
    await FirebaseFirestore.instance
        .collection('restaurant_settings')
        .doc(widget.restaurantId)
        .set({'cover_alignment': value}, SetOptions(merge: true));
    _showMessage('Cover Position Saved', Colors.green);
  }

  // Delete cover image and reset to default
  Future<void> _deleteCoverImage() async {
    await FirebaseFirestore.instance
        .collection('restaurant_settings')
        .doc(widget.restaurantId)
        .update({
          'cover_image': FieldValue.delete(),
          'cover_alignment': FieldValue.delete(),
        });
    setState(() {
      _coverAlignmentY = 0.0;
    });
    _showMessage('Custom Cover Deleted. Restored to Default.', Colors.green);
  }

  // ================= CATEGORY MANAGEMENT LOGIC =================
  final List<String> _defaultCategories = [
    'Fast Food',
    'Pizza',
    'Beverages',
    'Dessert',
    'Main Course',
  ];

  void _manageCategoriesDialog(List<String> customCats) {
    TextEditingController newCatCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Manage Categories',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newCatCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add new category...',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () async {
                          String cat = newCatCtrl.text.trim();
                          if (cat.isNotEmpty &&
                              !_defaultCategories.contains(cat) &&
                              !customCats.contains(cat)) {
                            await FirebaseFirestore.instance
                                .collection('restaurant_settings')
                                .doc(widget.restaurantId)
                                .set({
                                  'custom_categories': FieldValue.arrayUnion([
                                    cat,
                                  ]),
                                }, SetOptions(merge: true));
                            newCatCtrl.clear();
                            setDialogState(() => customCats.add(cat));
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Custom Categories:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (customCats.isEmpty)
                    const Text(
                      'No custom categories added.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ...customCats
                      .map(
                        (cat) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(cat),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: ctx,
                                builder: (innerCtx) => AlertDialog(
                                  title: const Text('Delete Category?'),
                                  content: Text(
                                    'Are you sure you want to delete "$cat"?\n\nWARNING: All food items inside this category will also be deleted!',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(innerCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(innerCtx);
                                        await FirebaseFirestore.instance
                                            .collection('restaurant_settings')
                                            .doc(widget.restaurantId)
                                            .set({
                                              'custom_categories':
                                                  FieldValue.arrayRemove([cat]),
                                            }, SetOptions(merge: true));

                                        var items = await FirebaseFirestore
                                            .instance
                                            .collection('MenuItems')
                                            .where(
                                              'restaurant_id',
                                              isEqualTo: widget.restaurantId,
                                            )
                                            .where('category', isEqualTo: cat)
                                            .get();

                                        WriteBatch batch = FirebaseFirestore
                                            .instance
                                            .batch();
                                        for (var doc in items.docs) {
                                          batch.delete(doc.reference);
                                        }
                                        await batch.commit();

                                        setDialogState(
                                          () => customCats.remove(cat),
                                        );
                                        if (_selectedCategory == cat)
                                          setState(
                                            () => _selectedCategory = null,
                                          );
                                        _showMessage(
                                          'Category and its items deleted',
                                          Colors.orange,
                                        );
                                      },
                                      child: const Text(
                                        'Delete All',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

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
    if (_selectedCategory == null) {
      _showMessage('Please select a category!', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> uploadedUrls = [];
      for (var file in _selectedImages) {
        String? url = await _cloudinaryService.uploadImage(file);
        if (url != null) uploadedUrls.add(url);
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
        category: _selectedCategory!,
        imageUrl: coverUrl,
        imageUrls: uploadedUrls,
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
          _isAvailable = true;
        });
        widget.onSaved();
      } else {
        throw Exception('Failed to save to database');
      }
    } catch (e) {
      _showMessage(e.toString(), Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // ================= SECTION 1: COVER IMAGE SETUP =================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.panorama, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Restaurant Cover Photo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          // Custom Cover delete button
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('restaurant_settings')
                                .doc(widget.restaurantId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                var data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                if (data.containsKey('cover_image') &&
                                    data['cover_image'] != null) {
                                  return IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Remove Custom Cover',
                                    onPressed: _deleteCoverImage,
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('restaurant_settings')
                            .doc(widget.restaurantId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String coverUrl = _defaultCoverUrl;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            if (data.containsKey('cover_image') &&
                                data['cover_image'] != null) {
                              coverUrl = data['cover_image'];
                            }
                            // Initialize alignment state if it comes from DB
                            if (data.containsKey('cover_alignment') &&
                                _coverAlignmentY == 0.0) {
                              _coverAlignmentY = data['cover_alignment']
                                  .toDouble();
                            }
                          }

                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    image: DecorationImage(
                                      image: NetworkImage(coverUrl),
                                      fit: BoxFit.cover,
                                      alignment: Alignment(
                                        0,
                                        _coverAlignmentY,
                                      ), // Live Preview
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text(
                                    'Position:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _coverAlignmentY,
                                      min: -1.0,
                                      max: 1.0,
                                      activeColor: Colors.deepPurple,
                                      onChanged: (val) {
                                        // Update UI smoothly without hitting database
                                        setState(() => _coverAlignmentY = val);
                                      },
                                      onChangeEnd: (val) {
                                        // Save to database only when dragging ends
                                        _updateCoverAlignmentInDB(val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isUploadingCover
                                      ? null
                                      : _uploadCoverImage,
                                  icon: _isUploadingCover
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file),
                                  label: const Text('Upload New Cover'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ================= SECTION 2: ADD ITEM FORM =================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Add New Food Item',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Image Picker
                        GestureDetector(
                          onTap: _isUploading ? null : _pickImages,
                          child: Container(
                            height: 120,
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
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isCover
                                                      ? Colors.deepPurple
                                                      : Colors.transparent,
                                                  width: 3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.memory(
                                                  _imageBytesList[index],
                                                  width: 90,
                                                  height: 110,
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
                                              onPressed: () =>
                                                  _removeImage(index),
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
                                        color: Colors.deepPurple.withOpacity(
                                          0.7,
                                        ),
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
                              'Tap on an image to set as Item Thumbnail',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),

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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                enabled: !_isUploading,
                                decoration: InputDecoration(
                                  labelText: 'Price (৳)',
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                enabled: !_isUploading,
                                decoration: InputDecoration(
                                  labelText: 'Discount Price (৳)',
                                  hintText: 'Optional',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.local_offer_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ================= DYNAMIC CATEGORY MANAGER =================
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('restaurant_settings')
                              .doc(widget.restaurantId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            List<String> customCats = [];
                            if (snapshot.hasData && snapshot.data!.exists) {
                              var data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              if (data.containsKey('custom_categories')) {
                                customCats = List<String>.from(
                                  data['custom_categories'],
                                );
                              }
                            }
                            List<String> allCats = [
                              ..._defaultCategories,
                              ...customCats,
                            ];

                            _selectedCategory ??= allCats.first;
                            if (!allCats.contains(_selectedCategory))
                              _selectedCategory = allCats.first;

                            return Row(
                              children: [
                                Expanded(
                                  flex: 2,
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
                                      prefixIcon: const Icon(
                                        Icons.timer_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
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
                                      prefixIcon: const Icon(
                                        Icons.category_outlined,
                                      ),
                                    ),
                                    items: allCats
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _isUploading
                                        ? null
                                        : (val) => setState(
                                            () => _selectedCategory = val,
                                          ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.deepPurple,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      _manageCategoriesDialog(customCats),
                                  tooltip: 'Manage Categories',
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              'Item Available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            value: _isAvailable,
                            activeColor: Colors.deepPurple,
                            onChanged: (val) =>
                                setState(() => _isAvailable = val),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _uploadAndSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isUploading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Add Food to Menu',
                                    style: TextStyle(
                                      fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }
}
