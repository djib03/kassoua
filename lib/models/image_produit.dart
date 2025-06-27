class ImageProduit {
  final String id;
  final String url;
  final String? produitId;
  ImageProduit({required this.id, required this.url, this.produitId});

  factory ImageProduit.fromMap(Map<String, dynamic> map, String id) {
    return ImageProduit(id: id, url: map['url'], produitId: map['produitId']);
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'produitId': produitId};
  }
}
