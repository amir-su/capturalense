import 'dart:typed_data';
import 'package:captura_lens/model/add_post.dart';
import 'package:captura_lens/photographer/photo_home.dart';
import 'package:captura_lens/services/photographer_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter/foundation.dart';

class PhotoAddPost extends StatefulWidget {
  const PhotoAddPost({super.key});

  @override
  State<PhotoAddPost> createState() => _PhotoAddPostState();
}

class _PhotoAddPostState extends State<PhotoAddPost> {
  XFile? selectedImage; // XFile for both web and mobile
  Uint8List? editedImage; // Uint8List for edited images
  String imageURL = '';
  // final firebaseStorage = FirebaseStorage.instance;
  String uniqueImageName = DateTime.now().microsecondsSinceEpoch.toString();
  final firebaseStorage =
      FirebaseStorage.instanceFor(bucket: "gs://capturalens-84b72");

  Future<void> _pickImage(bool fromCamera) async {
    final ImagePicker picker = ImagePicker();
    final XFile? returnImage = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (returnImage != null) {
      Uint8List imageBytes =
          await returnImage.readAsBytes(); // Works for both Web & Mobile

      setState(() {
        selectedImage = returnImage;
        editedImage = imageBytes;
      });

      // Navigate to Image Editor
      final edited = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: imageBytes),
        ),
      );

      if (edited != null) {
        setState(() {
          editedImage = edited; // Update with edited image
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image not selected")),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (editedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pick an image first!")),
      );
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to upload images")),
      );
      return;
    }

    try {
      SettableMetadata metadata = SettableMetadata(contentType: "image/jpeg");

      // Generating unique number
      String referenceNumber = DateTime.now().millisecondsSinceEpoch.toString();

      // Correct bucket URL without `.appspot.com`
      Reference ref =
          FirebaseStorage.instanceFor(bucket: "gs://capturalens-84b72")
              .ref()
              .child('images/$referenceNumber');

      await ref.putData(editedImage!, metadata);

      // Get URL
      imageURL = await ref.getDownloadURL();

      String id = randomAlphaNumeric(10);
      print("Image uploaded successfully: $imageURL");

      // Display the reference number in the debug console
      print("Reference Number: $referenceNumber");

      // Save to database
      await PhotographerController().photoPost(
        AddPost(
          imageUrl: imageURL,
          postId: id,
          uid: FirebaseAuth.instance.currentUser!.uid,
          referenceNumber: referenceNumber,
        ),
        id,
      );

      Fluttertoast.showToast(
        msg: "Photo Successfully Uploaded",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Reset state
      setState(() {
        editedImage = null;
        selectedImage = null;
        imageURL = "";
      });
    } catch (error) {
      print("Upload Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Post"),
        leading: IconButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PhotoHome()));
          },
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
              onPressed: () => _pickImage(false), child: const Text("Gallery")),
          TextButton(
              onPressed: () => _pickImage(true), child: const Text("Camera")),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: editedImage != null
                ? Image.memory(editedImage!)
                : Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Text("Select Photo"),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadImage,
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        child: const Text("Done"),
      ),
    );
  }
}
