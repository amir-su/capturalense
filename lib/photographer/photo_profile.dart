import 'dart:developer';
import 'dart:io';
import 'package:captura_lens/about_us.dart';
import 'package:captura_lens/forgot_password.dart';
import 'package:captura_lens/services/photographer_controller.dart';
import 'package:captura_lens/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../user/complaints_page.dart';
import '../help_page.dart';
import '../support_page.dart';

import 'package:flutter/foundation.dart';

class PhotoProfile extends StatefulWidget {
  bool isPhoto;
  PhotoProfile({super.key, required this.isPhoto});
  @override
  State<PhotoProfile> createState() => _PhotoProfileState();
}

class _PhotoProfileState extends State<PhotoProfile> {
  final nameController = TextEditingController();
  final placeController = TextEditingController();
  final phoneNumber = TextEditingController();

  final List<Widget> _pages = <Widget>[
    const AboutUs(),
    const ForgotPassword(),
    const SupportPage(),
    const HelpPage(),
    const ComplaintsPage(),
  ];
  final List<String> _pagesname = [
    "AboutUs",
    "ForgotPasswor",
    "SupportPag",
    "HelpPag",
    "ComplaintsPag",
    "Logout"
  ];
  dynamic selectedImage; // Supports both File (Mobile) and Uint8List (Web)
  Future<String> getImageUrl(String referenceNumber) async {
    print('Fetching image with reference number: $referenceNumber');
    try {
      final ref = FirebaseStorage.instanceFor(bucket: 'gs://capturalens-84b72')
          .ref()
          .child('images/$referenceNumber');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching image URL: $e');
      return ''; // Return empty string if no image found
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? returnImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (returnImage == null) return;

    if (kIsWeb) {
      // Web: Store as Uint8List
      Uint8List imageBytes = await returnImage.readAsBytes();
      setState(() {
        selectedImage = imageBytes; // Now selectedImage holds Uint8List
        print('Image selected (Web): ${selectedImage.length} bytes');
      });
    } else {
      // Mobile: Store as File
      setState(() {
        selectedImage = File(returnImage.path);
        print('Image selected (Mobile): ${selectedImage.path}');
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    print('Starting upload process...');
    if (selectedImage == null) {
      print('No image selected.');
      return;
    }

    try {
      // Set metadata for the file
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      // Generate a unique file name
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      Reference ref =
          FirebaseStorage.instanceFor(bucket: "gs://capturalens-84b72")
              .ref()
              .child("images/$currentTime");

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web: Upload as Uint8List
        uploadTask = ref.putData(selectedImage as Uint8List, metadata);
        print('Upload task created for web.');
      } else {
        // Mobile: Upload as File
        uploadTask = ref.putFile(selectedImage as File, metadata);
        print('Upload task created for mobile.');
      }

      // Listen for upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
        print('Task state: ${snapshot.state}');
      });

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;
      print('Upload completed. State: ${snapshot.state}');

      // Get the download URL
      String rawUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded to Firebase Storage. URL: $rawUrl");

      // Update Firestore with the new image URL
      await FirebaseFirestore.instance
          .collection("Photographers")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"profileUrl": rawUrl});

      print('Firestore updated with the new image URL.');

      // Refresh UI
      setState(() {});
    } catch (e) {
      print("Upload Error: $e");
      if (e is FirebaseException) {
        print("Firebase Error Code: ${e.code}");
        print("Firebase Error Message: ${e.message}");
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  static Future<void> openMap() async {
    String googleUrl =
        'https://www.google.com/maps/dir/?api=1&destination=10.7759,76.6651';
    try {
      // if (await canLaunch(googleUrl)) {
      // await launch(googleUrl, forceSafariVC: true);
      await launchUrl(Uri.parse(googleUrl));
    } catch (e) {
      log('error map open$e');
    }
  }

  Future bottomsheet(String id) async {
    final photograperedit =
        Provider.of<PhotographerController>(context, listen: false);

    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 500,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: 50,
                    height: 5,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'EDIT YOUR DETAILS ',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        hintText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    controller: placeController,
                    decoration: const InputDecoration(
                        hintText: 'Place', border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    controller: phoneNumber,
                    decoration: const InputDecoration(
                        hintText: 'phone number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  GestureDetector(
                    onTap: () {
                      photograperedit.updateprofile(id, {
                        'name': nameController.text,
                        'place': placeController.text,
                        'phonenumber': phoneNumber.text,
                      }).then(
                        (value) => Navigator.pop(context),
                      );
                      setState(() {});
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 150,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.black,
            body: Consumer<PhotographerController>(
                builder: (context, controller, child) {
              return FutureBuilder(
                  future: controller.readPhotographerData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      );
                    }
                    final userData = controller.currentUserData!;

                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    await _pickImageFromGallery();
                                    print('Image picked from gallery.');
                                    await _uploadImageToFirebase();
                                  },
                                  child: Container(
                                    width: 90,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      image: userData.profileUrl.isNotEmpty
                                          ? DecorationImage(
                                              fit: BoxFit.fill,
                                              image: NetworkImage(
                                                  userData.profileUrl))
                                          : const DecorationImage(
                                              fit: BoxFit.fill,
                                              image: AssetImage(
                                                  'assets/placeholder.png'),
                                            ),
                                    ),
                                    child: userData.profileUrl.isEmpty
                                        ? const Center(child: Text("Photo"))
                                        : const SizedBox(),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userData.name,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        const SizedBox(
                                          width: 150,
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              bottomsheet(userData.id);

                                              nameController.text =
                                                  userData.name.toString();
                                              placeController.text =
                                                  userData.place.toString();
                                              phoneNumber.text = userData
                                                  .phoneNumber
                                                  .toString();
                                            },
                                            child: const Text(
                                              'Edit Profile',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 15),
                                            ))
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      userData.typePhotographer,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // _launchgogglemap();
                                            openMap();
                                          },
                                          child: const Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        Text(
                                          userData.place,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            await _makePhoneCall(userData
                                                .phoneNumber
                                                .toString());
                                            log('click call');
                                          },
                                          child: const Icon(
                                            Icons.phone,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        Text(
                                          userData.phoneNumber.toString(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const Spacer(),
                                Expanded(
                                  child: Column(
                                    children: [
                                      PopupMenuButton<int>(
                                        icon: const Icon(
                                          Icons.menu,
                                          color: Colors.white,
                                        ),
                                        onSelected: (int index) {
                                          if (index == 5) {
                                            FirebaseAuth.instance
                                                .signOut()
                                                .then((value) {
                                              Navigator.of(context)
                                                  .pushAndRemoveUntil(
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const SplashScreen()),
                                                      (route) => false);
                                            });
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => _pages[
                                                    index], // Use the selected index
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return List.generate(
                                            _pagesname.length,
                                            (index) => PopupMenuItem(
                                              value:
                                                  index, // Set the value to the index
                                              child: Text(_pagesname[index]),
                                            ),
                                          ).toList();
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          FutureBuilder(
                              future:
                                  controller.readCurrentPhotoGrapherrPhotoa(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Expanded(child: SizedBox());
                                }
                                final postList = controller.currentUserPosts;

                                return postList.isEmpty
                                    ? const Expanded(
                                        child: Center(
                                        child: Text(
                                          "No Post",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ))
                                    : Expanded(
                                        child: GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 20,
                                          crossAxisSpacing:20,
                                        ),
                                        itemCount: postList.length,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                              onLongPress: () {
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (context) =>
                                                            AlertDialog(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              elevation: 0,
                                                              alignment: Alignment
                                                                  .bottomCenter,
                                                              title:
                                                                  ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor: Colors
                                                                              .black,
                                                                          shape: ContinuousRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                  20))),
                                                                      onPressed:
                                                                          () {
                                                                        controller
                                                                            .deletePostByPG(postList[index].postId)
                                                                            .then((val) {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                        "Delete",
                                                                        style: TextStyle(
                                                                            color: Colors
                                                                                .white,
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.w400),
                                                                      )),
                                                            ));
                                              },
                                              child: Container(
                                                child: FutureBuilder<String>(
                                                  future: getImageUrl(
                                                      postList[index]
                                                          .referenceNumber),
                                                  builder: (context, snapshot) {
                                                    print(
                                                        "snapshot data : ${snapshot.data}");

                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }

                                                    if (snapshot.hasError) {
                                                      print(
                                                          "Error in FutureBuilder: ${snapshot.error}");
                                                      return const Icon(
                                                          Icons.error,
                                                          color: Colors.red);
                                                    }

                                                    if (snapshot.data == null ||
                                                        snapshot
                                                            .data!.isEmpty) {
                                                      return const Text(
                                                          'No image found');
                                                    }

                                                    return Image.network(
                                                      snapshot.data!,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;

                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    (loadingProgress
                                                                            .expectedTotalBytes ??
                                                                        1)
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        print(
                                                            "Error loading image: $error");
                                                        return const Icon(
                                                            Icons.error,
                                                            color: Colors.red);
                                                      },
                                                    );
                                                  },
                                                ),
                                              ));
                                        },
                                      ));
                              })
                        ]));
                  });
            })));
  }
}
    

   
// import 'dart:developer';
// import 'dart:io';
// import 'package:captura_lens/about_us.dart';
// import 'package:captura_lens/forgot_password.dart';
// import 'package:captura_lens/services/photographer_controller.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../user/complaints_page.dart';
// import '../help_page.dart';
// import '../support_page.dart';
// import 'package:flutter/foundation.dart';

