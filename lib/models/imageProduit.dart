class ImageProduit {
  final String id;
  final String url;

  ImageProduit({required this.id, required this.url});

  factory ImageProduit.fromMap(Map<String, dynamic> map, String id) {
    return ImageProduit(id: id, url: map['url']);
  }

  Map<String, dynamic> toMap() {
    return {'url': url};
  }
}
