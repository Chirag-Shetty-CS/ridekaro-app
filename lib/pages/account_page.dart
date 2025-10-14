import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // --- State Variables ---
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- Fetches user data from Firebase ---
  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      try {
        // Query Firestore by phone number
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: _user!.phoneNumber)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userData = querySnapshot.docs.first.data();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userData = null;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        if (mounted) {
          setState(() {
            _userData = null;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Handles the logout process ---
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login screen and remove all previous routes
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // --- Helper widget to build labeled detail rows ---
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely get and capitalize the userType before building the widget
    String userType = 'N/A';
    if (_userData?['userType'] is String) {
      String originalUserType = _userData!['userType'];
      if (originalUserType.isNotEmpty) {
        userType = originalUserType[0].toUpperCase() + originalUserType.substring(1);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF2E2E2E),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      )
          : _user == null || _userData == null
          ? const Center(
        child: Text(
          'Could not load user data.',
          style: TextStyle(color: Colors.white70),
        ),
      )
      // --- THIS IS THE FIX: Wrap the content in a Center widget ---
          : Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            mainAxisSize: MainAxisSize.min, // Take up only needed space
            children: [
              // --- Profile Picture ---
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF1C1C1C),
                backgroundImage: AssetImage('assets/images/default_user.jpg'),
              ),
              const SizedBox(height: 32),

              // --- Details Container ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Name:',
                      _userData?['name'] ?? 'N/A',
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildDetailRow(
                      'Phone Number:',
                      _userData?['phoneNumber'] ?? 'N/A',
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildDetailRow(
                      'User Type:',
                      userType,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

