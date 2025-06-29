import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ImageViewer extends StatefulWidget {
  final List<String> imageUrl;
  final int initialIndex; // Index de l'image à afficher en premier
  final bool isNetworkImage; // true pour les URLs réseau, false pour les assets

  ImageViewer({
    required this.imageUrl,
    this.initialIndex = 0,
    this.isNetworkImage = true, // Par défaut, on assume des URLs réseau
  });

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController productImageSlider;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    productImageSlider = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    productImageSlider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            'assets/icons/Arrow-left.svg',
            color: Colors.white,
          ),
        ),
        title:
            widget.imageUrl.length > 1
                ? Text(
                  '${currentIndex + 1} / ${widget.imageUrl.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
                : null,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body:
          widget.imageUrl.isEmpty
              ? _buildEmptyState()
              : Stack(
                children: [
                  // Images en plein écran
                  PageView.builder(
                    physics: BouncingScrollPhysics(),
                    controller: productImageSlider,
                    itemCount: widget.imageUrl.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: _buildImage(widget.imageUrl[index]),
                        ),
                      );
                    },
                  ),

                  // Indicateur de page (seulement si plusieurs images)
                  if (widget.imageUrl.length > 1)
                    Positioned(
                      bottom: 50,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SmoothPageIndicator(
                            controller: productImageSlider,
                            count: widget.imageUrl.length,
                            effect: ExpandingDotsEffect(
                              dotColor: Colors.white.withOpacity(0.4),
                              activeDotColor: Colors.white,
                              dotHeight: 8,
                              dotWidth: 8,
                              expansionFactor: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Instructions de zoom (s'affiche brièvement)
                  if (widget.imageUrl.isNotEmpty)
                    Positioned(
                      bottom: 100,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Pincez pour zoomer',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (widget.isNetworkImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorState();
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorState();
        },
      );
    }
  }

  Widget _buildErrorState() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Impossible de charger l\'image',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vérifiez votre connexion internet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune image disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
