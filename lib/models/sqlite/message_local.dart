class MessageLocal {
  final String id;
  final String contenu;
  final String dateEnvoi;
  final String expediteurId;
  final String destinataireId;
  final String discussionId;
  final bool estLu;
  final bool isSynced;
  final String lastUpdated;

  MessageLocal({
    required this.id,
    required this.contenu,
    required this.dateEnvoi,
    required this.expediteurId,
    required this.destinataireId,
    required this.discussionId,
    required this.estLu,
    required this.isSynced,
    required this.lastUpdated,
  });

  factory MessageLocal.fromMap(Map<String, dynamic> map) {
    return MessageLocal(
      id: map['id'],
      contenu: map['contenu'],
      dateEnvoi: map['dateEnvoi'],
      expediteurId: map['expediteurId'],
      destinataireId: map['destinataireId'],
      discussionId: map['discussionId'],
      estLu: map['estLu'] == 1,
      isSynced: map['isSynced'] == 1,
      lastUpdated: map['lastUpdated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contenu': contenu,
      'dateEnvoi': dateEnvoi,
      'expediteurId': expediteurId,
      'destinataireId': destinataireId,
      'discussionId': discussionId,
      'estLu': estLu ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'lastUpdated': lastUpdated,
    };
  }
}