// class PhotoProfile extends StatefulWidget {
//   final bool isPhoto;
//   const PhotoProfile({super.key, required this.isPhoto});

//   @override
//   State<PhotoProfile> createState() => _PhotoProfileState();
// }

// class _PhotoProfileState extends State<PhotoProfile> {
//   final nameController = TextEditingController();
//   final placeController = TextEditingController();
//   final phoneNumber = TextEditingController();

//   dynamic selectedImage;
//   bool isUploading = false; // To track upload progress

//   // Function to Pick Image from Gallery
//  Future<void> _pickImageFromGallery() async {
//   final ImagePicker picker = ImagePicker();
//   final XFile? returnImage = await picker.pickImage(source: ImageSource.gallery);

//   if (returnImage == null) return;

//   if (kIsWeb) {
//     // Web: Await the readAsBytes function before setting state
//     Uint8List imageBytes = await returnImage.readAsBytes();  // ✅ Ensure await is used
//     setState(() {
//       selectedImage = imageBytes; // Now it's correctly a Uint8List
//     });
//   } else {
//     // Mobile: Store as File
//     setState(() {
//       selectedImage = File(returnImage.path);
//     });
//   }
//   await _uploadImageToFirebase();
// }

// Future<void> _uploadImageToFirebase() async {
//   if (selectedImage == null) return;

