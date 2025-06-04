import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';
import 'package:iconsax/iconsax.dart';

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
  final _quantityController = TextEditingController(text: '1');

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  String? _selectedCategory;
  bool _isLoading = false;

  // Liste des catégories
  final List<String> _categories = [
    'Électronique',
    'Mode & Vêtements',
    'Maison & Jardin',
    'Sports & Loisirs',
    'Véhicules',
    'Immobilier',
    'Emploi & Services',
    'Autres',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    // TODO: Charger les données du produit existant
    // Pour l'instant, on simule avec des données factices
    if (widget.productId == 'prod_001') {
      _titleController.text = 'Smartphone Android X20';
      _descriptionController.text =
          'Smartphone en excellent état, 128GB, caméra 48MP.';
      _priceController.text = '75000';
      _quantityController.text = '1';
      _selectedCategory = 'Électronique';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
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
        // TODO: Implémenter la logique de sauvegarde
        await Future.delayed(const Duration(seconds: 2)); // Simulation

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productId != null
                  ? 'Produit modifié avec succès!'
                  : 'Produit ajouté avec succès!',
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
                    : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),

        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                      label: 'Titre du produit',
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
                      label: 'Description',
                      hint: 'Décrivez votre produit en détail...',
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

                    // Section Prix et Stock
                    _buildSectionTitle('Prix et stock'),
                    SizedBox(height: DMSizes.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Prix (FCFA)',
                            hint: '50000',
                            icon: Iconsax.money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un prix';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Prix invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: DMSizes.md),
                        Expanded(
                          child: _buildTextField(
                            controller: _quantityController,
                            label: 'Quantité',
                            hint: '1',
                            icon: Iconsax.box,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              final qty = int.tryParse(value);
                              if (qty == null || qty <= 0) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DMSizes.md),
                    _buildCategoryDropdown(),
                    SizedBox(height: DMSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),

            // Bouton de sauvegarde fixe en bas
            Container(
              padding: EdgeInsets.all(DMSizes.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
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
                            width: 20,
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
                                    ? 'Modifier le produit'
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
        items:
            _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
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

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(DMSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DMSizes.borderRadiusMd),
        border: Border.all(
          color: DMColors.grey.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          if (_selectedImages.isEmpty) ...[
            // État vide - bouton d'ajout principal
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
            // Grille d'images sélectionnées
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
                  // Bouton d'ajout d'image supplémentaire
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

                // Affichage des images sélectionnées
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
