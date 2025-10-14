import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setEnglish() {
    setLocale(const Locale('en'));
  }

  void setMarathi() {
    setLocale(const Locale('mr'));
  }

  String get languageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }
}



