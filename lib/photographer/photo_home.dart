 
import 'package:captura_lens/constants.dart';
import 'package:captura_lens/photographer/photo_activity.dart';
import 'package:captura_lens/photographer/photo_add_post.dart';
import 'package:captura_lens/photographer/photo_home_details.dart';
import 'package:captura_lens/photographer/photo_notification.dart';
import 'package:captura_lens/photographer/photo_profile.dart';
import 'package:flutter/material.dart';

class PhotoHome extends StatefulWidget {
  const PhotoHome({super.key});

  @override
  State<PhotoHome> createState() => _PhotoHomeState();
}

class _PhotoHomeState extends State<PhotoHome> {
  
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const PhotoHomeDetails(),
    const PhotoActivity(),
    const PhotoAddPost(),
    const PhotoNotification(),
    PhotoProfile(
      isPhoto: true,
    )
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: CustomColors.buttonGrey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: Colors.black,
              ),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.view_comfy_alt_sharp,
                color: Colors.black,
              ),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.add,
                color: Colors.black,
              ),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications,
                color: Colors.black,
              ),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: Colors.black,
              ),
              label: '')
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black12,
        onTap: _onItemTapped,
        showSelectedLabels: false,
      ),
    );
  }
}