//   try {
//     SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
//     final currentTime = DateTime.now().millisecondsSinceEpoch;
//     Reference ref = FirebaseStorage.instance.ref().child("shopTagImage/Shop$currentTime");

//     UploadTask uploadTask;

//     if (kIsWeb) {
//       // ✅ Ensure selectedImage is correctly awaited before passing to putData
//       uploadTask = ref.putData(selectedImage as Uint8List, metadata);
//     } else {
//       uploadTask = ref.putFile(selectedImage as File, metadata);
//     }

//     TaskSnapshot snapshot = await uploadTask;
//     String rawUrl = await snapshot.ref.getDownloadURL();

//     print("Image uploaded to Firebase Storage. URL: $rawUrl");

//     await FirebaseFirestore.instance
//         .collection("Photographers")
//         .doc(FirebaseAuth.instance.currentUser!.uid)
//         .update({"profileUrl": rawUrl});

//     setState(() {}); // Refresh UI after upload
//   } catch (e) {
//     print("Upload Error: $e");
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: Consumer<PhotographerController>(
//           builder: (context, controller, child) {
//             return FutureBuilder(
//               future: controller.readPhotographerData(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator(color: Colors.white));
//                 }
//                 final userData = controller.currentUserData;

//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: const BoxDecoration(color: Colors.black),
//                         child: Row(
//                           children: [
//                             GestureDetector(
//                               onTap: _pickImageFromGallery,
//                               child: Stack(
//                                 children: [
//                                   Container(
//                                     width: 90,
//                                     height: 100,
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       image: selectedImage != null
//                                           ? DecorationImage(
//                                               fit: BoxFit.fill,
//                                               image: kIsWeb
//                                                   ? MemoryImage(selectedImage as Uint8List)
//                                                   : FileImage(selectedImage as File) as ImageProvider,
//                                             )
//                                           : userData?.profileUrl.isNotEmpty == true
//                                               ? DecorationImage(
//                                                   fit: BoxFit.fill,
//                                                   image: NetworkImage(userData!.profileUrl),
//                                                 )
//                                               : const DecorationImage(
//                                                   fit: BoxFit.fill,
//                                                   image: AssetImage("assets/default_avatar.png"), // Add a placeholder image in assets
//                                                 ),
//                                     ),
//                                   ),
//                                   if (isUploading)
//                                     const Positioned.fill(
//                                       child: Center(
//                                         child: CircularProgressIndicator(color: Colors.blue),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
                        
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
