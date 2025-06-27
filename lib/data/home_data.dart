import 'package:flutter/material.dart';

class HomeData {
  static final List<Map<String, dynamic>> categories = [
    {'name': 'Mode', 'icon': Icons.checkroom_outlined},
    {'name': 'Électronique', 'icon': Icons.devices_other_outlined},
    {'name': 'Maison', 'icon': Icons.home_outlined},
    {'name': 'Beauté & Santé', 'icon': Icons.spa_outlined},
    {'name': 'Alimentation', 'icon': Icons.restaurant_outlined},
    {'name': 'Informatique', 'icon': Icons.computer_outlined},
    {'name': 'Sports', 'icon': Icons.sports_soccer_outlined},
    {'name': 'Jeux vidéo', 'icon': Icons.videogame_asset_outlined},
    {'name': 'Auto & Moto', 'icon': Icons.directions_car_outlined},
    {'name': 'Livres & Papeterie', 'icon': Icons.menu_book_outlined},
    {'name': 'Téléphonie & Internet', 'icon': Icons.smartphone_outlined},
  ];

  static final List<Map<String, dynamic>> products = [
    {'id': '1', 'name': 'Smartphone Premium', 'price': 299000},
    {'id': '2', 'name': 'T-shirt Coton Bio', 'price': 19000},
    {'id': '3', 'name': 'Lampe LED Design', 'price': 49000},
    {'id': '4', 'name': 'Ballon de Football', 'price': 15000},
  ];
  static final List<Map<String, String>> banners = [
    {
      'text': 'Offre spéciale\n-20% sur l\'électronique !',
      'subtitle': 'Smartphones, laptops et plus encore',
      'color': '0xFF6366F1',
    },
    {
      'text': 'Nouveautés mode\nautomne 2025 !',
      'subtitle': 'Découvrez les dernières tendances',
      'color': '0xFFEC4899',
    },
    {
      'text': 'Décorez votre maison\navec style !',
      'subtitle': 'Mobilier et décoration moderne',
      'color': '0xFF10B981',
    },
  ];
}
