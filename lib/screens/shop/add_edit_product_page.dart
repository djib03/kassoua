import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kassoua/services/firestore_service.dart';
import 'package:kassoua/models/product.dart';
import 'package:kassoua/models/categorie.dart';
import 'package:kassoua/services/categorie_service.dart';
import 'package:kassoua/services/cloudinary_service.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter/services.dart';

class AddEditProductPage extends StatefulWidget {
  final String? productId;

  const AddEditProductPage({Key? key, this.productId}) : super(key: key);

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  // Removed _quantityController as it's not needed for marketplace announcement
  // final _quantityController = TextEditingController(text: '1');

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  String? _selectedCategory;
  bool _isLoading = false;

  List<Categorie> _categories = [];
  List<CategoryHierarchy> _categoryHierarchy = [];
  bool _categoriesLoading = true;

  // List of product conditions/states
  final List<String> _productStates = [
    'neuf',
    'occasion',
    'tres_bon_etat',
    'bon_etat',
    'etat_correct',
  ];
  String? _selectedProductState; // New: To hold selected product state

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
    });

    try {
      final categories = await CategoryService().getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des catégories: $e'),
          backgroundColor: DMColors.error,
        ),
      );
    } finally {
      setState(() {
        _categoriesLoading = false;
      });
    }
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    List<DropdownMenuItem<String>> items = [];

    for (CategoryHierarchy hierarchy in _categoryHierarchy) {
      // Ajouter la catégorie parent avec icône
      items.add(
        DropdownMenuItem<String>(
          value: hierarchy.parent.id,
          child: Row(
            children: [
              IconUtils.buildCustomIcon(
                hierarchy.parent.icone,
                size: 20,
                color: DMColors.primary,
              ),
              SizedBox(width: DMSizes.sm),
              Text(
                hierarchy.parent.nom,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: DMColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

      // Ajouter les sous-catégories avec indentation
      for (Categorie subCategory in hierarchy.subCategories) {
        items.add(
          DropdownMenuItem<String>(
            value: subCategory.id,
            child: Padding(
              padding: EdgeInsets.only(left: DMSizes.lg),
              child: Text(
                '• ${subCategory.nom}',
                style: TextStyle(color: DMColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  void _loadProductData() {
    // TODO: Charger les données du produit existant
    // For now, we simulate with dummy data
    if (widget.productId == 'prod_001') {
      _titleController.text = 'Smartphone Android X20';
      _descriptionController.text =
          'Smartphone en excellent état, 128GB, caméra 48MP.';
      _priceController.text = '75000';
      // _quantityController.text = '1'; // Removed
      _selectedCategory = 'Électronique';
      _selectedProductState = 'occasion'; // Set a default or loaded state
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // _quantityController.dispose(); // Removed
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne pouvez pas ajouter plus de 5 images'),
            backgroundColor: DMColors.error,
          ),
        );
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        final int remainingSlots = 5 - _selectedImages.length;
        final List<XFile> imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd.map((image) => File(image.path)));
        });

        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seules les 5 premières images ont été ajoutées'),
              backgroundColor: DMColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des images: $e'),
          backgroundColor: DMColors.error,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prise de photo: $e'),
          backgroundColor: DMColors.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DMSizes.borderRadiusLg),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(DMSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DMColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: DMSizes.lg),
              Text(
                'Ajouter des photos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: DMSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Iconsax.camera,
                      label: 'Caméra',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                  ),
                  SizedBox(width: DMSizes.md),
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Iconsax.gallery,
                      label: 'Galerie',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: DMSizes.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
      child: Container(
        padding: EdgeInsets.all(DMSizes.lg),
        decoration: BoxDecoration(
          border: Border.all(color: DMColors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(DMSizes.md),
              decoration: BoxDecoration(
                color: DMColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: DMColors.primary, size: DMSizes.iconLg),
            ),
            SizedBox(height: DMSizes.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty && widget.productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins une image'),
            backgroundColor: DMColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Retrieve logged-in user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("Utilisateur non connecté");
        }

        // Create the product
        final produit = Produit(
          id: widget.productId ?? UniqueKey().toString(),
          nom: _titleController.text,
          description: _descriptionController.text,
          prix: double.parse(
            _priceController.text.replaceAll(' ', ''),
          ), // Remove spaces before parsing
          etat: _selectedProductState ?? 'occasion', // Use selected state
          // quantite: 1, // Quantity is always 1 for marketplace announcements
          statut: 'disponible', // Default status for new announcements
          dateAjout: DateTime.now(),
          vendeurId: user.uid,
          categorieId: _selectedCategory ?? '',
          adresseId: '', // To be adapted if you manage addresses
        );

        // Save to Firestore
        await FirestoreService().addProduit(produit);

        // Upload images to Cloudinary and create ImageProduit documents
        for (var imageFile in _selectedImages) {
          final url = await uploadImageToCloudinary(
            imageFile,
          ); // Implement this function
          if (url != null) {
            final imageProduit = ImageProduit(
              id: UniqueKey().toString(),
              produitId: produit.id,
              url: url,
            );
            await FirestoreService().addImageProduit(imageProduit);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productId != null
                  ? 'Annonce modifiée avec succès!'
                  : 'Annonce publiée avec succès!',
            ),
            backgroundColor: DMColors.success,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: DMColors.error,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedProductState = _productStates.first; // Set initial product state
    if (widget.productId != null) {
      _loadProductData();
    }
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      _categories = await CategoryService().getCategories();
      _categoryHierarchy = await CategoryService().getCategoryHierarchy();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement catégories: $e')),
      );
    }
    setState(() => _categoriesLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? DMColors.textWhite
                  : Colors.black,
        ),
        title: Text(
          isEditing ? 'Modifier l\'Annonce' : 'Nouvelle Annonce',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DMColors.textWhite
                    : DMColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),

        elevation: 0,
        backgroundColor:
            Brightness.dark == Theme.of(context).brightness
                ? DMColors.black
                : DMColors.light,

        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor:
          Brightness.dark == Theme.of(context).brightness
              ? DMColors.black
              : DMColors.light,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DMSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Images
                    _buildSectionTitle('Photos du produit'),
                    SizedBox(height: DMSizes.md),
                    _buildImageSection(),
                    SizedBox(height: DMSizes.spaceBtwSections),

                    // Section Informations de base
                    _buildSectionTitle('Informations de base'),
                    SizedBox(height: DMSizes.md),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Titre de l\'annonce', // Changed label
                      hint: 'ex: iPhone 15 Pro Max',
                      icon: Iconsax.tag,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        if (value.length < 3) {
                          return 'Le titre doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: DMSizes.md),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description de l\'annonce', // Changed label
                      hint: 'Décrivez votre annonce en détail...',
                      icon: Iconsax.document_text,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        if (value.length < 10) {
                          return 'La description doit contenir au moins 10 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: DMSizes.spaceBtwSections),

                    // Section Détails de l'annonce
                    _buildSectionTitle('Détails de l\'annonce'),
                    SizedBox(height: DMSizes.md),
                    _buildCategoryDropdown(),
                    SizedBox(height: DMSizes.md),
                    _buildProductStateDropdown(), // New: Product State dropdown
                    SizedBox(height: DMSizes.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Prix (FCFA)',
                            hint: '50 000',
                            icon: Iconsax.money,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatter(
                                thousandSeparator: ThousandSeparator.Space,
                                mantissaLength: 0,
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un prix';
                              }
                              // Remove spaces for conversion
                              final price = double.tryParse(
                                value.replaceAll(' ', ''),
                              );
                              if (price == null || price <= 0) {
                                return 'Prix invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DMSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),

            // Fixed save button at the bottom
            Container(
              padding: EdgeInsets.all(DMSizes.lg),
              decoration: BoxDecoration(
                color:
                    Brightness.dark == Theme.of(context).brightness
                        ? DMColors.black
                        : DMColors.light,
                boxShadow: [
                  BoxShadow(
                    color: DMColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DMColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DMSizes.buttonRadius),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 25,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: DMColors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEditing ? Iconsax.edit : Iconsax.add,
                                color: DMColors.white,
                              ),
                              SizedBox(width: DMSizes.sm),
                              Text(
                                isEditing
                                    ? 'Modifier l\'annonce' // Changed text
                                    : 'Publier l\'annonce',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: DMColors.white,
                                  fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            Brightness.dark == Theme.of(context).brightness
                ? const Color.fromARGB(255, 36, 36, 36)
                : DMColors.light,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: DMColors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: DMColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.all(DMSizes.md),
          labelStyle: TextStyle(color: DMColors.textSecondary),
          hintStyle: TextStyle(color: DMColors.textSecondary.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color:
            Brightness.dark == Theme.of(context).brightness
                ? const Color.fromARGB(255, 36, 36, 36)
                : DMColors.light,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: DMColors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Catégorie',
          prefixIcon: const Icon(Iconsax.category, color: DMColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.all(DMSizes.md),
        ),
        items: _buildCategoryItems(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez sélectionner une catégorie';
          }
          return null;
        },
      ),
    );
  }

  // New Widget for Product State Dropdown
  Widget _buildProductStateDropdown() {
    return Container(
      decoration: BoxDecoration(
        color:
            Brightness.dark == Theme.of(context).brightness
                ? const Color.fromARGB(255, 36, 36, 36)
                : DMColors.light,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: DMColors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedProductState,
        decoration: InputDecoration(
          labelText: 'État du produit',
          prefixIcon: const Icon(
            Iconsax.health,
            color: DMColors.primary,
          ), // You can choose a suitable icon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.all(DMSizes.md),
        ),
        items:
            _productStates.map((state) {
              String displayText;
              switch (state) {
                case 'neuf':
                  displayText = 'Neuf';
                  break;
                case 'occasion':
                  displayText = 'Occasion';
                  break;
                case 'tres_bon_etat':
                  displayText = 'Très bon état';
                  break;
                case 'bon_etat':
                  displayText = 'Bon état';
                  break;
                case 'etat_correct':
                  displayText = 'État correct';
                  break;
                default:
                  displayText = state;
              }
              return DropdownMenuItem<String>(
                value: state,
                child: Text(displayText),
              );
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedProductState = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez sélectionner l\'état du produit';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(DMSizes.md),
      decoration: BoxDecoration(
        color:
            Brightness.dark == Theme.of(context).brightness
                ? const Color.fromARGB(255, 36, 36, 36)
                : DMColors.light,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        border: Border.all(
          color: DMColors.grey.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          if (_selectedImages.isEmpty) ...[
            // Empty state - primary add button
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: DMColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
                  border: Border.all(
                    color: DMColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(DMSizes.md),
                        decoration: BoxDecoration(
                          color: DMColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.camera,
                          color: DMColors.primary,
                          size: DMSizes.iconLg,
                        ),
                      ),
                      SizedBox(height: DMSizes.sm),
                      Text(
                        'Ajouter des photos',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: DMColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Appuyez pour sélectionner',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DMColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Grid of selected images
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  // Additional image add button
                  return InkWell(
                    onTap: _showImageSourceDialog,
                    borderRadius: BorderRadius.circular(DMSizes.borderRadiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DMColors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          DMSizes.borderRadiusSm,
                        ),
                        border: Border.all(
                          color: DMColors.grey.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Icon(Iconsax.add, color: DMColors.primary),
                    ),
                  );
                }

                // Display selected images
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          DMSizes.borderRadiusSm,
                        ),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: DMColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: DMColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DMSizes.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DMColors.primary,
                            borderRadius: BorderRadius.circular(
                              DMSizes.borderRadiusSm,
                            ),
                          ),
                          child: Text(
                            'Principale',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: DMColors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          SizedBox(height: DMSizes.sm),
          Text(
            'Ajoutez jusqu\'à 5 photos. La première sera utilisée comme image principale.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: DMColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
