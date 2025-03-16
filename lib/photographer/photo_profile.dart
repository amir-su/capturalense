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
// gs://capturalens-84b72/images/1741944117332
    try {
      final ref = FirebaseStorage.instanceFor(bucket: 'gs://capturalens-84b72')
          .ref()
          .child('images/$referenceNumber');
      print(ref);
      print('//***///******////////******');
      print('Reference Path: ${ref.fullPath}'); // Confirm path
      final url = await ref.getDownloadURL();
      print("Fetched URL: $url");
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
      });
    } else {
      // Mobile: Store as File
      setState(() {
        selectedImage = File(returnImage.path);
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (selectedImage == null) return;

    try {
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      Reference ref =
          FirebaseStorage.instance.ref().child("shopTagImage/Shop$currentTime");

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web: Upload as Uint8List
        uploadTask = ref.putData(selectedImage as Uint8List, metadata);
      } else {
        // Mobile: Upload as File
        uploadTask = ref.putFile(selectedImage as File, metadata);
      }

      TaskSnapshot snapshot = await uploadTask;
      String rawUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded to Firebase Storage. URL: $rawUrl");
      print('!!!!!!!!!!!!!!!!!!!!!!');

      await FirebaseFirestore.instance
          .collection("Photographers")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"profileUrl": rawUrl});

      setState(() {}); // Refresh UI after upload
    } catch (e) {
      print("Upload Error: $e");
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

                      // Map<String,dynamic> updateCompetitionid =
                      // log('id the edit $id');
                      // Navigator.pop(context);
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
    final size = MediaQuery.of(context).size;
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
                    final userData = controller.currentUserData;

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
                                    await _uploadImageToFirebase();
                                  },
                                  child: Container(
                                    width: 90,
                                    height: 100,

                                    // decoration: BoxDecoration(
                                    //     color: Colors.white,
                                    //     image: userData!.profileUrl.isNotEmpty
                                    //         ? DecorationImage(
                                    //             fit: BoxFit.fill,
                                    //             image:
                                    //                 NetworkImage(userData.profileUrl))
                                    //         : const DecorationImage(
                                    //             fit: BoxFit.fill,
                                    //             image: NetworkImage(
                                    //                 "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAARMAAAC3CAMAAAAGjUrGAAAAMFBMVEXx8/XCy9K/yND09vfw8vTP1tzp7O/i5ure4+fO1dvJ0dfT2d/EzNPt7/Lb4OXo6+4FeM7UAAAFL0lEQVR4nO2c24KrIAxFLdha7///t0dxOlWDSiAKztnrbR4G6SoJBKHZA6zJYncgQeCEAicUOKHACQVOKHBCgRMKnFDghAInFDihwAkFTihwQoETCpxQ4IQCJxQ4ocAJBU4ocEKBEwqcUOCEAicUOKHACQVOKHBCgRMKnFDghAInFDihwAkFTihwQoETCpxQ4IQCJxQ4ocAJBU4ot3Oi1KMq64FnWTVq+EueWzlRquqKVn/J+/ezEfdyHydKPYtc62yF1m1Xymq5ixPVdDnx8eslf1eCVu7hRFXFppAfLW39kNJyByeqOTJirGTvRsbKDZyozsHIpKUQsZK8E1Vu55GTrKTuRL0ZRoyVLviZaTtRVctUMuaVOnCoJO1E1WwjxsorbGZO2Qk7br5WuhApKTvpfZWMy5WAoZKuk6b1NhI4VJJ10uRBSsas0ng+OlUnVaARw9NvqCTqRERJpt9eUtJ0IqPEN36SdNIIKRnIPeafFJ0Ep9c5mr+qTdFJ2CRMpLAn5fScqJeokrFWZkoRdaImwtpw2T9iSnnxuiDoRFXda6hK28JzWTA14ryBxKFlTT9iTlT1W57o3Lta96yED8krRieknCw/DDuEP1TnKBlgzMlCTtZDXr+8pIjOwitK5x7JOKFD3mukiE85ix45S5FxYll46prdiv8ekpsU19wv4kS9LV1ouQPlrPzKliIzTuw9YDYiVfgFSxFx8rR+wcyMomSX9HYpTjlFwonqrB3gBc/JyYQjRcRJYe8Ay4l9rMlLcVi8iTjp7Y/nOBHcMjngWEoi4+TUlcmKw9rnxHzCWMqeU/ltkB9JEZl3SusnYmwQn1fm2GgPeiOzZrM9WZfu/3/BNDznYATLOLENffep+JppeMZBMSZUF9N6ljFM7KF3qpTduBZyQj4W53XTiRsEm1L2dr2k9k9W9Rtjq2BrJj9Zyk7pI7bP9lw8kfH+4KIFLGF77Sa3R90Un0POvHNCcYzsLVMk9+2buni1bd9xjMSJHMPmjCz7zov/fidW5GQ7OS/2e8BoRrLtrBfXScTIMVLsk09cJxEjZ8I6+cR1EmG1tsRaDsZ0EjlyDL0leuxOpulD4JTALtfXORRbnqVO1LDOePdtpoclWPsqulL+wt0P0SNnxFKrrp2opmuXl+5OuHA3PSmByDGQ9ezSydYdM+ELd4YUIsdANnoWTva2RSUv3JlnJRE5I2RbY+6kee1+dTrrhC7cPTZeMUdivZnydaIc3tdqqWuI6USOYZlSfp0oxzVlJxNByUSOYZlSPk6cDzqEXy17JDTn/LBMKRlTSRZ4X2giep2zZnEwZHLiGjifFt6BTtKKHMMspUxO2BkvDzoDm1jkGGa7bsaJx0t9XfgrOfuMlhezwsc48RrKufvhyiXXHatg8T2Zkm0eHzluxO8W4pXHKljkXycBt3h9blFdeqyCx2fPOguLbn6qTWsBu+Czxs/CopsdP4kmkx+mcZ8FRrfuWUqSTSYT005keDucW4iXnzRhMg17iYacC6A0VyZzzIQs0pBrUrn22JoXY4Us0pDjaZMzb+dIMX6/Qi0dHSU0XHySz48heqSaOs60vsvlq2mtpzj9OCh/Trgjew7afgLar63d6ec2SmTZm37+UyV7048K+Gmkm7O10A/8aaSbY7sEr8rYvYoNnX4Sr3EuYJVpVc35Ccu/innZbryMJ1n4v9f4N9FZ39XPZ931GYzMGH9VPHYfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADp8Q9+nG9anuOrfAAAAABJRU5ErkJggg=="))),
                                    child: userData!.profileUrl.isEmpty
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
                                print(
                                    'Firestore Reference Number: ${postList[0].referenceNumber}');

                                print('*********/////////******');
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
                                                      "https://firebasestorage.googleapis.com/v0/b/capturalens-84b72/o/images%2F1741947457110?alt=media&token=d2ad18eb-717f-493d-a4c1-2dfdef83da32",
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
