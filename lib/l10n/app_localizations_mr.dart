// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'राइड करो';

  @override
  String get nearbyRideRequests => 'जवळच्या राइड विनंत्या';

  @override
  String get accept => 'स्वीकारा';

  @override
  String get myAccount => 'माझे खाते';

  @override
  String get name => 'नाव';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get userType => 'वापरकर्ता प्रकार';

  @override
  String get language => 'भाषा';

  @override
  String get driver => 'चालक';

  @override
  String get rider => 'सवारी';

  @override
  String get english => 'इंग्रजी';

  @override
  String get marathi => 'मराठी';

  @override
  String get yourLocation => 'तुमचे स्थान';

  @override
  String get pickup => 'पिकअप';

  @override
  String get drop => 'ड्रॉप';

  @override
  String get fare => 'भाडे';

  @override
  String get from => 'पासून';

  @override
  String get to => 'पर्यंत';

  @override
  String get noRideRequestsNearby => 'जवळ कोणतीही राइड विनंती नाही.';

  @override
  String acceptedRideFrom(Object riderName) {
    return '$riderName कडून राइड स्वीकारली!';
  }

  @override
  String errorPlottingRoute(Object error) {
    return 'मार्ग प्लॉट करताना त्रुटी: $error';
  }

  @override
  String get login => 'लॉगिन';

  @override
  String get createAccount => 'खाते तयार करा';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्डची पुष्टी करा';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signUp => 'साइन अप';

  @override
  String get alreadyHaveAccount => 'आधीपासून खाते आहे?';

  @override
  String get dontHaveAccount => 'खाते नाही?';

  @override
  String get enterOTP => 'OTP प्रविष्ट करा';

  @override
  String get verify => 'सत्यापित करा';

  @override
  String get resendOTP => 'OTP पुन्हा पाठवा';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get locationPermissionRequired => 'स्थान परवानगी आवश्यक';

  @override
  String get locationPermissionMessage =>
      'तुमचे स्थान नकाशावर दर्शवण्यासाठी या अॅपला स्थान प्रवेशाची आवश्यकता आहे. कृपया तुमच्या डिव्हाइस सेटिंग्जमध्ये ते सक्षम करा.';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get openSettings => 'सेटिंग्ज उघडा';

  @override
  String get selectPickupAndDrop =>
      'कृपया पिकअप आणि ड्रॉप दोन्ही ठिकाणे निवडा.';

  @override
  String error(Object errorMessage) {
    return 'त्रुटी: $errorMessage';
  }

  @override
  String get searchPickupLocation => 'पिकअप स्थान शोधा';

  @override
  String get searchDropLocation => 'ड्रॉप स्थान शोधा';

  @override
  String get smallCar => 'लहान';

  @override
  String get largeCar => 'मोठी';

  @override
  String get auto => 'ऑटो';

  @override
  String get bike => 'बाईक';

  @override
  String get requestRide => 'राइडची विनंती करा';
}
