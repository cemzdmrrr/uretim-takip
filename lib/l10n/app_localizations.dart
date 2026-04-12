import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'TexPilot'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get next;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @none.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbiri'**
  String get none;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için giriş yapın'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In tr, this message translates to:
  /// **'Beni hatırla'**
  String get rememberMe;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @loginError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Hatası'**
  String get loginError;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta gerekli'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta girin'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordMinLength;

  /// No description provided for @secureConnection.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli bağlantı'**
  String get secureConnection;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @models.
  ///
  /// In tr, this message translates to:
  /// **'Modeller'**
  String get models;

  /// No description provided for @production.
  ///
  /// In tr, this message translates to:
  /// **'Üretim'**
  String get production;

  /// No description provided for @personnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get personnel;

  /// No description provided for @accounting.
  ///
  /// In tr, this message translates to:
  /// **'Muhasebe'**
  String get accounting;

  /// No description provided for @suppliers.
  ///
  /// In tr, this message translates to:
  /// **'Tedarikçiler'**
  String get suppliers;

  /// No description provided for @inventory.
  ///
  /// In tr, this message translates to:
  /// **'Stok'**
  String get inventory;

  /// No description provided for @shipping.
  ///
  /// In tr, this message translates to:
  /// **'Sevkiyat'**
  String get shipping;

  /// No description provided for @reports.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @dokuma.
  ///
  /// In tr, this message translates to:
  /// **'Dokuma'**
  String get dokuma;

  /// No description provided for @konfeksiyon.
  ///
  /// In tr, this message translates to:
  /// **'Konfeksiyon'**
  String get konfeksiyon;

  /// No description provided for @yikama.
  ///
  /// In tr, this message translates to:
  /// **'Yıkama'**
  String get yikama;

  /// No description provided for @utuPaket.
  ///
  /// In tr, this message translates to:
  /// **'Ütü Paket'**
  String get utuPaket;

  /// No description provided for @ilikDugme.
  ///
  /// In tr, this message translates to:
  /// **'İlik Düğme'**
  String get ilikDugme;

  /// No description provided for @kaliteKontrol.
  ///
  /// In tr, this message translates to:
  /// **'Kalite Kontrol'**
  String get kaliteKontrol;

  /// No description provided for @paketleme.
  ///
  /// In tr, this message translates to:
  /// **'Paketleme'**
  String get paketleme;

  /// No description provided for @nakis.
  ///
  /// In tr, this message translates to:
  /// **'Nakış'**
  String get nakis;

  /// No description provided for @productionPanels.
  ///
  /// In tr, this message translates to:
  /// **'Üretim Panelleri'**
  String get productionPanels;

  /// No description provided for @managementPanels.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim Panelleri'**
  String get managementPanels;

  /// No description provided for @financePanels.
  ///
  /// In tr, this message translates to:
  /// **'Finans Panelleri'**
  String get financePanels;

  /// No description provided for @invoices.
  ///
  /// In tr, this message translates to:
  /// **'Faturalar'**
  String get invoices;

  /// No description provided for @payments.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeler'**
  String get payments;

  /// No description provided for @salary.
  ///
  /// In tr, this message translates to:
  /// **'Bordro'**
  String get salary;

  /// No description provided for @overtime.
  ///
  /// In tr, this message translates to:
  /// **'Mesai'**
  String get overtime;

  /// No description provided for @leave.
  ///
  /// In tr, this message translates to:
  /// **'İzin'**
  String get leave;

  /// No description provided for @attendance.
  ///
  /// In tr, this message translates to:
  /// **'Puantaj'**
  String get attendance;

  /// No description provided for @total.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get total;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam Ediyor'**
  String get inProgress;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get cancelled;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @passive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get passive;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Silme Onayı'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu kaydı silmek istediğinizden emin misiniz?'**
  String get deleteConfirmMessage;

  /// No description provided for @saveSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarıyla oluşturuldu'**
  String get saveSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarıyla güncellendi'**
  String get updateSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarıyla silindi'**
  String get deleteSuccess;

  /// No description provided for @operationError.
  ///
  /// In tr, this message translates to:
  /// **'İşlem sırasında bir hata oluştu'**
  String get operationError;

  /// No description provided for @personnelNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Personel kaydı bulunamadı'**
  String get personnelNotFound;

  /// No description provided for @unauthorized.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok'**
  String get unauthorized;

  /// No description provided for @sessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süresi doldu, lütfen tekrar giriş yapın'**
  String get sessionExpired;

  /// No description provided for @dateFormat.
  ///
  /// In tr, this message translates to:
  /// **'dd.MM.yyyy'**
  String get dateFormat;

  /// No description provided for @dateTimeFormat.
  ///
  /// In tr, this message translates to:
  /// **'dd.MM.yyyy HH:mm'**
  String get dateTimeFormat;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'₺'**
  String get currency;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
