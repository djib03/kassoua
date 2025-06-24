import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationApp {
  final String id;
  final String contenu;
  final String type;
  final bool estLu;
  final DateTime dateEnvoi;

  NotificationApp({
    required this.id,
    required this.contenu,
    required this.type,
    required this.estLu,
    required this.dateEnvoi,
  });

  factory NotificationApp.fromMap(Map<String, dynamic> map, String id) {
    return NotificationApp(
      id: id,
      contenu: map['contenu'],
      type: map['type'],
      estLu: map['estLu'],
      dateEnvoi: (map['dateEnvoi'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contenu': contenu,
      'type': type,
      'estLu': estLu,
      'dateEnvoi': dateEnvoi,
    };
  }
}
