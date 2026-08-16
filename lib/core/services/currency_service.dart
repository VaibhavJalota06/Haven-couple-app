import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static CurrencyInfo _current = const CurrencyInfo(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    flag: '🇮🇳',
  );

  static final ValueNotifier<CurrencyInfo> notifier = ValueNotifier<CurrencyInfo>(_current);

  static CurrencyInfo get current => notifier.value;
  static String get symbol => notifier.value.symbol;
  static String get code => notifier.value.code;
  static String get name => notifier.value.name;
  static String get flag => notifier.value.flag;

  static const Map<String, CurrencyInfo> _countryToCurrency = {
    'IN': CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    'US': CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    'GB': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    'UK': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    'EU': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    'FR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇫🇷'),
    'DE': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇩🇪'),
    'IT': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇮🇹'),
    'ES': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇸'),
    'NL': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇳🇱'),
    'BE': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇧🇪'),
    'AT': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇦🇹'),
    'PT': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇵🇹'),
    'IE': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇮🇪'),
    'JP': CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
    'CA': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦'),
    'AU': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
    'AE': CurrencyInfo(code: 'AED', symbol: 'AED ', name: 'UAE Dirham', flag: '🇦🇪'),
    'SA': CurrencyInfo(code: 'SAR', symbol: 'SAR ', name: 'Saudi Riyal', flag: '🇸🇦'),
    'SG': CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬'),
    'CH': CurrencyInfo(code: 'CHF', symbol: 'CHF ', name: 'Swiss Franc', flag: '🇨🇭'),
    'BR': CurrencyInfo(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', flag: '🇧🇷'),
    'MX': CurrencyInfo(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso', flag: '🇲🇽'),
    'KR': CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean Won', flag: '🇰🇷'),
    'CN': CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳'),
    'NZ': CurrencyInfo(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', flag: '🇳🇿'),
    'SE': CurrencyInfo(code: 'SEK', symbol: 'kr ', name: 'Swedish Krona', flag: '🇸🇪'),
    'NO': CurrencyInfo(code: 'NOK', symbol: 'kr ', name: 'Norwegian Krone', flag: '🇳🇴'),
    'DK': CurrencyInfo(code: 'DKK', symbol: 'kr ', name: 'Danish Krone', flag: '🇩🇰'),
    'ZA': CurrencyInfo(code: 'ZAR', symbol: 'R ', name: 'South African Rand', flag: '🇿🇦'),
    'RU': CurrencyInfo(code: 'RUB', symbol: '₽', name: 'Russian Ruble', flag: '🇷🇺'),
    'TR': CurrencyInfo(code: 'TRY', symbol: '₺', name: 'Turkish Lira', flag: '🇹🇷'),
    'TH': CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht', flag: '🇹🇭'),
    'ID': CurrencyInfo(code: 'IDR', symbol: 'Rp ', name: 'Indonesian Rupiah', flag: '🇮🇩'),
    'MY': CurrencyInfo(code: 'MYR', symbol: 'RM ', name: 'Malaysian Ringgit', flag: '🇲🇾'),
    'PH': CurrencyInfo(code: 'PHP', symbol: '₱', name: 'Philippine Peso', flag: '🇵🇭'),
    'VN': CurrencyInfo(code: 'VND', symbol: '₫', name: 'Vietnamese Dong', flag: '🇻🇳'),
    'NG': CurrencyInfo(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', flag: '🇳🇬'),
    'PK': CurrencyInfo(code: 'PKR', symbol: 'Rs ', name: 'Pakistani Rupee', flag: '🇵🇰'),
    'BD': CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka', flag: '🇧🇩'),
  };

  static List<CurrencyInfo> get allCurrencies =>
      _countryToCurrency.values.toSet().toList();

  static Future<void> init() async {
    await _autoDetectRegion();
  }

  static Future<void> _autoDetectRegion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('user_selected_currency_code');
      if (savedCode != null) {
        final match = allCurrencies.where((c) => c.code == savedCode).firstOrNull;
        if (match != null) {
          _current = match;
          notifier.value = _current;
          debugPrint('🌐 CurrencyService: Loaded saved user preference: ${_current.code} (${_current.symbol})');
          return;
        }
      }

      // Check Timezone Offset (Detects actual host machine location accurately even on emulators!)
      final offset = DateTime.now().timeZoneOffset;
      final offsetMinutes = offset.inMinutes;

      if (offsetMinutes == 330) {
        // IST +05:30 (India)
        _current = _countryToCurrency['IN']!;
        notifier.value = _current;
        debugPrint('🌐 CurrencyService: Timezone auto-detected India (IST +05:30) -> INR (₹)');
        return;
      } else if (offsetMinutes == 345) {
        // Nepal (+05:45)
        _current = _countryToCurrency['IN']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 360) {
        // Bangladesh (+06:00)
        _current = _countryToCurrency['BD'] ?? _countryToCurrency['IN']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 300) {
        // Pakistan (+05:00)
        _current = _countryToCurrency['PK'] ?? _countryToCurrency['IN']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 240) {
        // UAE (+04:00)
        _current = _countryToCurrency['AE']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 180) {
        // Saudi Arabia / East Africa (+03:00)
        _current = _countryToCurrency['SA'] ?? _countryToCurrency['AE']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 540) {
        // Japan / Korea (+09:00)
        _current = _countryToCurrency['JP']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 480) {
        // Singapore / China / Malaysia (+08:00)
        _current = _countryToCurrency['SG'] ?? _countryToCurrency['CN']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 600 || offsetMinutes == 660) {
        // Australia (+10:00 / +11:00)
        _current = _countryToCurrency['AU']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 60 || offsetMinutes == 120) {
        // Europe (+01:00 / +02:00)
        _current = _countryToCurrency['EU']!;
        notifier.value = _current;
        return;
      } else if (offsetMinutes == 0) {
        // UK (UTC / GMT)
        _current = _countryToCurrency['GB']!;
        notifier.value = _current;
        return;
      }

      // Check Locale countryCode
      final locale = PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode?.toUpperCase();
      if (countryCode != null && _countryToCurrency.containsKey(countryCode)) {
        _current = _countryToCurrency[countryCode]!;
        notifier.value = _current;
        debugPrint('🌐 CurrencyService: Auto-detected region $countryCode -> ${_current.code} (${_current.symbol})');
        return;
      }

      // Fallback
      _current = _countryToCurrency['IN'] ?? _countryToCurrency['US']!;
      notifier.value = _current;
    } catch (e) {
      debugPrint('CurrencyService auto-detect error: $e');
      _current = _countryToCurrency['IN'] ?? _countryToCurrency['US']!;
      notifier.value = _current;
    }
  }

  static void setCurrency(CurrencyInfo currency) {
    _current = currency;
    notifier.value = _current;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_selected_currency_code', currency.code);
    });
  }

  static String format(num amount, {bool decimal = false}) {
    final formatPattern = decimal ? '#,##0.00' : '#,##0';
    final formatter = NumberFormat(formatPattern);
    return '${symbol}${formatter.format(amount)}';
  }
}

