import 'package:flutter/material.dart';
import 'package:kassoua/models/image_produit.dart';
import 'package:kassoua/constants/colors.dart';

class OptimizedImageWidget extends StatelessWidget {
  final ImageProduit? image;
  final String productId;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const OptimizedImageWidget({
    Key? key,
    required this.image,
    required this.productId,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Gérer les valeurs infinies
    double? finalWidth = width;
    double? finalHeight = height;

    // Si width ou height est infini, on les met à null pour laisser le parent gérer
    if (width != null && (width!.isInfinite || width!.isNaN)) {
      finalWidth = null;
    }
    if (height != null && (height!.isInfinite || height!.isNaN)) {
      finalHeight = null;
    }

    Widget imageWidget;

    if (image != null && image!.url.isNotEmpty) {
      imageWidget = Image.network(
        image!.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: finalWidth,
            height: finalHeight,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: finalWidth,
            height: finalHeight,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      );
    } else {
      // Image par défaut
      imageWidget = Container(
        width: finalWidth,
        height: finalHeight,
        color: Colors.grey[200],
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
      );
    }

    // Appliquer le borderRadius si spécifié
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
