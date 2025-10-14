// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ride Karo';

  @override
  String get nearbyRideRequests => 'Nearby Ride Requests';

  @override
  String get accept => 'Accept';

  @override
  String get myAccount => 'My Account';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get userType => 'User Type';

  @override
  String get language => 'Language';

  @override
  String get driver => 'Driver';

  @override
  String get rider => 'Rider';

  @override
  String get english => 'English';

  @override
  String get marathi => 'Marathi';

  @override
  String get yourLocation => 'Your Location';

  @override
  String get pickup => 'Pickup';

  @override
  String get drop => 'Drop';

  @override
  String get fare => 'Fare';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get noRideRequestsNearby => 'No ride requests nearby.';

  @override
  String acceptedRideFrom(Object riderName) {
    return 'Accepted ride from $riderName!';
  }

  @override
  String errorPlottingRoute(Object error) {
    return 'Error plotting route: $error';
  }

  @override
  String get login => 'Login';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get verify => 'Verify';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get locationPermissionMessage =>
      'This app needs location access to show your position on the map. Please enable it in your device settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get selectPickupAndDrop =>
      'Please select both pickup and drop locations.';

  @override
  String error(Object errorMessage) {
    return 'Error: $errorMessage';
  }

  @override
  String get searchPickupLocation => 'Search Pickup Location';

  @override
  String get searchDropLocation => 'Search Drop Location';

  @override
  String get smallCar => 'Small';

  @override
  String get largeCar => 'Large';

  @override
  String get auto => 'Auto';

  @override
  String get bike => 'Bike';

  @override
  String get requestRide => 'Request Ride';
}
