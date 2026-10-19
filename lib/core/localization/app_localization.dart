import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/providers.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => Locale(
      ref.watch(sharedPreferencesProvider).getString('app_language') == 'hi'
          ? 'hi'
          : 'en');
  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'hi') return;
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setString('app_language', code);
    if (!saved) throw StateError('Could not save language');
    state = Locale(code);
  }
}

extension AppTranslation on BuildContext {
  String tr(String text) => Localizations.localeOf(this).languageCode == 'hi'
      ? _hindi[text] ?? text
      : text;
}

const _hindi = <String, String>{
  'Welcome back': 'वापस स्वागत है',
  'Log in to browse products and manage your cart.':
      'उत्पाद देखने और अपनी कार्ट सँभालने के लिए लॉग इन करें।',
  'Username': 'उपयोगकर्ता नाम',
  'Password': 'पासवर्ड',
  'Log in': 'लॉग इन',
  'Show password': 'पासवर्ड दिखाएँ',
  'Hide password': 'पासवर्ड छिपाएँ',
  'Enter your username': 'उपयोगकर्ता नाम दर्ज करें',
  'Username must be at least 3 characters':
      'उपयोगकर्ता नाम कम से कम 3 अक्षर का होना चाहिए',
  'Enter your password': 'पासवर्ड दर्ज करें',
  'Password must be at least 6 characters':
      'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
  'Invalid username or password.': 'उपयोगकर्ता नाम या पासवर्ड गलत है।',
  'Your session expired. Please log in again.':
      'आपका सत्र समाप्त हो गया। फिर से लॉग इन करें।',
  'Shop': 'दुकान',
  'Cart': 'कार्ट',
  'Profile': 'प्रोफ़ाइल',
  'Your profile': 'आपकी प्रोफ़ाइल',
  'Wishlist': 'पसंदीदा',
  'Your wishlist is empty': 'आपकी पसंदीदा सूची खाली है',
  'Tap a heart to save products for later.':
      'उत्पाद सहेजने के लिए दिल के चिह्न पर टैप करें।',
  'Save to wishlist': 'पसंदीदा में सहेजें',
  'Remove from wishlist': 'पसंदीदा से हटाएँ',
  'Could not save favourites. Please try again.':
      'पसंदीदा सहेज नहीं सके। फिर कोशिश करें।',
  'A little discovery, every day.': 'हर दिन कुछ नया पाएँ।',
  'Find your next everyday favourite.': 'रोज़मर्रा की अपनी अगली पसंद खोजें।',
  'Search products': 'उत्पाद खोजें',
  'Clear search': 'खोज मिटाएँ',
  'Sort products': 'उत्पाद क्रमबद्ध करें',
  'All': 'सभी',
  'Featured': 'चुनिंदा',
  'Price: low to high': 'कीमत: कम से अधिक',
  'Price: high to low': 'कीमत: अधिक से कम',
  'Top rated': 'सर्वश्रेष्ठ रेटिंग',
  'Title: A to Z': 'नाम: A से Z',
  'No products found': 'कोई उत्पाद नहीं मिला',
  'Try a different search or category.': 'कोई दूसरी खोज या श्रेणी चुनें।',
  'There is nothing to show right now.': 'अभी दिखाने के लिए कुछ नहीं है।',
  'Clear filters': 'फ़िल्टर हटाएँ',
  'Refresh': 'ताज़ा करें',
  'Retry': 'फिर कोशिश करें',
  'Try again': 'फिर कोशिश करें',
  'Retry refresh': 'फिर से ताज़ा करें',
  'Could not load more. Retry': 'और उत्पाद लोड नहीं हुए। फिर कोशिश करें',
  'You have seen everything': 'आपने सभी उत्पाद देख लिए हैं',
  'You are offline. Showing saved products.':
      'आप ऑफ़लाइन हैं। सहेजे हुए उत्पाद दिखाए जा रहे हैं।',
  'Product not found': 'उत्पाद नहीं मिला',
  'This product may have been removed or never existed.':
      'यह उत्पाद हटा दिया गया है या उपलब्ध नहीं है।',
  'Back to shop': 'दुकान पर वापस जाएँ',
  'Select a product': 'उत्पाद चुनें',
  'Pick something from the list to see its details.':
      'विवरण देखने के लिए सूची से कोई उत्पाद चुनें।',
  'Quantity': 'मात्रा',
  'Add to cart': 'कार्ट में जोड़ें',
  'Out of stock': 'स्टॉक में नहीं है',
  'In stock': 'स्टॉक में है',
  'Customer reviews': 'ग्राहकों की समीक्षाएँ',
  'No reviews yet.': 'अभी कोई समीक्षा नहीं है।',
  'Added to cart': 'कार्ट में जोड़ दिया गया',
  'View cart': 'कार्ट देखें',
  'Subtotal': 'उप-योग',
  'Discount': 'छूट',
  'Grand total': 'कुल राशि',
  'Total': 'कुल',
  'Place order': 'ऑर्डर करें',
  'Your cart is empty': 'आपकी कार्ट खाली है',
  'Continue shopping': 'खरीदारी जारी रखें',
  'Start shopping': 'खरीदारी शुरू करें',
  'Order summary': 'ऑर्डर का विवरण',
  'Remove item': 'उत्पाद हटाएँ',
  'Order placed': 'ऑर्डर हो गया',
  'Thanks for shopping with ShopSphere.':
      'ShopSphere से खरीदारी के लिए धन्यवाद।',
  'This is a simulated order, so nothing is saved on the server.':
      'यह एक नमूना ऑर्डर है, इसलिए सर्वर पर कुछ सहेजा नहीं जाता।',
  'First name': 'पहला नाम',
  'Last name': 'अंतिम नाम',
  'Email': 'ईमेल',
  'Phone': 'फ़ोन',
  'Not provided': 'जानकारी नहीं दी गई',
  'Log out': 'लॉग आउट',
  'Log out?': 'लॉग आउट करें?',
  'You will need to log in again to keep shopping.':
      'खरीदारी जारी रखने के लिए फिर लॉग इन करना होगा।',
  'Cancel': 'रद्द करें',
  'Switch to light theme': 'लाइट थीम चुनें',
  'Switch to dark theme': 'डार्क थीम चुनें',
  'Could not save theme. Please try again.':
      'थीम सहेज नहीं सके। फिर कोशिश करें।',
  'Could not start ShopSphere': 'ShopSphere शुरू नहीं हो सका',
  'Please check your connection.': 'अपना इंटरनेट कनेक्शन जाँचें।',
  'Something went wrong': 'कुछ गड़बड़ हुई',
  'No internet connection. Check your network and try again.':
      'इंटरनेट कनेक्शन नहीं है। नेटवर्क जाँचकर फिर कोशिश करें।',
  'The request took too long. Check your connection and try again.':
      'अनुरोध में अधिक समय लगा। कनेक्शन जाँचकर फिर कोशिश करें।',
  'Something unexpected happened. Please try again.':
      'कोई अनपेक्षित समस्या हुई। फिर कोशिश करें।',
  'We could not load products.': 'उत्पाद लोड नहीं हो सके।',
  'We could not load this product.': 'यह उत्पाद लोड नहीं हो सका।',
  'We could not load your profile.': 'आपकी प्रोफ़ाइल लोड नहीं हो सकी।',
  'Increase quantity': 'मात्रा बढ़ाएँ',
  'Decrease quantity': 'मात्रा घटाएँ',
  'Language': 'भाषा'
};

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
        tooltip: context.tr('Language'),
        icon: const Icon(Icons.translate),
        initialValue: ref.watch(localeProvider).languageCode,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'en', child: Text('English')),
          PopupMenuItem(value: 'hi', child: Text('हिन्दी')),
        ],
        onSelected: (code) async {
          try {
            await ref.read(localeProvider.notifier).setLanguage(code);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Could not save language / भाषा सहेज नहीं सके')));
            }
          }
        },
      );
}

class HindiMaterialLocalizations extends DefaultMaterialLocalizations {
  const HindiMaterialLocalizations();
  @override
  String get backButtonTooltip => 'वापस';
  @override
  String get closeButtonTooltip => 'बंद करें';
  @override
  String get cancelButtonLabel => 'रद्द करें';
  @override
  String get okButtonLabel => 'ठीक है';
  @override
  String get copyButtonLabel => 'कॉपी करें';
  @override
  String get pasteButtonLabel => 'पेस्ट करें';
  @override
  String get cutButtonLabel => 'काटें';
  @override
  String get selectAllButtonLabel => 'सभी चुनें';
  @override
  String get searchFieldLabel => 'खोजें';
  @override
  String get moreButtonTooltip => 'और';
}

class AppMaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(locale.languageCode == 'hi'
          ? const HindiMaterialLocalizations()
          : const DefaultMaterialLocalizations());
  @override
  bool shouldReload(AppMaterialDelegate old) => false;
}

class AppWidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const AppWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultWidgetsLocalizations());
  @override
  bool shouldReload(AppWidgetsDelegate old) => false;
}
