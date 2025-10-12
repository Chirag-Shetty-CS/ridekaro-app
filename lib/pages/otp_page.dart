import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  String? _message;
  Color? _messageColor;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _handleOTPSubmit(Map<String, dynamic> arguments) async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() {
        _message = 'Please enter a valid 6-digit OTP';
        _messageColor = const Color(0xFFD32F2F); // Crimson Red
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: arguments['verificationId'],
        smsCode: otp,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      User? newUser = userCredential.user;

      if (newUser != null) {
        if (arguments['isSigningUp'] == true) {
          await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
            'name': arguments['name'],
            'phoneNumber': arguments['phoneNumber'],
            'email': arguments['email'],
            'userType': arguments['userType'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // **MODIFICATION HERE: Navigate to the home screen**
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);

      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Invalid OTP or error occurred: ${e.code}';
        _messageColor = const Color(0xFFD32F2F);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phoneNumber = arguments?['phoneNumber'] as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1C1C),
              Color(0xFF2E2E2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ride Karo', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Enter OTP sent to $phoneNumber', style: const TextStyle(fontSize: 16, color: Color(0xFFAAAAAA))),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      prefixIcon: const Icon(Icons.lock_open_outlined, color: Color(0xFFFAFAFA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFCC00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleOTPSubmit(arguments ?? {}),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C1C1C)))
                          : const Text('Submit OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_message != null)
                    AnimatedOpacity(
                      opacity: _message != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _messageColor?.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(_message!, style: TextStyle(color: _messageColor, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _message = 'OTP resent to $phoneNumber';
                        _messageColor = const Color(0xFF03A9F4);
                      });
                    },
                    child: const Text('Resend OTP', style: TextStyle(color: Color(0xFF03A9F4), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}