import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// CORRECTED: Simple, "non-bitchy" constructor
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  Color? _messageColor;

  Future<void> _verifyOtp() async {
    // CORRECTED: Get arguments here, where they are needed
    final arguments =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    if (_otpController.text.trim().length < 6) {
      setState(() {
        _message = "Please enter a valid 6-digit OTP.";
        _messageColor = Colors.red;
      });
      return;
    }
    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: arguments['verificationId'],
        smsCode: _otpController.text.trim(),
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        if (arguments['isSigningUp'] == true) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': arguments['name'],
            'email': arguments['email'],
            'phoneNumber': arguments['phoneNumber'],
            'userType': arguments['userType'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Verification failed: ${e.message}';
          _messageColor = Colors.red;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRECTED: Get arguments here to display phone number
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phoneNumber = arguments?['phoneNumber'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter the OTP sent to $phoneNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 20, letterSpacing: 8),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
                ),
              ),
              const SizedBox(height: 30),
              if (_message != null) ...[
                Text(_message!, style: TextStyle(color: _messageColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFCC00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C1C1C)))
                      : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
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

