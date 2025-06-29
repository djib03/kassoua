//  ---------------------------------------------------------------------------
// / mark_as_sold_dialog.dart
// / ---------------------------------------------------------------------------
// / Un composant réutilisable permettant d'afficher une boîte de dialogue de
// / confirmation "Marquer comme vendu" pour une annonce (Produit).
// /
// / Utilisation :
// / ```dart
// / await showMarkAsSoldConfirmationDialog(
// /   context: context,
// /   product: produit,
// /   onMarkAsSold: (id) => _firestoreService.markProductAsSold(id),
// / );
// / ```
// / ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:iconsax/iconsax.dart';

// Importez vos dépendances locales (modèle Produit, tailles, couleurs, etc.)
// ignore: implementation_imports

import 'package:kassoua/models/product.dart';
import 'package:kassoua/constants/colors.dart';
import 'package:kassoua/constants/size.dart';

/// Affiche une boîte de dialogue de confirmation pour marquer un [Produit]
/// comme vendu. La logique d'écriture dans la base est injectée via le callback
/// [onMarkAsSold] afin de garder ce composant totalement découplé.
Future<void> showMarkAsSoldConfirmationDialog({
  required BuildContext context,
  required Produit product,
  required Future<void> Function(String productId) onMarkAsSold,
}) async {
  return SmartDialog.show(
    alignment: Alignment.bottomCenter,
    animationType: SmartAnimationType.scale,
    animationTime: const Duration(milliseconds: 300),
    clickMaskDismiss: true,
    backDismiss: true,
    builder: (dialogContext) {
      // Note : on n’utilise pas [context] directement dans le builder car celui‑ci
      // possède son propre BuildContext (dialogContext).
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(DMSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : AppColors.white,
          borderRadius: BorderRadius.circular(DMSizes.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: DMSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(DMSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône et titre
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(DMSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            DMSizes.borderRadiusSm,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: DMSizes.md),
                      Expanded(
                        child: Text(
                          'Marquer comme vendu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: DMSizes.md),

                  // Message
                  Text(
                    'Êtes‑vous sûr de vouloir marquer l\'annonce "${product.nom}" comme vendue ?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: DMSizes.lg),

                  // Boutons d'action
                  Row(
                    children: [
                      // ------ Bouton Annuler ------
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => SmartDialog.dismiss(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: DMSizes.md),
                            side: BorderSide(color: AppColors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DMSizes.borderRadiusMd,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: DMSizes.md),

                      // ------ Bouton Confirmer ------
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            SmartDialog.showLoading(
                              msg: 'Marquage en cours...',
                              maskColor: Colors.black.withOpacity(0.3),
                            );

                            try {
                              await onMarkAsSold(product.id);

                              // Ferme d'abord le loading puis la boîte de dialogue.
                              SmartDialog.dismiss(); // loading
                              SmartDialog.dismiss(); // dialog

                              // Attends un court instant pour laisser l'animation
                              // de fermeture se terminer.
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Iconsax.tick_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: DMSizes.sm),
                                        Expanded(
                                          child: Text(
                                            'Annonce "${product.nom}" marquée comme vendue.',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        DMSizes.borderRadiusMd,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              SmartDialog.dismiss(); // loading (et éventuellement la dialog si ouverte)
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erreur lors de la mise à jour : $e',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: DMSizes.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DMSizes.borderRadiusMd,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Marquer comme vendu',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) => Future.value());
}
