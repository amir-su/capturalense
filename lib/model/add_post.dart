class AddPost {
  String imageUrl;
  String uid;
  String postId;
  String referenceNumber;
  AddPost(
      {required this.imageUrl,
      required this.postId,
      required this.uid,
      required this.referenceNumber});

  Map<String, dynamic> toJson() => {
        "imageUrl": imageUrl,
        "uid": uid,
        "postId": postId,
        "referenceNumber": referenceNumber
      };

  factory AddPost.fromJson(Map<String, dynamic> json) {
    return AddPost(
        imageUrl: json["imageUrl"],
        postId: json["postId"],
        uid: json["uid"],
        referenceNumber: json["referenceNumber"]);
  }
}
