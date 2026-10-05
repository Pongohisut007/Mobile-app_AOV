import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('th'),
  ];

  /// No description provided for @navHome.
  ///
  /// In th, this message translates to:
  /// **'หน้าหลัก'**
  String get navHome;

  /// No description provided for @navCommunity.
  ///
  /// In th, this message translates to:
  /// **'คอมมูนิตี้'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์'**
  String get navProfile;

  /// No description provided for @recommendedTitle.
  ///
  /// In th, this message translates to:
  /// **'เมนูแนะนำ'**
  String get recommendedTitle;

  /// No description provided for @seeMore.
  ///
  /// In th, this message translates to:
  /// **'ดูทั้งหมด'**
  String get seeMore;

  /// No description provided for @allRecipesTitle.
  ///
  /// In th, this message translates to:
  /// **'สูตรทั้งหมด'**
  String get allRecipesTitle;

  /// No description provided for @searchRecipeHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาสูตรอาหาร'**
  String get searchRecipeHint;

  /// No description provided for @ratingNew.
  ///
  /// In th, this message translates to:
  /// **'ใหม่'**
  String get ratingNew;

  /// No description provided for @favoriteRemoveTooltip.
  ///
  /// In th, this message translates to:
  /// **'เอาออกจากรายการโปรด'**
  String get favoriteRemoveTooltip;

  /// No description provided for @favoriteAddTooltip.
  ///
  /// In th, this message translates to:
  /// **'บันทึกลงรายการโปรด'**
  String get favoriteAddTooltip;

  /// No description provided for @loading.
  ///
  /// In th, this message translates to:
  /// **'กำลังโหลด...'**
  String get loading;

  /// No description provided for @noRecipesInCategory.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีเมนูในหมวดนี้'**
  String get noRecipesInCategory;

  /// No description provided for @noRecipesNamed.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบเมนูที่ชื่อ \"{query}\"'**
  String noRecipesNamed(String query);

  /// No description provided for @loadMoreRecipesFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดเมนูเพิ่มไม่สำเร็จ ลองอีกครั้ง'**
  String get loadMoreRecipesFailed;

  /// No description provided for @cartFallbackTitle.
  ///
  /// In th, this message translates to:
  /// **'เมนูนี้'**
  String get cartFallbackTitle;

  /// No description provided for @cartAdded.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม {title} ลงตะกร้าแล้ว'**
  String cartAdded(String title);

  /// No description provided for @cartAlreadyIn.
  ///
  /// In th, this message translates to:
  /// **'{title} อยู่ในตะกร้าแล้ว'**
  String cartAlreadyIn(String title);

  /// No description provided for @cartAddFailed.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม {title} ลงตะกร้าไม่สำเร็จ'**
  String cartAddFailed(String title);

  /// No description provided for @routeNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบหน้านี้'**
  String get routeNotFound;

  /// No description provided for @categoryAll.
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมด'**
  String get categoryAll;

  /// No description provided for @createRecipeTooltip.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตร'**
  String get createRecipeTooltip;

  /// No description provided for @searchTooltip.
  ///
  /// In th, this message translates to:
  /// **'ค้นหา'**
  String get searchTooltip;

  /// No description provided for @closeSearchTooltip.
  ///
  /// In th, this message translates to:
  /// **'ปิดการค้นหา'**
  String get closeSearchTooltip;

  /// No description provided for @errorWithMessage.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาด: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @noPostsInCategory.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีโพสต์ในหมวดนี้'**
  String get noPostsInCategory;

  /// No description provided for @noPostsNamed.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบโพสต์ที่ชื่อ \"{query}\"'**
  String noPostsNamed(String query);

  /// No description provided for @loadFailedTryAgain.
  ///
  /// In th, this message translates to:
  /// **'โหลดไม่สำเร็จ ลองอีกครั้ง'**
  String get loadFailedTryAgain;

  /// No description provided for @showMore.
  ///
  /// In th, this message translates to:
  /// **'แสดงเพิ่ม'**
  String get showMore;

  /// No description provided for @noData.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีข้อมูล'**
  String get noData;

  /// No description provided for @timeJustNow.
  ///
  /// In th, this message translates to:
  /// **'เมื่อกี้'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In th, this message translates to:
  /// **'{count} นาทีที่แล้ว'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In th, this message translates to:
  /// **'{count} ชั่วโมงที่แล้ว'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In th, this message translates to:
  /// **'{count} วันที่แล้ว'**
  String timeDaysAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In th, this message translates to:
  /// **'{count} เดือนที่แล้ว'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearsAgo.
  ///
  /// In th, this message translates to:
  /// **'{count} ปีที่แล้ว'**
  String timeYearsAgo(int count);

  /// No description provided for @anonymousUser.
  ///
  /// In th, this message translates to:
  /// **'ผู้ใช้งาน'**
  String get anonymousUser;

  /// No description provided for @viewCommentsTooltip.
  ///
  /// In th, this message translates to:
  /// **'ดูความคิดเห็น'**
  String get viewCommentsTooltip;

  /// No description provided for @signIn.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get signIn;

  /// No description provided for @editProfile.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขโปรไฟล์'**
  String get editProfile;

  /// No description provided for @yourKitchenTitle.
  ///
  /// In th, this message translates to:
  /// **'ครัวของคุณ'**
  String get yourKitchenTitle;

  /// No description provided for @appVersionFooter.
  ///
  /// In th, this message translates to:
  /// **'{appName} · เวอร์ชัน {version}'**
  String appVersionFooter(String appName, String version);

  /// No description provided for @settingsTitle.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า'**
  String get settingsTitle;

  /// No description provided for @cartTooltip.
  ///
  /// In th, this message translates to:
  /// **'ตะกร้า'**
  String get cartTooltip;

  /// No description provided for @myRecipes.
  ///
  /// In th, this message translates to:
  /// **'สูตรของฉัน'**
  String get myRecipes;

  /// No description provided for @myRecipesDetail.
  ///
  /// In th, this message translates to:
  /// **'เผยแพร่ {count} สูตร'**
  String myRecipesDetail(int count);

  /// No description provided for @purchasedRecipes.
  ///
  /// In th, this message translates to:
  /// **'ซื้อแล้ว'**
  String get purchasedRecipes;

  /// No description provided for @purchasedDetail.
  ///
  /// In th, this message translates to:
  /// **'{count} สูตร'**
  String purchasedDetail(int count);

  /// No description provided for @favorites.
  ///
  /// In th, this message translates to:
  /// **'รายการโปรด'**
  String get favorites;

  /// No description provided for @favoritesDetail.
  ///
  /// In th, this message translates to:
  /// **'บันทึกไว้ {count} สูตร'**
  String favoritesDetail(int count);

  /// No description provided for @drafts.
  ///
  /// In th, this message translates to:
  /// **'ฉบับร่าง'**
  String get drafts;

  /// No description provided for @draftsDetail.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่เสร็จ {count} สูตร'**
  String draftsDetail(int count);

  /// No description provided for @guest.
  ///
  /// In th, this message translates to:
  /// **'ผู้เยี่ยมชม'**
  String get guest;

  /// No description provided for @fieldName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อ'**
  String get fieldName;

  /// No description provided for @fieldEmail.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get fieldEmail;

  /// No description provided for @profileLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดโปรไฟล์ไม่สำเร็จ'**
  String get profileLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In th, this message translates to:
  /// **'ลองอีกครั้ง'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;

  /// No description provided for @passwordChangedOthersSignedOut.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่านแล้ว อุปกรณ์อื่นถูกออกจากระบบ'**
  String get passwordChangedOthersSignedOut;

  /// No description provided for @signOut.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In th, this message translates to:
  /// **'คุณเข้าสู่ระบบใหม่เพื่อดูสูตรของคุณได้ทุกเมื่อ'**
  String get signOutConfirmMessage;

  /// No description provided for @signOutAllTitle.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบทุกอุปกรณ์?'**
  String get signOutAllTitle;

  /// No description provided for @signOutAllMessage.
  ///
  /// In th, this message translates to:
  /// **'ทุกเครื่องที่เข้าสู่ระบบด้วยบัญชีนี้ รวมถึงเครื่องนี้ จะถูกออกจากระบบทันที'**
  String get signOutAllMessage;

  /// No description provided for @signOutAllAction.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบทั้งหมด'**
  String get signOutAllAction;

  /// No description provided for @signOutAllDevices.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบทุกอุปกรณ์'**
  String get signOutAllDevices;

  /// No description provided for @signOutAllDevicesHint.
  ///
  /// In th, this message translates to:
  /// **'ใช้เมื่อมือถือหาย หรือสงสัยว่ามีคนใช้บัญชี'**
  String get signOutAllDevicesHint;

  /// No description provided for @versionLabel.
  ///
  /// In th, this message translates to:
  /// **'เวอร์ชัน {version}'**
  String versionLabel(String version);

  /// No description provided for @settingsAccount.
  ///
  /// In th, this message translates to:
  /// **'บัญชี'**
  String get settingsAccount;

  /// No description provided for @changePassword.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรหัสผ่าน'**
  String get changePassword;

  /// No description provided for @settingsHelpAndTerms.
  ///
  /// In th, this message translates to:
  /// **'ความช่วยเหลือและข้อกำหนด'**
  String get settingsHelpAndTerms;

  /// No description provided for @helpAndSupport.
  ///
  /// In th, this message translates to:
  /// **'ช่วยเหลือและติดต่อ'**
  String get helpAndSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In th, this message translates to:
  /// **'นโยบายความเป็นส่วนตัว'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In th, this message translates to:
  /// **'ข้อกำหนดการใช้งาน'**
  String get termsOfUse;

  /// No description provided for @aboutApp.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับแอป'**
  String get aboutApp;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In th, this message translates to:
  /// **'เวอร์ชัน {version} · ไลเซนส์โอเพนซอร์ส'**
  String aboutAppSubtitle(String version);

  /// No description provided for @dangerZone.
  ///
  /// In th, this message translates to:
  /// **'โซนอันตราย'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชี'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In th, this message translates to:
  /// **'ปิดบัญชีและลบข้อมูลส่วนตัว กู้คืนไม่ได้'**
  String get deleteAccountHint;

  /// No description provided for @faqTitle.
  ///
  /// In th, this message translates to:
  /// **'คำถามที่พบบ่อย'**
  String get faqTitle;

  /// No description provided for @contactTeam.
  ///
  /// In th, this message translates to:
  /// **'ติดต่อทีมงาน'**
  String get contactTeam;

  /// No description provided for @emailCopied.
  ///
  /// In th, this message translates to:
  /// **'คัดลอกอีเมลแล้ว'**
  String get emailCopied;

  /// No description provided for @noAccountPrompt.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีบัญชี? '**
  String get noAccountPrompt;

  /// No description provided for @signUp.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิก'**
  String get signUp;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In th, this message translates to:
  /// **'มีบัญชีอยู่แล้ว? '**
  String get haveAccountPrompt;

  /// No description provided for @emailAddress.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In th, this message translates to:
  /// **'กรอกอีเมลของคุณ'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกอีเมล'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In th, this message translates to:
  /// **'กรอกอีเมลให้ถูกต้อง'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่าน'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสผ่าน'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกรหัสผ่าน'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'**
  String get passwordTooShort;

  /// No description provided for @passwordTooLong.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร'**
  String get passwordTooLong;

  /// No description provided for @showPassword.
  ///
  /// In th, this message translates to:
  /// **'แสดงรหัสผ่าน'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In th, this message translates to:
  /// **'ซ่อนรหัสผ่าน'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน?'**
  String get forgotPassword;

  /// No description provided for @orSignInWith.
  ///
  /// In th, this message translates to:
  /// **'หรือเข้าสู่ระบบด้วย'**
  String get orSignInWith;

  /// No description provided for @orSignUpWith.
  ///
  /// In th, this message translates to:
  /// **'หรือสมัครด้วย'**
  String get orSignUpWith;

  /// No description provided for @acceptTermsRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณายอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว'**
  String get acceptTermsRequired;

  /// No description provided for @displayName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อที่แสดง'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In th, this message translates to:
  /// **'กรอกชื่อที่แสดง'**
  String get displayNameHint;

  /// No description provided for @displayNameRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อที่แสดง'**
  String get displayNameRequired;

  /// No description provided for @displayNameTooLong.
  ///
  /// In th, this message translates to:
  /// **'ชื่อที่แสดงต้องไม่เกิน 150 ตัวอักษร'**
  String get displayNameTooLong;

  /// No description provided for @confirmPassword.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่าน'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสผ่านอีกครั้ง'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณายืนยันรหัสผ่าน'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงกัน'**
  String get passwordsDoNotMatch;

  /// No description provided for @termsAgreePrefix.
  ///
  /// In th, this message translates to:
  /// **'ฉันยอมรับ'**
  String get termsAgreePrefix;

  /// No description provided for @termsAgreeUserAgreement.
  ///
  /// In th, this message translates to:
  /// **'ข้อกำหนดการใช้งาน'**
  String get termsAgreeUserAgreement;

  /// No description provided for @termsAgreeAnd.
  ///
  /// In th, this message translates to:
  /// **' และ'**
  String get termsAgreeAnd;

  /// No description provided for @termsAgreePrivacy.
  ///
  /// In th, this message translates to:
  /// **'นโยบายความเป็นส่วนตัว'**
  String get termsAgreePrivacy;

  /// No description provided for @sessionExpired.
  ///
  /// In th, this message translates to:
  /// **'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'**
  String get sessionExpired;

  /// No description provided for @saving.
  ///
  /// In th, this message translates to:
  /// **'กำลังบันทึก...'**
  String get saving;

  /// No description provided for @currentPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านปัจจุบัน'**
  String get currentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสผ่านปัจจุบัน'**
  String get currentPasswordRequired;

  /// No description provided for @newPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่'**
  String get newPassword;

  /// No description provided for @passwordLengthHelper.
  ///
  /// In th, this message translates to:
  /// **'8-72 ตัวอักษร'**
  String get passwordLengthHelper;

  /// No description provided for @newPasswordSameAsOld.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม'**
  String get newPasswordSameAsOld;

  /// No description provided for @confirmNewPassword.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่านใหม่'**
  String get confirmNewPassword;

  /// No description provided for @newPasswordsDoNotMatch.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่ไม่ตรงกัน'**
  String get newPasswordsDoNotMatch;

  /// No description provided for @deletingAccount.
  ///
  /// In th, this message translates to:
  /// **'กำลังลบบัญชี...'**
  String get deletingAccount;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชีถาวร'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteIrreversible.
  ///
  /// In th, this message translates to:
  /// **'ลบแล้วกู้คืนไม่ได้'**
  String get deleteIrreversible;

  /// No description provided for @deleteBulletSignOut.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบทุกอุปกรณ์ และเข้าสู่ระบบด้วยบัญชีนี้ไม่ได้อีก'**
  String get deleteBulletSignOut;

  /// No description provided for @deleteBulletPersonalData.
  ///
  /// In th, this message translates to:
  /// **'ชื่อ รูปโปรไฟล์ และอีเมลถูกลบ กลับมาสมัครใหม่ด้วยอีเมลเดิมได้ แต่จะเป็นบัญชีใหม่'**
  String get deleteBulletPersonalData;

  /// No description provided for @deleteBulletRecipes.
  ///
  /// In th, this message translates to:
  /// **'สูตรที่คุณสร้างจะไม่แสดงให้ใครเห็นอีก ยกเว้นคนที่ซื้อไปแล้วยังเปิดดูได้'**
  String get deleteBulletRecipes;

  /// No description provided for @deleteBulletLibrary.
  ///
  /// In th, this message translates to:
  /// **'รายการโปรด ตะกร้า และสูตรที่คุณซื้อไว้จะหายไป'**
  String get deleteBulletLibrary;

  /// No description provided for @deleteBulletComments.
  ///
  /// In th, this message translates to:
  /// **'คอมเมนต์และรีวิวยังอยู่ แต่จะแสดงเป็น \"ผู้ใช้ที่ลบบัญชีแล้ว\"'**
  String get deleteBulletComments;

  /// No description provided for @confirmWithPassword.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันด้วยรหัสผ่าน'**
  String get confirmWithPassword;

  /// No description provided for @passwordEnter.
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสผ่าน'**
  String get passwordEnter;

  /// No description provided for @deleteUnderstand.
  ///
  /// In th, this message translates to:
  /// **'ฉันเข้าใจว่าการลบบัญชีกู้คืนไม่ได้'**
  String get deleteUnderstand;

  /// No description provided for @imageOpenFailed.
  ///
  /// In th, this message translates to:
  /// **'เปิดรูปไม่ได้: {error}'**
  String imageOpenFailed(String error);

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรูปโปรไฟล์'**
  String get changeProfilePhoto;

  /// No description provided for @emailCannotChange.
  ///
  /// In th, this message translates to:
  /// **'อีเมลใช้สำหรับเข้าสู่ระบบ แก้ไขไม่ได้'**
  String get emailCannotChange;

  /// No description provided for @difficultyEasy.
  ///
  /// In th, this message translates to:
  /// **'ง่าย'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In th, this message translates to:
  /// **'ปานกลาง'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In th, this message translates to:
  /// **'ยาก'**
  String get difficultyHard;

  /// No description provided for @priceFree.
  ///
  /// In th, this message translates to:
  /// **'ฟรี'**
  String get priceFree;

  /// No description provided for @mockIapDisabled.
  ///
  /// In th, this message translates to:
  /// **'โหมดซื้อจำลองถูกปิดอยู่ กรุณาเชื่อม Google Play Billing'**
  String get mockIapDisabled;

  /// No description provided for @mockPaymentCancelled.
  ///
  /// In th, this message translates to:
  /// **'จำลองการยกเลิกการชำระเงินแล้ว'**
  String get mockPaymentCancelled;

  /// No description provided for @mockPaymentFailed.
  ///
  /// In th, this message translates to:
  /// **'จำลองการชำระเงินไม่สำเร็จ'**
  String get mockPaymentFailed;

  /// No description provided for @mockBillingTitle.
  ///
  /// In th, this message translates to:
  /// **'Google Play Billing — โหมดจำลอง'**
  String get mockBillingTitle;

  /// No description provided for @mockBillingSubtitle.
  ///
  /// In th, this message translates to:
  /// **'เลือกผลลัพธ์ที่ต้องการทดสอบ ระบบนี้ไม่ตัดเงินจริง'**
  String get mockBillingSubtitle;

  /// No description provided for @mockPaySuccess.
  ///
  /// In th, this message translates to:
  /// **'จำลองชำระสำเร็จ'**
  String get mockPaySuccess;

  /// No description provided for @mockPayFail.
  ///
  /// In th, this message translates to:
  /// **'จำลองชำระไม่สำเร็จ'**
  String get mockPayFail;

  /// No description provided for @mockUserCancel.
  ///
  /// In th, this message translates to:
  /// **'จำลองผู้ใช้ยกเลิก'**
  String get mockUserCancel;

  /// No description provided for @clearCartTitle.
  ///
  /// In th, this message translates to:
  /// **'ล้างตะกร้า?'**
  String get clearCartTitle;

  /// No description provided for @clearCartMessage.
  ///
  /// In th, this message translates to:
  /// **'สูตรทั้งหมดในตะกร้าจะถูกเอาออก'**
  String get clearCartMessage;

  /// No description provided for @clear.
  ///
  /// In th, this message translates to:
  /// **'ล้าง'**
  String get clear;

  /// No description provided for @cartTitle.
  ///
  /// In th, this message translates to:
  /// **'ตะกร้า'**
  String get cartTitle;

  /// No description provided for @clearCartTooltip.
  ///
  /// In th, this message translates to:
  /// **'ล้างตะกร้า'**
  String get clearCartTooltip;

  /// No description provided for @cartLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดตะกร้าไม่สำเร็จ'**
  String get cartLoadFailed;

  /// No description provided for @selectAll.
  ///
  /// In th, this message translates to:
  /// **'เลือกทั้งหมด'**
  String get selectAll;

  /// No description provided for @selectedOfTotal.
  ///
  /// In th, this message translates to:
  /// **'เลือก {selected} จาก {total} รายการ'**
  String selectedOfTotal(int selected, int total);

  /// No description provided for @cartEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ตะกร้าว่างเปล่า'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'สูตรที่คุณเพิ่มจะแสดงที่นี่'**
  String get cartEmptyMessage;

  /// No description provided for @browseRecipes.
  ///
  /// In th, this message translates to:
  /// **'ดูสูตรอาหาร'**
  String get browseRecipes;

  /// No description provided for @selectItemForCheckout.
  ///
  /// In th, this message translates to:
  /// **'เลือก {title} เพื่อชำระเงิน'**
  String selectItemForCheckout(String title);

  /// No description provided for @remove.
  ///
  /// In th, this message translates to:
  /// **'เอาออก'**
  String get remove;

  /// No description provided for @itemCount.
  ///
  /// In th, this message translates to:
  /// **'{count} รายการ'**
  String itemCount(int count);

  /// No description provided for @checkout.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงิน'**
  String get checkout;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินไม่สำเร็จ'**
  String get paymentFailedTitle;

  /// No description provided for @purchaseIncomplete.
  ///
  /// In th, this message translates to:
  /// **'ยังซื้อสูตรไม่ครบ'**
  String get purchaseIncomplete;

  /// No description provided for @purchasePartialMessage.
  ///
  /// In th, this message translates to:
  /// **'ก่อนเกิดข้อผิดพลาด ซื้อสำเร็จแล้ว {count} สูตร สูตรที่เหลือยังอยู่ในตะกร้า'**
  String purchasePartialMessage(int count);

  /// No description provided for @retry.
  ///
  /// In th, this message translates to:
  /// **'ลองใหม่'**
  String get retry;

  /// No description provided for @backToCart.
  ///
  /// In th, this message translates to:
  /// **'กลับไปตะกร้า'**
  String get backToCart;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินสำเร็จ'**
  String get paymentSuccessTitle;

  /// No description provided for @purchaseSuccess.
  ///
  /// In th, this message translates to:
  /// **'ซื้อสูตรสำเร็จ!'**
  String get purchaseSuccess;

  /// No description provided for @purchaseUnlocked.
  ///
  /// In th, this message translates to:
  /// **'เปิดสิทธิ์เข้าถึง {count} สูตรแล้ว'**
  String purchaseUnlocked(int count);

  /// No description provided for @mockPaymentNotice.
  ///
  /// In th, this message translates to:
  /// **'รายการนี้เป็นการชำระเงินจำลอง ไม่มีการตัดเงินจริง'**
  String get mockPaymentNotice;

  /// No description provided for @viewPurchasedRecipes.
  ///
  /// In th, this message translates to:
  /// **'ดูสูตรที่ซื้อแล้ว'**
  String get viewPurchasedRecipes;

  /// No description provided for @backToHome.
  ///
  /// In th, this message translates to:
  /// **'กลับหน้าหลัก'**
  String get backToHome;

  /// No description provided for @checkoutNow.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินเลย'**
  String get checkoutNow;

  /// No description provided for @buyNow.
  ///
  /// In th, this message translates to:
  /// **'ซื้อเลย'**
  String get buyNow;

  /// No description provided for @recipeNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลเมนูนี้'**
  String get recipeNotFound;

  /// No description provided for @startCooking.
  ///
  /// In th, this message translates to:
  /// **'เริ่มทำอาหาร'**
  String get startCooking;

  /// No description provided for @deleteRecipe.
  ///
  /// In th, this message translates to:
  /// **'ลบสูตรอาหาร'**
  String get deleteRecipe;

  /// No description provided for @deleteRecipeConfirm.
  ///
  /// In th, this message translates to:
  /// **'คุณต้องการลบสูตรอาหารนี้ใช่หรือไม่?\nข้อมูลที่เกี่ยวข้องทั้งหมดจะถูกลบด้วย'**
  String get deleteRecipeConfirm;

  /// No description provided for @delete.
  ///
  /// In th, this message translates to:
  /// **'ลบ'**
  String get delete;

  /// No description provided for @changesSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการแก้ไขแล้ว'**
  String get changesSaved;

  /// No description provided for @goBack.
  ///
  /// In th, this message translates to:
  /// **'ย้อนกลับ'**
  String get goBack;

  /// No description provided for @description.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด'**
  String get description;

  /// No description provided for @edit.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข'**
  String get edit;

  /// No description provided for @minutesShort.
  ///
  /// In th, this message translates to:
  /// **'{count} น.'**
  String minutesShort(int count);

  /// No description provided for @infoPrep.
  ///
  /// In th, this message translates to:
  /// **'เตรียม'**
  String get infoPrep;

  /// No description provided for @infoCook.
  ///
  /// In th, this message translates to:
  /// **'ปรุง'**
  String get infoCook;

  /// No description provided for @infoServings.
  ///
  /// In th, this message translates to:
  /// **'เสิร์ฟ'**
  String get infoServings;

  /// No description provided for @infoLevel.
  ///
  /// In th, this message translates to:
  /// **'ระดับ'**
  String get infoLevel;

  /// No description provided for @event.
  ///
  /// In th, this message translates to:
  /// **'กิจกรรม'**
  String get event;

  /// No description provided for @details.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด'**
  String get details;

  /// No description provided for @eventNoDetails.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายละเอียดของกิจกรรมนี้'**
  String get eventNoDetails;

  /// No description provided for @periodStarts.
  ///
  /// In th, this message translates to:
  /// **'เริ่ม {date}'**
  String periodStarts(String date);

  /// No description provided for @periodEnds.
  ///
  /// In th, this message translates to:
  /// **'ถึง {date}'**
  String periodEnds(String date);

  /// No description provided for @starLabel1.
  ///
  /// In th, this message translates to:
  /// **'แย่มาก'**
  String get starLabel1;

  /// No description provided for @starLabel2.
  ///
  /// In th, this message translates to:
  /// **'พอใช้'**
  String get starLabel2;

  /// No description provided for @starLabel3.
  ///
  /// In th, this message translates to:
  /// **'ดี'**
  String get starLabel3;

  /// No description provided for @starLabel4.
  ///
  /// In th, this message translates to:
  /// **'ดีมาก'**
  String get starLabel4;

  /// No description provided for @starLabel5.
  ///
  /// In th, this message translates to:
  /// **'ยอดเยี่ยม!'**
  String get starLabel5;

  /// No description provided for @rateThisRecipe.
  ///
  /// In th, this message translates to:
  /// **'ให้คะแนนสูตรนี้'**
  String get rateThisRecipe;

  /// No description provided for @rateDialogSubtitle.
  ///
  /// In th, this message translates to:
  /// **'ความคิดเห็นของคุณช่วยให้เราพัฒนาสูตรอาหารให้ดียิ่งขึ้น'**
  String get rateDialogSubtitle;

  /// No description provided for @tapStarsToRate.
  ///
  /// In th, this message translates to:
  /// **'แตะดาวเพื่อให้คะแนน'**
  String get tapStarsToRate;

  /// No description provided for @whatDidYouLike.
  ///
  /// In th, this message translates to:
  /// **'ชอบอะไรในสูตรนี้'**
  String get whatDidYouLike;

  /// No description provided for @tellMore.
  ///
  /// In th, this message translates to:
  /// **'เล่าเพิ่มเติม '**
  String get tellMore;

  /// No description provided for @optional.
  ///
  /// In th, this message translates to:
  /// **'(ไม่บังคับ)'**
  String get optional;

  /// No description provided for @reviewCommentHint.
  ///
  /// In th, this message translates to:
  /// **'เล่าว่าทำสูตรนี้แล้วเป็นยังไงบ้าง'**
  String get reviewCommentHint;

  /// No description provided for @submitRating.
  ///
  /// In th, this message translates to:
  /// **'ส่งคะแนน'**
  String get submitRating;

  /// No description provided for @updateRating.
  ///
  /// In th, this message translates to:
  /// **'อัปเดตคะแนน'**
  String get updateRating;

  /// No description provided for @thanksForRating.
  ///
  /// In th, this message translates to:
  /// **'ขอบคุณสำหรับคะแนน!'**
  String get thanksForRating;

  /// No description provided for @ratingAddedMessage.
  ///
  /// In th, this message translates to:
  /// **'รีวิวของคุณถูกเพิ่มในหน้าสูตรแล้ว\nแก้ไขได้ทุกเมื่อจากปุ่ม \"แก้ไขคะแนน\"'**
  String get ratingAddedMessage;

  /// No description provided for @backToRecipe.
  ///
  /// In th, this message translates to:
  /// **'กลับไปที่สูตร'**
  String get backToRecipe;

  /// No description provided for @close.
  ///
  /// In th, this message translates to:
  /// **'ปิด'**
  String get close;

  /// No description provided for @ratingLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดคะแนนไม่สำเร็จ'**
  String get ratingLoadFailed;

  /// No description provided for @rate.
  ///
  /// In th, this message translates to:
  /// **'ให้คะแนน'**
  String get rate;

  /// No description provided for @editRating.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขคะแนน'**
  String get editRating;

  /// No description provided for @latestReviews.
  ///
  /// In th, this message translates to:
  /// **'รีวิวล่าสุด'**
  String get latestReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรีวิว'**
  String get noReviewsYet;

  /// No description provided for @ratingsAndReviews.
  ///
  /// In th, this message translates to:
  /// **'คะแนนและรีวิว'**
  String get ratingsAndReviews;

  /// No description provided for @noRatingsYet.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีคะแนน'**
  String get noRatingsYet;

  /// No description provided for @fromReviewCount.
  ///
  /// In th, this message translates to:
  /// **'จาก {count} รีวิว'**
  String fromReviewCount(int count);

  /// No description provided for @starCount.
  ///
  /// In th, this message translates to:
  /// **'{count} ดาว'**
  String starCount(int count);

  /// No description provided for @allReviews.
  ///
  /// In th, this message translates to:
  /// **'รีวิวทั้งหมด'**
  String get allReviews;

  /// No description provided for @averageRating.
  ///
  /// In th, this message translates to:
  /// **'คะแนนเฉลี่ย'**
  String get averageRating;

  /// No description provided for @tagTasty.
  ///
  /// In th, this message translates to:
  /// **'รสชาติดี'**
  String get tagTasty;

  /// No description provided for @tagEasy.
  ///
  /// In th, this message translates to:
  /// **'ทำง่าย'**
  String get tagEasy;

  /// No description provided for @tagSpicyRight.
  ///
  /// In th, this message translates to:
  /// **'เผ็ดกำลังดี'**
  String get tagSpicyRight;

  /// No description provided for @tagEasyIngredients.
  ///
  /// In th, this message translates to:
  /// **'วัตถุดิบหาง่าย'**
  String get tagEasyIngredients;

  /// No description provided for @commentMore.
  ///
  /// In th, this message translates to:
  /// **'...เพิ่มเติม'**
  String get commentMore;

  /// No description provided for @commentLess.
  ///
  /// In th, this message translates to:
  /// **'  ย่อ'**
  String get commentLess;

  /// No description provided for @actionFailed.
  ///
  /// In th, this message translates to:
  /// **'ทำรายการไม่สำเร็จ'**
  String get actionFailed;

  /// No description provided for @buyToComment.
  ///
  /// In th, this message translates to:
  /// **'ซื้อสูตรนี้ก่อนจึงจะแสดงความคิดเห็นได้'**
  String get buyToComment;

  /// No description provided for @comments.
  ///
  /// In th, this message translates to:
  /// **'ความคิดเห็น'**
  String get comments;

  /// No description provided for @commentsLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดความคิดเห็นไม่สำเร็จ'**
  String get commentsLoadFailed;

  /// No description provided for @noCommentsYet.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีความคิดเห็น'**
  String get noCommentsYet;

  /// No description provided for @viewMoreComments.
  ///
  /// In th, this message translates to:
  /// **'ดูความคิดเห็นเพิ่มเติม'**
  String get viewMoreComments;

  /// No description provided for @loadMoreCommentsAgain.
  ///
  /// In th, this message translates to:
  /// **'โหลดความคิดเห็นเพิ่มอีกครั้ง'**
  String get loadMoreCommentsAgain;

  /// No description provided for @deleteComment.
  ///
  /// In th, this message translates to:
  /// **'ลบความคิดเห็น'**
  String get deleteComment;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In th, this message translates to:
  /// **'ต้องการลบความคิดเห็นนี้ใช่ไหม'**
  String get deleteCommentConfirm;

  /// No description provided for @editComment.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขความคิดเห็น'**
  String get editComment;

  /// No description provided for @writeCommentHint.
  ///
  /// In th, this message translates to:
  /// **'เขียนความคิดเห็น'**
  String get writeCommentHint;

  /// No description provided for @addCommentHint.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มความคิดเห็น...'**
  String get addCommentHint;

  /// No description provided for @sendComment.
  ///
  /// In th, this message translates to:
  /// **'ส่งความคิดเห็น'**
  String get sendComment;

  /// No description provided for @manageComment.
  ///
  /// In th, this message translates to:
  /// **'จัดการความคิดเห็น'**
  String get manageComment;

  /// No description provided for @askAiAboutRecipe.
  ///
  /// In th, this message translates to:
  /// **'ถาม AI เกี่ยวกับสูตรนี้'**
  String get askAiAboutRecipe;

  /// No description provided for @pickFromGallery.
  ///
  /// In th, this message translates to:
  /// **'เลือกจากคลังรูป'**
  String get pickFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In th, this message translates to:
  /// **'ถ่ายรูป'**
  String get takePhoto;

  /// No description provided for @newChat.
  ///
  /// In th, this message translates to:
  /// **'เริ่มแชทใหม่'**
  String get newChat;

  /// No description provided for @chatEmptyHint.
  ///
  /// In th, this message translates to:
  /// **'ถามอะไรก็ได้เกี่ยวกับสูตรนี้\nเช่น \"ใช้อะไรแทนน้ำปลาได้บ้าง\"'**
  String get chatEmptyHint;

  /// No description provided for @aiTyping.
  ///
  /// In th, this message translates to:
  /// **'AI กำลังพิมพ์...'**
  String get aiTyping;

  /// No description provided for @attachImage.
  ///
  /// In th, this message translates to:
  /// **'แนบรูป'**
  String get attachImage;

  /// No description provided for @chatInputHint.
  ///
  /// In th, this message translates to:
  /// **'พิมพ์คำถาม...'**
  String get chatInputHint;

  /// No description provided for @chatImageHint.
  ///
  /// In th, this message translates to:
  /// **'ถามเกี่ยวกับรูปนี้ (ไม่พิมพ์ก็ได้)'**
  String get chatImageHint;

  /// No description provided for @openEditorFailed.
  ///
  /// In th, this message translates to:
  /// **'เปิดหน้าแก้ไขสูตรไม่ได้: {error}'**
  String openEditorFailed(String error);

  /// No description provided for @collectionEmptyMyRecipes.
  ///
  /// In th, this message translates to:
  /// **'คุณยังไม่ได้เผยแพร่สูตรเลย'**
  String get collectionEmptyMyRecipes;

  /// No description provided for @collectionEmptyPurchased.
  ///
  /// In th, this message translates to:
  /// **'คุณยังไม่ได้ซื้อสูตรเลย'**
  String get collectionEmptyPurchased;

  /// No description provided for @collectionEmptyFavorites.
  ///
  /// In th, this message translates to:
  /// **'สูตรที่คุณบันทึกไว้จะแสดงที่นี่'**
  String get collectionEmptyFavorites;

  /// No description provided for @collectionEmptyDrafts.
  ///
  /// In th, this message translates to:
  /// **'คุณไม่มีสูตรที่ยังทำไม่เสร็จ'**
  String get collectionEmptyDrafts;

  /// No description provided for @pickCoverBeforePublish.
  ///
  /// In th, this message translates to:
  /// **'เลือกรูปตัวอย่างอาหารก่อนเผยแพร่สูตร'**
  String get pickCoverBeforePublish;

  /// No description provided for @pickAtLeastOneCategory.
  ///
  /// In th, this message translates to:
  /// **'เลือกหมวดหมู่อย่างน้อย 1 หมวด'**
  String get pickAtLeastOneCategory;

  /// No description provided for @addStepsBeforePublish.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มขั้นตอนการทำอาหารก่อนเผยแพร่สูตร'**
  String get addStepsBeforePublish;

  /// No description provided for @completeAllSteps.
  ///
  /// In th, this message translates to:
  /// **'กรอกชื่อและรายละเอียดให้ครบทุกขั้นตอน'**
  String get completeAllSteps;

  /// No description provided for @defaultSectionTitle.
  ///
  /// In th, this message translates to:
  /// **'หัวข้อชุดขั้นตอน {number}'**
  String defaultSectionTitle(int number);

  /// No description provided for @draftRecipeTitle.
  ///
  /// In th, this message translates to:
  /// **'สูตรอาหารฉบับร่าง'**
  String get draftRecipeTitle;

  /// No description provided for @draftSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกฉบับร่างแล้ว'**
  String get draftSaved;

  /// No description provided for @saveDraftBeforeLeaving.
  ///
  /// In th, this message translates to:
  /// **'บันทึกฉบับร่างก่อนออกไหม?'**
  String get saveDraftBeforeLeaving;

  /// No description provided for @saveDraftBeforeLeavingMessage.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลที่กรอกไว้จะถูกเก็บในฉบับร่างบนหน้าโปรไฟล์'**
  String get saveDraftBeforeLeavingMessage;

  /// No description provided for @stay.
  ///
  /// In th, this message translates to:
  /// **'อยู่ต่อ'**
  String get stay;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In th, this message translates to:
  /// **'ออกโดยไม่บันทึก'**
  String get leaveWithoutSaving;

  /// No description provided for @saveDraft.
  ///
  /// In th, this message translates to:
  /// **'บันทึกฉบับร่าง'**
  String get saveDraft;

  /// No description provided for @discardEditsTitle.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิกการแก้ไขไหม?'**
  String get discardEditsTitle;

  /// No description provided for @discardEditsMessage.
  ///
  /// In th, this message translates to:
  /// **'การแก้ไขที่ยังไม่ได้บันทึกจะหายไป'**
  String get discardEditsMessage;

  /// No description provided for @keepEditing.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขต่อ'**
  String get keepEditing;

  /// No description provided for @fileSelectedWillUpload.
  ///
  /// In th, this message translates to:
  /// **'เลือกไฟล์แล้ว จะอัปโหลดเมื่อเผยแพร่สูตร'**
  String get fileSelectedWillUpload;

  /// No description provided for @cannotOpenSelectedFile.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถเปิดไฟล์ที่เลือกได้'**
  String get cannotOpenSelectedFile;

  /// No description provided for @fileTooLarge.
  ///
  /// In th, this message translates to:
  /// **'ไฟล์ต้องมีขนาดไม่เกิน {maxMb} MB'**
  String fileTooLarge(int maxMb);

  /// No description provided for @imageTypesOnly.
  ///
  /// In th, this message translates to:
  /// **'รองรับไฟล์ JPG, PNG, WEBP หรือ GIF เท่านั้น'**
  String get imageTypesOnly;

  /// No description provided for @videoTypesOnly.
  ///
  /// In th, this message translates to:
  /// **'รองรับไฟล์ MP4, WEBM หรือ MOV เท่านั้น'**
  String get videoTypesOnly;

  /// No description provided for @fieldRequired.
  ///
  /// In th, this message translates to:
  /// **'กรอก{field}'**
  String fieldRequired(String field);

  /// No description provided for @fieldMustBeNonNegative.
  ///
  /// In th, this message translates to:
  /// **'{field}ต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป'**
  String fieldMustBeNonNegative(String field);

  /// No description provided for @fieldMustBeWholeNumber.
  ///
  /// In th, this message translates to:
  /// **'{field}ต้องเป็นจำนวนเต็มตั้งแต่ {minimum} ขึ้นไป'**
  String fieldMustBeWholeNumber(String field, int minimum);

  /// No description provided for @editRecipe.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขสูตรอาหาร'**
  String get editRecipe;

  /// No description provided for @createRecipe.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตรอาหาร'**
  String get createRecipe;

  /// No description provided for @uploadingFiles.
  ///
  /// In th, this message translates to:
  /// **'กำลังอัปโหลดไฟล์...'**
  String get uploadingFiles;

  /// No description provided for @publishing.
  ///
  /// In th, this message translates to:
  /// **'กำลังเผยแพร่...'**
  String get publishing;

  /// No description provided for @saveChanges.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการแก้ไข'**
  String get saveChanges;

  /// No description provided for @publishRecipe.
  ///
  /// In th, this message translates to:
  /// **'เผยแพร่สูตรอาหาร'**
  String get publishRecipe;

  /// No description provided for @uploading.
  ///
  /// In th, this message translates to:
  /// **'กำลังอัปโหลด...'**
  String get uploading;

  /// No description provided for @publish.
  ///
  /// In th, this message translates to:
  /// **'เผยแพร่'**
  String get publish;

  /// No description provided for @yourRecipe.
  ///
  /// In th, this message translates to:
  /// **'สูตรของคุณ'**
  String get yourRecipe;

  /// No description provided for @yourRecipeSubtitle.
  ///
  /// In th, this message translates to:
  /// **'ชื่อเมนูและเรื่องราวสั้น ๆ'**
  String get yourRecipeSubtitle;

  /// No description provided for @thaiName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อภาษาไทย'**
  String get thaiName;

  /// No description provided for @thaiNameHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น ผัดกะเพราไก่'**
  String get thaiNameHint;

  /// No description provided for @recipeNameField.
  ///
  /// In th, this message translates to:
  /// **'ชื่อสูตรอาหาร'**
  String get recipeNameField;

  /// No description provided for @englishName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อภาษาอังกฤษ'**
  String get englishName;

  /// No description provided for @descriptionField.
  ///
  /// In th, this message translates to:
  /// **'คำอธิบาย'**
  String get descriptionField;

  /// No description provided for @descriptionHint.
  ///
  /// In th, this message translates to:
  /// **'เล่าจุดเด่นหรือรสชาติของเมนูนี้'**
  String get descriptionHint;

  /// No description provided for @categories.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get categories;

  /// No description provided for @categoriesPickMany.
  ///
  /// In th, this message translates to:
  /// **'เลือกได้มากกว่า 1 หมวด'**
  String get categoriesPickMany;

  /// No description provided for @categoriesSelected.
  ///
  /// In th, this message translates to:
  /// **'เลือกแล้ว {count} หมวด'**
  String categoriesSelected(int count);

  /// No description provided for @noCategories.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีหมวดหมู่ให้เลือก'**
  String get noCategories;

  /// No description provided for @searchCategoriesHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาหมวดหมู่...'**
  String get searchCategoriesHint;

  /// No description provided for @coverPhoto.
  ///
  /// In th, this message translates to:
  /// **'รูปตัวอย่างอาหาร'**
  String get coverPhoto;

  /// No description provided for @coverPhotoSubtitle.
  ///
  /// In th, this message translates to:
  /// **'รูปหน้าปกที่ทุกคนจะเห็นก่อน'**
  String get coverPhotoSubtitle;

  /// No description provided for @currentImage.
  ///
  /// In th, this message translates to:
  /// **'รูปเดิม'**
  String get currentImage;

  /// No description provided for @showImageInCommunity.
  ///
  /// In th, this message translates to:
  /// **'แสดงรูปในชุมชน'**
  String get showImageInCommunity;

  /// No description provided for @showImageInCommunityHint.
  ///
  /// In th, this message translates to:
  /// **'โชว์รูปเล็กใต้โพสต์ในหน้าคอมมูนิตี้'**
  String get showImageInCommunityHint;

  /// No description provided for @chooseImage.
  ///
  /// In th, this message translates to:
  /// **'เลือกรูปภาพ'**
  String get chooseImage;

  /// No description provided for @imageRequirements.
  ///
  /// In th, this message translates to:
  /// **'JPG, PNG, WEBP หรือ GIF ไม่เกิน 10 MB'**
  String get imageRequirements;

  /// No description provided for @changeImage.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรูปภาพ'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In th, this message translates to:
  /// **'ลบรูปภาพ'**
  String get removeImage;

  /// No description provided for @recipeDetails.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียดสูตร'**
  String get recipeDetails;

  /// No description provided for @recipeDetailsSubtitle.
  ///
  /// In th, this message translates to:
  /// **'เวลา จำนวนที่เสิร์ฟ และความยาก'**
  String get recipeDetailsSubtitle;

  /// No description provided for @price.
  ///
  /// In th, this message translates to:
  /// **'ราคา'**
  String get price;

  /// No description provided for @baht.
  ///
  /// In th, this message translates to:
  /// **'บาท'**
  String get baht;

  /// No description provided for @priceRequired.
  ///
  /// In th, this message translates to:
  /// **'กรอกราคา'**
  String get priceRequired;

  /// No description provided for @prepLabel.
  ///
  /// In th, this message translates to:
  /// **'เตรียม'**
  String get prepLabel;

  /// No description provided for @minutesUnit.
  ///
  /// In th, this message translates to:
  /// **'นาที'**
  String get minutesUnit;

  /// No description provided for @prepTimeField.
  ///
  /// In th, this message translates to:
  /// **'เวลาเตรียม'**
  String get prepTimeField;

  /// No description provided for @cookLabel.
  ///
  /// In th, this message translates to:
  /// **'ปรุง'**
  String get cookLabel;

  /// No description provided for @cookTimeField.
  ///
  /// In th, this message translates to:
  /// **'เวลาปรุง'**
  String get cookTimeField;

  /// No description provided for @servings.
  ///
  /// In th, this message translates to:
  /// **'จำนวนที่รับประทาน'**
  String get servings;

  /// No description provided for @servingsUnit.
  ///
  /// In th, this message translates to:
  /// **'ที่'**
  String get servingsUnit;

  /// No description provided for @difficulty.
  ///
  /// In th, this message translates to:
  /// **'ระดับความยาก'**
  String get difficulty;

  /// No description provided for @difficultyRequired.
  ///
  /// In th, this message translates to:
  /// **'เลือกระดับความยาก'**
  String get difficultyRequired;

  /// No description provided for @cookingSteps.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอนการทำอาหาร'**
  String get cookingSteps;

  /// No description provided for @tapToEditSteps.
  ///
  /// In th, this message translates to:
  /// **'แตะเพื่อแก้ไขหัวข้อและขั้นตอน'**
  String get tapToEditSteps;

  /// No description provided for @noStepGroupsYet.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้เพิ่มหัวข้อขั้นตอน'**
  String get noStepGroupsYet;

  /// No description provided for @statGroups.
  ///
  /// In th, this message translates to:
  /// **'ชุด'**
  String get statGroups;

  /// No description provided for @statSteps.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอน'**
  String get statSteps;

  /// No description provided for @editStepGroups.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขหัวข้อขั้นตอน'**
  String get editStepGroups;

  /// No description provided for @addStepGroups.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มหัวข้อขั้นตอน'**
  String get addStepGroups;

  /// No description provided for @recipeType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทสูตร'**
  String get recipeType;

  /// No description provided for @recipeTypeSubtitle.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนได้จนกว่าจะเผยแพร่'**
  String get recipeTypeSubtitle;

  /// No description provided for @recipeTypeOfficial.
  ///
  /// In th, this message translates to:
  /// **'Official (ขาย)'**
  String get recipeTypeOfficial;

  /// No description provided for @recipeTypeCommunity.
  ///
  /// In th, this message translates to:
  /// **'Community (ฟรี)'**
  String get recipeTypeCommunity;

  /// No description provided for @mediaTypesOnly.
  ///
  /// In th, this message translates to:
  /// **'รองรับไฟล์รูปภาพหรือวิดีโอเท่านั้น'**
  String get mediaTypesOnly;

  /// No description provided for @minutesNonNegative.
  ///
  /// In th, this message translates to:
  /// **'ใส่เวลาเป็นจำนวนนาทีตั้งแต่ 0'**
  String get minutesNonNegative;

  /// No description provided for @backAutoSave.
  ///
  /// In th, this message translates to:
  /// **'กลับ (บันทึกอัตโนมัติ)'**
  String get backAutoSave;

  /// No description provided for @addStep.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มขั้นตอน'**
  String get addStep;

  /// No description provided for @stepNumber.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอนที่ {number}'**
  String stepNumber(int number);

  /// No description provided for @deleteStep.
  ///
  /// In th, this message translates to:
  /// **'ลบขั้นตอน'**
  String get deleteStep;

  /// No description provided for @collapseDetails.
  ///
  /// In th, this message translates to:
  /// **'พับรายละเอียด'**
  String get collapseDetails;

  /// No description provided for @expandDetails.
  ///
  /// In th, this message translates to:
  /// **'ขยายรายละเอียด'**
  String get expandDetails;

  /// No description provided for @subStepTitle.
  ///
  /// In th, this message translates to:
  /// **'ชื่อขั้นตอนย่อย'**
  String get subStepTitle;

  /// No description provided for @subStepTitleHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น เตรียมหมูและเครื่องปรุง'**
  String get subStepTitleHint;

  /// No description provided for @instructions.
  ///
  /// In th, this message translates to:
  /// **'วิธีทำ'**
  String get instructions;

  /// No description provided for @instructionsHint.
  ///
  /// In th, this message translates to:
  /// **'อธิบายสิ่งที่ต้องทำในขั้นตอนนี้'**
  String get instructionsHint;

  /// No description provided for @stepType.
  ///
  /// In th, this message translates to:
  /// **'ชนิดขั้นตอน'**
  String get stepType;

  /// No description provided for @stepTypeTip.
  ///
  /// In th, this message translates to:
  /// **'เคล็ดลับ'**
  String get stepTypeTip;

  /// No description provided for @stepTypeWarning.
  ///
  /// In th, this message translates to:
  /// **'ข้อควรระวัง'**
  String get stepTypeWarning;

  /// No description provided for @stepTypeImage.
  ///
  /// In th, this message translates to:
  /// **'รูปภาพ'**
  String get stepTypeImage;

  /// No description provided for @stepTypeVideo.
  ///
  /// In th, this message translates to:
  /// **'คลิปวิดีโอ'**
  String get stepTypeVideo;

  /// No description provided for @chooseMediaFile.
  ///
  /// In th, this message translates to:
  /// **'เลือกไฟล์รูปภาพหรือวิดีโอ'**
  String get chooseMediaFile;

  /// No description provided for @timeLabel.
  ///
  /// In th, this message translates to:
  /// **'เวลา'**
  String get timeLabel;

  /// No description provided for @useExistingVideo.
  ///
  /// In th, this message translates to:
  /// **'ใช้คลิปวิดีโอเดิม'**
  String get useExistingVideo;

  /// No description provided for @changeFile.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนไฟล์'**
  String get changeFile;

  /// No description provided for @chooseImageOrVideo.
  ///
  /// In th, this message translates to:
  /// **'เลือกรูปภาพหรือวิดีโอ'**
  String get chooseImageOrVideo;

  /// No description provided for @mediaRequirements.
  ///
  /// In th, this message translates to:
  /// **'รูปไม่เกิน 10 MB · วิดีโอไม่เกิน 100 MB'**
  String get mediaRequirements;

  /// No description provided for @enterGroupTitleFirst.
  ///
  /// In th, this message translates to:
  /// **'กรอกหัวข้อขั้นตอนก่อนเพิ่มขั้นตอน'**
  String get enterGroupTitleFirst;

  /// No description provided for @stepGroupTitle.
  ///
  /// In th, this message translates to:
  /// **'หัวข้อขั้นตอน'**
  String get stepGroupTitle;

  /// No description provided for @stepGroupsHelp.
  ///
  /// In th, this message translates to:
  /// **'แบ่งขั้นตอนเป็นชุด เช่น \"เตรียมวัตถุดิบ\" \"ปรุง\" \"จัดเสิร์ฟ\" แล้วแตะการ์ดเพื่อเพิ่มขั้นตอนย่อย กดย้อนกลับได้เลย ระบบบันทึกให้อัตโนมัติ'**
  String get stepGroupsHelp;

  /// No description provided for @noStepGroupsTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีหัวข้อขั้นตอน'**
  String get noStepGroupsTitle;

  /// No description provided for @noStepGroupsHint.
  ///
  /// In th, this message translates to:
  /// **'เริ่มจากเพิ่มหัวข้อชุดแรกด้านล่าง'**
  String get noStepGroupsHint;

  /// No description provided for @cookingDone.
  ///
  /// In th, this message translates to:
  /// **'ทำอาหารเสร็จแล้ว!'**
  String get cookingDone;

  /// No description provided for @cookingDoneMessage.
  ///
  /// In th, this message translates to:
  /// **'คุณทำ {recipe} ครบทุกขั้นตอนแล้ว'**
  String cookingDoneMessage(String recipe);

  /// No description provided for @backToRecipePage.
  ///
  /// In th, this message translates to:
  /// **'กลับไปหน้าสูตรอาหาร'**
  String get backToRecipePage;

  /// No description provided for @stepDone.
  ///
  /// In th, this message translates to:
  /// **'เสร็จแล้ว'**
  String get stepDone;

  /// No description provided for @stepOfTotal.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอน {current} จาก {total}'**
  String stepOfTotal(int current, int total);

  /// No description provided for @stepTypeVideoShort.
  ///
  /// In th, this message translates to:
  /// **'วิดีโอ'**
  String get stepTypeVideoShort;

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In th, this message translates to:
  /// **'{minutes} นาที {seconds} วินาที'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In th, this message translates to:
  /// **'{minutes} นาที'**
  String durationMinutes(int minutes);

  /// No description provided for @durationSeconds.
  ///
  /// In th, this message translates to:
  /// **'{seconds} วินาที'**
  String durationSeconds(int seconds);

  /// No description provided for @stepHasNoVideo.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอนนี้ยังไม่มีวิดีโอ'**
  String get stepHasNoVideo;

  /// No description provided for @previousStep.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอนก่อนหน้า'**
  String get previousStep;

  /// No description provided for @finishCooking.
  ///
  /// In th, this message translates to:
  /// **'ทำอาหารเสร็จแล้ว'**
  String get finishCooking;

  /// No description provided for @finishStep.
  ///
  /// In th, this message translates to:
  /// **'เสร็จขั้นตอนนี้'**
  String get finishStep;

  /// No description provided for @cookingNow.
  ///
  /// In th, this message translates to:
  /// **'กำลังทำอาหาร'**
  String get cookingNow;

  /// No description provided for @stepProgress.
  ///
  /// In th, this message translates to:
  /// **'{current} / {total} ขั้นตอน'**
  String stepProgress(int current, int total);

  /// No description provided for @recipeHasNoSteps.
  ///
  /// In th, this message translates to:
  /// **'สูตรนี้ยังไม่มีขั้นตอนการทำ'**
  String get recipeHasNoSteps;

  /// No description provided for @loadingVideo.
  ///
  /// In th, this message translates to:
  /// **'กำลังโหลดวิดีโอ...'**
  String get loadingVideo;

  /// No description provided for @videoPlayFailedDetails.
  ///
  /// In th, this message translates to:
  /// **'เล่นวิดีโอไม่ได้\n{details}'**
  String videoPlayFailedDetails(String details);

  /// No description provided for @videoPlayFailed.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถเล่นวิดีโอนี้ได้'**
  String get videoPlayFailed;

  /// No description provided for @rewind10.
  ///
  /// In th, this message translates to:
  /// **'ย้อนกลับ 10 วินาที'**
  String get rewind10;

  /// No description provided for @pause.
  ///
  /// In th, this message translates to:
  /// **'หยุดชั่วคราว'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In th, this message translates to:
  /// **'เล่น'**
  String get play;

  /// No description provided for @forward10.
  ///
  /// In th, this message translates to:
  /// **'เดินหน้า 10 วินาที'**
  String get forward10;

  /// No description provided for @unmute.
  ///
  /// In th, this message translates to:
  /// **'เปิดเสียง'**
  String get unmute;

  /// No description provided for @adjustVolume.
  ///
  /// In th, this message translates to:
  /// **'ปรับเสียง'**
  String get adjustVolume;

  /// No description provided for @mute.
  ///
  /// In th, this message translates to:
  /// **'ปิดเสียง'**
  String get mute;

  /// No description provided for @playbackSpeed.
  ///
  /// In th, this message translates to:
  /// **'ความเร็วการเล่น'**
  String get playbackSpeed;

  /// No description provided for @rotateScreen.
  ///
  /// In th, this message translates to:
  /// **'หมุนหน้าจอ'**
  String get rotateScreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In th, this message translates to:
  /// **'ออกจากเต็มจอ'**
  String get exitFullscreen;

  /// No description provided for @fullscreen.
  ///
  /// In th, this message translates to:
  /// **'เต็มจอ'**
  String get fullscreen;

  /// No description provided for @volumeDown.
  ///
  /// In th, this message translates to:
  /// **'ลดเสียง'**
  String get volumeDown;

  /// No description provided for @volumeUp.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มเสียง'**
  String get volumeUp;

  /// No description provided for @groupNumber.
  ///
  /// In th, this message translates to:
  /// **'ชุดที่ {number}'**
  String groupNumber(int number);

  /// No description provided for @stepsCount.
  ///
  /// In th, this message translates to:
  /// **'{count} ขั้นตอน'**
  String stepsCount(int count);

  /// No description provided for @collapseSteps.
  ///
  /// In th, this message translates to:
  /// **'พับขั้นตอน'**
  String get collapseSteps;

  /// No description provided for @showSteps.
  ///
  /// In th, this message translates to:
  /// **'แสดงขั้นตอน'**
  String get showSteps;

  /// No description provided for @deleteStepGroup.
  ///
  /// In th, this message translates to:
  /// **'ลบหัวข้อขั้นตอน'**
  String get deleteStepGroup;

  /// No description provided for @noSubStepsHint.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม'**
  String get noSubStepsHint;

  /// No description provided for @untitledStep.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีชื่อขั้นตอนย่อย'**
  String get untitledStep;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'**
  String get errorInvalidResponse;

  /// No description provided for @errorTimeout.
  ///
  /// In th, this message translates to:
  /// **'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่อีกครั้ง'**
  String get errorTimeout;

  /// No description provided for @errorConnection.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: {details}'**
  String errorConnection(String details);

  /// No description provided for @errorActionFailed.
  ///
  /// In th, this message translates to:
  /// **'{action}ไม่สำเร็จ (HTTP {statusCode})'**
  String errorActionFailed(String action, int statusCode);

  /// No description provided for @loginFailed.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอีเมลและรหัสผ่าน'**
  String get loginFailed;

  /// No description provided for @loadBannersFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดแบนเนอร์ไม่สำเร็จ (HTTP {statusCode})'**
  String loadBannersFailed(int statusCode);

  /// No description provided for @loadCategoriesFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดหมวดหมู่ไม่สำเร็จ'**
  String get loadCategoriesFailed;

  /// No description provided for @actionLoadCart.
  ///
  /// In th, this message translates to:
  /// **'โหลดตะกร้า'**
  String get actionLoadCart;

  /// No description provided for @actionOpenCart.
  ///
  /// In th, this message translates to:
  /// **'เปิดตะกร้า'**
  String get actionOpenCart;

  /// No description provided for @actionAddToCart.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มสูตรนี้ลงตะกร้า'**
  String get actionAddToCart;

  /// No description provided for @actionRemoveFromCart.
  ///
  /// In th, this message translates to:
  /// **'เอาสูตรนี้ออกจากตะกร้า'**
  String get actionRemoveFromCart;

  /// No description provided for @actionClearCart.
  ///
  /// In th, this message translates to:
  /// **'ล้างตะกร้า'**
  String get actionClearCart;

  /// No description provided for @cartSignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบเพื่อใช้ตะกร้า'**
  String get cartSignInRequired;

  /// No description provided for @chatInvalidResponse.
  ///
  /// In th, this message translates to:
  /// **'AI ตอบกลับมาในรูปแบบที่ไม่ถูกต้อง'**
  String get chatInvalidResponse;

  /// No description provided for @chatBuyFirst.
  ///
  /// In th, this message translates to:
  /// **'ต้องซื้อสูตรนี้ก่อนจึงจะถาม AI ได้'**
  String get chatBuyFirst;

  /// No description provided for @chatImageTooLarge.
  ///
  /// In th, this message translates to:
  /// **'รูปใหญ่เกินไป (ไม่เกิน 5MB)'**
  String get chatImageTooLarge;

  /// No description provided for @chatUnavailable.
  ///
  /// In th, this message translates to:
  /// **'AI ไม่พร้อมใช้งานชั่วคราว ลองใหม่อีกครั้ง'**
  String get chatUnavailable;

  /// No description provided for @errorHttp.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาด (HTTP {statusCode})'**
  String errorHttp(int statusCode);

  /// No description provided for @chatTimeout.
  ///
  /// In th, this message translates to:
  /// **'AI ตอบช้าเกินไป ลองใหม่อีกครั้ง'**
  String get chatTimeout;

  /// No description provided for @actionLoadFavorites.
  ///
  /// In th, this message translates to:
  /// **'โหลดรายการโปรด'**
  String get actionLoadFavorites;

  /// No description provided for @actionSaveRecipe.
  ///
  /// In th, this message translates to:
  /// **'บันทึกสูตรนี้'**
  String get actionSaveRecipe;

  /// No description provided for @actionUnsaveRecipe.
  ///
  /// In th, this message translates to:
  /// **'เอาสูตรนี้ออกจากรายการโปรด'**
  String get actionUnsaveRecipe;

  /// No description provided for @favoriteSignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบเพื่อบันทึกสูตร'**
  String get favoriteSignInRequired;

  /// No description provided for @createRecipeFailed.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตรอาหารไม่สำเร็จ'**
  String get createRecipeFailed;

  /// No description provided for @updateRecipeFailed.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขสูตรอาหารไม่สำเร็จ'**
  String get updateRecipeFailed;

  /// No description provided for @loadRecipesFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดสูตรอาหารไม่สำเร็จ'**
  String get loadRecipesFailed;

  /// No description provided for @recipeNotFoundShort.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบเมนูนี้'**
  String get recipeNotFoundShort;

  /// No description provided for @loadRecipeFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดสูตรอาหารไม่สำเร็จ'**
  String get loadRecipeFailed;

  /// No description provided for @searchRecipesFailed.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาสูตรอาหารไม่สำเร็จ'**
  String get searchRecipesFailed;

  /// No description provided for @deleteRecipeFailed.
  ///
  /// In th, this message translates to:
  /// **'ลบสูตรอาหารไม่สำเร็จ'**
  String get deleteRecipeFailed;

  /// No description provided for @actionLoadProfile.
  ///
  /// In th, this message translates to:
  /// **'โหลดโปรไฟล์'**
  String get actionLoadProfile;

  /// No description provided for @actionSaveProfile.
  ///
  /// In th, this message translates to:
  /// **'บันทึกโปรไฟล์'**
  String get actionSaveProfile;

  /// No description provided for @signInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบ'**
  String get signInRequired;

  /// No description provided for @signInBeforeCheckout.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบก่อนชำระเงิน'**
  String get signInBeforeCheckout;

  /// No description provided for @mockPaymentFailedHttp.
  ///
  /// In th, this message translates to:
  /// **'ชำระเงินจำลองไม่สำเร็จ (HTTP {statusCode})'**
  String mockPaymentFailedHttp(int statusCode);

  /// No description provided for @purchaseInvalidResult.
  ///
  /// In th, this message translates to:
  /// **'ผลการชำระเงินจากเซิร์ฟเวอร์ไม่ถูกต้อง'**
  String get purchaseInvalidResult;

  /// No description provided for @purchaseTimeout.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลารอการยืนยันการชำระเงิน'**
  String get purchaseTimeout;

  /// No description provided for @actionLoadComments.
  ///
  /// In th, this message translates to:
  /// **'โหลดความคิดเห็น'**
  String get actionLoadComments;

  /// No description provided for @actionCheckCommentPermission.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบสิทธิ์แสดงความคิดเห็น'**
  String get actionCheckCommentPermission;

  /// No description provided for @actionSaveComment.
  ///
  /// In th, this message translates to:
  /// **'บันทึกความคิดเห็น'**
  String get actionSaveComment;

  /// No description provided for @actionUpdateComment.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขความคิดเห็น'**
  String get actionUpdateComment;

  /// No description provided for @actionDeleteComment.
  ///
  /// In th, this message translates to:
  /// **'ลบความคิดเห็น'**
  String get actionDeleteComment;

  /// No description provided for @editOwnCommentOnly.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขได้เฉพาะความคิดเห็นของตัวเอง'**
  String get editOwnCommentOnly;

  /// No description provided for @deleteOwnCommentOnly.
  ///
  /// In th, this message translates to:
  /// **'ลบได้เฉพาะความคิดเห็นของตัวเอง'**
  String get deleteOwnCommentOnly;

  /// No description provided for @commentSignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบเพื่อแสดงความคิดเห็น'**
  String get commentSignInRequired;

  /// No description provided for @errorNoPermission.
  ///
  /// In th, this message translates to:
  /// **'คุณไม่มีสิทธิ์{action}'**
  String errorNoPermission(String action);

  /// No description provided for @actionLoadCollection.
  ///
  /// In th, this message translates to:
  /// **'โหลด{collection}'**
  String actionLoadCollection(String collection);

  /// No description provided for @librarySignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบเพื่อดูสูตรของคุณ'**
  String get librarySignInRequired;

  /// No description provided for @actionLoadReviews.
  ///
  /// In th, this message translates to:
  /// **'โหลดรีวิว'**
  String get actionLoadReviews;

  /// No description provided for @actionLoadYourReview.
  ///
  /// In th, this message translates to:
  /// **'โหลดรีวิวของคุณ'**
  String get actionLoadYourReview;

  /// No description provided for @actionSaveYourReview.
  ///
  /// In th, this message translates to:
  /// **'บันทึกรีวิวของคุณ'**
  String get actionSaveYourReview;

  /// No description provided for @reviewSignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบเพื่อรีวิวสูตร'**
  String get reviewSignInRequired;

  /// No description provided for @buyToRate.
  ///
  /// In th, this message translates to:
  /// **'ต้องซื้อสูตรนี้ก่อนจึงจะให้คะแนนได้'**
  String get buyToRate;

  /// No description provided for @uploadSignInRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบก่อนอัปโหลด'**
  String get uploadSignInRequired;

  /// No description provided for @uploadPrepareFailed.
  ///
  /// In th, this message translates to:
  /// **'เตรียมการอัปโหลดไม่สำเร็จ'**
  String get uploadPrepareFailed;

  /// No description provided for @uploadFailedHttp.
  ///
  /// In th, this message translates to:
  /// **'อัปโหลดไฟล์ไม่สำเร็จ (HTTP {statusCode})'**
  String uploadFailedHttp(int statusCode);

  /// No description provided for @uploadVerifyFailed.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบไฟล์ที่อัปโหลดไม่สำเร็จ'**
  String get uploadVerifyFailed;

  /// No description provided for @commentEmpty.
  ///
  /// In th, this message translates to:
  /// **'ความคิดเห็นต้องไม่ว่าง'**
  String get commentEmpty;

  /// No description provided for @signInAgain.
  ///
  /// In th, this message translates to:
  /// **'กรุณาเข้าสู่ระบบอีกครั้ง'**
  String get signInAgain;

  /// No description provided for @roleCreator.
  ///
  /// In th, this message translates to:
  /// **'ผู้สร้างสูตร'**
  String get roleCreator;

  /// No description provided for @roleAdmin.
  ///
  /// In th, this message translates to:
  /// **'ผู้ดูแลระบบ'**
  String get roleAdmin;

  /// No description provided for @roleFoodLover.
  ///
  /// In th, this message translates to:
  /// **'คนรักอาหาร'**
  String get roleFoodLover;

  /// No description provided for @faqCreateTitle.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตรอาหารยังไง'**
  String get faqCreateTitle;

  /// No description provided for @faqCreateBody.
  ///
  /// In th, this message translates to:
  /// **'กดปุ่ม + ได้ 2 ที่\n• หน้าคอมมูนิตี้: สร้างสูตรแจกฟรีให้ทุกคนดู\n• โปรไฟล์ → สูตรของฉัน: สร้างสูตรแบบ Official ตั้งราคาขายได้\nกรอกชื่อ รูปปก รายละเอียด หมวดหมู่ และขั้นตอน แล้วกด \"เผยแพร่สูตรอาหาร\"'**
  String get faqCreateBody;

  /// No description provided for @faqDraftTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังเขียนสูตรไม่เสร็จ เก็บไว้ก่อนได้ไหม'**
  String get faqDraftTitle;

  /// No description provided for @faqDraftBody.
  ///
  /// In th, this message translates to:
  /// **'ได้ กดย้อนกลับระหว่างสร้างสูตรแล้วเลือก \"บันทึกฉบับร่าง\" สูตรจะอยู่ใน โปรไฟล์ → ฉบับร่าง กลับมาเขียนต่อหรือเผยแพร่ทีหลังได้'**
  String get faqDraftBody;

  /// No description provided for @faqEditTitle.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขหรือลบสูตรของฉัน'**
  String get faqEditTitle;

  /// No description provided for @faqEditBody.
  ///
  /// In th, this message translates to:
  /// **'เปิดสูตรแล้วกดปุ่ม ⋮ มุมขวาบน เลือก \"แก้ไข\" หรือ \"ลบสูตรอาหาร\"\nสูตร Official ที่เผยแพร่แล้วแก้ไขไม่ได้ (ลบได้)'**
  String get faqEditBody;

  /// No description provided for @faqBuyTitle.
  ///
  /// In th, this message translates to:
  /// **'ซื้อสูตรยังไง'**
  String get faqBuyTitle;

  /// No description provided for @faqBuyBody.
  ///
  /// In th, this message translates to:
  /// **'เปิดสูตรแล้วกด \"ซื้อเลย\" เพื่อใส่ตะกร้า จากนั้นเข้าตะกร้าแล้วกดชำระเงิน สูตรที่ซื้อแล้วดูได้ที่ โปรไฟล์ → ซื้อแล้ว'**
  String get faqBuyBody;

  /// No description provided for @faqAiTitle.
  ///
  /// In th, this message translates to:
  /// **'ถาม AI เกี่ยวกับสูตรได้ยังไง'**
  String get faqAiTitle;

  /// No description provided for @faqAiBody.
  ///
  /// In th, this message translates to:
  /// **'ปุ่ม \"ถาม AI เกี่ยวกับสูตรนี้\" จะขึ้นในสูตรที่คุณซื้อแล้วหรือเป็นเจ้าของ พิมพ์คำถามหรือแนบรูปอาหารได้ คำตอบจาก AI อาจไม่ถูกต้องทุกครั้ง โปรดใช้วิจารณญาณ โดยเฉพาะเรื่องการแพ้อาหาร'**
  String get faqAiBody;

  /// No description provided for @faqRateTitle.
  ///
  /// In th, this message translates to:
  /// **'ให้คะแนนและรีวิวสูตร'**
  String get faqRateTitle;

  /// No description provided for @faqRateBody.
  ///
  /// In th, this message translates to:
  /// **'ให้คะแนนได้เฉพาะสูตรที่ซื้อแล้ว กด \"ให้คะแนน\" ในหน้าสูตร แก้คะแนนทีหลังได้ ส่วนสูตรในคอมมูนิตี้แสดงความคิดเห็นได้เลย'**
  String get faqRateBody;

  /// No description provided for @faqProfileTitle.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนรูปโปรไฟล์หรือชื่อ'**
  String get faqProfileTitle;

  /// No description provided for @faqProfileBody.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์ → แก้ไขโปรไฟล์ เปลี่ยนรูปและชื่อที่แสดงได้ อีเมลใช้เข้าสู่ระบบจึงเปลี่ยนไม่ได้'**
  String get faqProfileBody;

  /// No description provided for @faqForgotTitle.
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน'**
  String get faqForgotTitle;

  /// No description provided for @faqForgotBody.
  ///
  /// In th, this message translates to:
  /// **'ตอนนี้ยังไม่มีระบบรีเซ็ตรหัสผ่านผ่านอีเมล ถ้ายังเข้าสู่ระบบอยู่ เปลี่ยนรหัสได้ที่ ตั้งค่า → เปลี่ยนรหัสผ่าน ถ้าเข้าไม่ได้แล้วโปรดติดต่อทีมงาน'**
  String get faqForgotBody;

  /// No description provided for @faqLostTitle.
  ///
  /// In th, this message translates to:
  /// **'มือถือหาย หรือสงสัยว่ามีคนใช้บัญชีของฉัน'**
  String get faqLostTitle;

  /// No description provided for @faqLostBody.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า → ออกจากระบบทุกอุปกรณ์ แล้วเปลี่ยนรหัสผ่าน ทุกเครื่องที่เข้าสู่ระบบอยู่จะหลุดออกทันที'**
  String get faqLostBody;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลที่เราเก็บ'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectBody.
  ///
  /// In th, this message translates to:
  /// **'• ข้อมูลบัญชี: อีเมล ชื่อที่แสดง รูปโปรไฟล์ และรหัสผ่าน (เก็บแบบเข้ารหัสทางเดียว ทีมงานอ่านรหัสผ่านของคุณไม่ได้)\n• เนื้อหาที่คุณสร้าง: สูตรอาหาร รูปภาพ วิดีโอ คอมเมนต์ และรีวิว\n• การใช้งานในแอป: รายการโปรด ตะกร้า และประวัติการซื้อสูตร'**
  String get privacyCollectBody;

  /// No description provided for @privacyVisibleTitle.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลที่คนอื่นมองเห็น'**
  String get privacyVisibleTitle;

  /// No description provided for @privacyVisibleBody.
  ///
  /// In th, this message translates to:
  /// **'ชื่อที่แสดง รูปโปรไฟล์ สูตรที่เผยแพร่ คอมเมนต์ และรีวิวของคุณ ผู้ใช้คนอื่นมองเห็นได้ ส่วนอีเมล รายการโปรด ตะกร้า และประวัติการซื้อ เห็นได้เฉพาะคุณ'**
  String get privacyVisibleBody;

  /// No description provided for @privacyAiTitle.
  ///
  /// In th, this message translates to:
  /// **'แชทถาม AI'**
  String get privacyAiTitle;

  /// No description provided for @privacyAiBody.
  ///
  /// In th, this message translates to:
  /// **'คำถามและรูปที่คุณส่งในแชท AI จะถูกส่งไปยังผู้ให้บริการ AI ภายนอกเพื่อสร้างคำตอบ บทสนทนาถูกจำไว้ชั่วคราวและถูกลืมเมื่อไม่มีการใช้งานประมาณ 20 นาที เราไม่เก็บรูปที่ส่งในแชท'**
  String get privacyAiBody;

  /// No description provided for @privacyDeviceTitle.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลบนเครื่องของคุณ'**
  String get privacyDeviceTitle;

  /// No description provided for @privacyDeviceBody.
  ///
  /// In th, this message translates to:
  /// **'แอปเก็บข้อมูลเข้าสู่ระบบไว้ในพื้นที่ปลอดภัยของเครื่อง และเก็บรูปภาพที่เคยโหลดไว้ในเครื่องเพื่อให้เปิดได้เร็วขึ้น ข้อมูลเข้าสู่ระบบถูกลบเมื่อคุณออกจากระบบ'**
  String get privacyDeviceBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In th, this message translates to:
  /// **'การลบข้อมูล'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชีได้ที่ ตั้งค่า → ลบบัญชี อีเมล ชื่อ รูปโปรไฟล์ รายการโปรด และตะกร้าจะถูกลบ สูตรของคุณจะไม่แสดงอีก ยกเว้นผู้ที่ซื้อไปแล้ว คอมเมนต์และรีวิวยังอยู่โดยแสดงเป็น \"ผู้ใช้ที่ลบบัญชีแล้ว\"'**
  String get privacyDeleteBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In th, this message translates to:
  /// **'ติดต่อเรา'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In th, this message translates to:
  /// **'มีคำถามเรื่องข้อมูลส่วนตัว ติดต่อทีมงานได้ที่หน้าช่วยเหลือและติดต่อ'**
  String get privacyContactBody;

  /// No description provided for @termsAccountTitle.
  ///
  /// In th, this message translates to:
  /// **'บัญชีผู้ใช้'**
  String get termsAccountTitle;

  /// No description provided for @termsAccountBody.
  ///
  /// In th, this message translates to:
  /// **'คุณต้องรับผิดชอบการรักษารหัสผ่านและการใช้งานทั้งหมดที่เกิดจากบัญชีของคุณ ถ้าสงสัยว่ามีผู้อื่นใช้บัญชี ให้ออกจากระบบทุกอุปกรณ์และเปลี่ยนรหัสผ่านทันที'**
  String get termsAccountBody;

  /// No description provided for @termsContentTitle.
  ///
  /// In th, this message translates to:
  /// **'เนื้อหาที่คุณโพสต์'**
  String get termsContentTitle;

  /// No description provided for @termsContentBody.
  ///
  /// In th, this message translates to:
  /// **'สูตร รูป วิดีโอ คอมเมนต์ และรีวิวที่คุณโพสต์ต้องเป็นของคุณหรือคุณมีสิทธิ์เผยแพร่ ห้ามโพสต์เนื้อหาที่ผิดกฎหมาย ละเมิดลิขสิทธิ์ หรือทำร้ายผู้อื่น ทีมงานอาจลบเนื้อหาหรือระงับบัญชีที่ฝ่าฝืน'**
  String get termsContentBody;

  /// No description provided for @termsPurchaseTitle.
  ///
  /// In th, this message translates to:
  /// **'การซื้อสูตร'**
  String get termsPurchaseTitle;

  /// No description provided for @termsPurchaseBody.
  ///
  /// In th, this message translates to:
  /// **'สูตรที่ซื้อแล้วเปิดดูได้ในแอปเพื่อใช้ส่วนตัว ห้ามคัดลอกหรือนำไปเผยแพร่ต่อโดยไม่ได้รับอนุญาตจากผู้สร้างสูตร'**
  String get termsPurchaseBody;

  /// No description provided for @termsAiTitle.
  ///
  /// In th, this message translates to:
  /// **'คำตอบจาก AI'**
  String get termsAiTitle;

  /// No description provided for @termsAiBody.
  ///
  /// In th, this message translates to:
  /// **'คำแนะนำจาก AI ใช้ประกอบการทำอาหารเท่านั้น อาจไม่ถูกต้องหรือไม่ครบถ้วน โปรดตรวจสอบเองก่อนใช้ โดยเฉพาะเรื่องการแพ้อาหารและความปลอดภัยของอาหาร'**
  String get termsAiBody;

  /// No description provided for @termsCloseTitle.
  ///
  /// In th, this message translates to:
  /// **'การปิดบัญชี'**
  String get termsCloseTitle;

  /// No description provided for @termsCloseBody.
  ///
  /// In th, this message translates to:
  /// **'คุณลบบัญชีได้ทุกเมื่อที่ ตั้งค่า → ลบบัญชี'**
  String get termsCloseBody;

  /// No description provided for @termsChangesTitle.
  ///
  /// In th, this message translates to:
  /// **'การเปลี่ยนแปลงข้อกำหนด'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesBody.
  ///
  /// In th, this message translates to:
  /// **'ข้อกำหนดนี้อาจมีการปรับปรุง การใช้งานแอปต่อหลังมีการเปลี่ยนแปลง ถือว่าคุณยอมรับข้อกำหนดฉบับใหม่'**
  String get termsChangesBody;

  /// No description provided for @settingsGeneral.
  ///
  /// In th, this message translates to:
  /// **'ทั่วไป'**
  String get settingsGeneral;

  /// No description provided for @language.
  ///
  /// In th, this message translates to:
  /// **'ภาษา'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In th, this message translates to:
  /// **'เลือกภาษา'**
  String get chooseLanguage;

  /// No description provided for @englishNameHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น Spicy basil chicken'**
  String get englishNameHint;

  /// No description provided for @englishNameHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ ใช้แสดงเมื่อผู้ใช้เลือกภาษาอังกฤษ'**
  String get englishNameHelper;

  /// No description provided for @statRecipeRating.
  ///
  /// In th, this message translates to:
  /// **'คะแนนสูตร'**
  String get statRecipeRating;

  /// No description provided for @reviewsCountShort.
  ///
  /// In th, this message translates to:
  /// **'{count} รีวิว'**
  String reviewsCountShort(int count);

  /// No description provided for @statSales.
  ///
  /// In th, this message translates to:
  /// **'ขายได้'**
  String get statSales;

  /// No description provided for @statOfficialSaves.
  ///
  /// In th, this message translates to:
  /// **'บันทึกสูตร Official'**
  String get statOfficialSaves;

  /// No description provided for @statCommunitySaves.
  ///
  /// In th, this message translates to:
  /// **'บันทึกสูตรคอมมูนิตี้'**
  String get statCommunitySaves;

  /// No description provided for @statSavesReceived.
  ///
  /// In th, this message translates to:
  /// **'ถูกบันทึก'**
  String get statSavesReceived;

  /// No description provided for @statCommentsReceived.
  ///
  /// In th, this message translates to:
  /// **'ความคิดเห็น'**
  String get statCommentsReceived;

  /// No description provided for @statReviewsWritten.
  ///
  /// In th, this message translates to:
  /// **'รีวิวที่เขียน'**
  String get statReviewsWritten;

  /// No description provided for @recentPurchases.
  ///
  /// In th, this message translates to:
  /// **'ซื้อล่าสุด'**
  String get recentPurchases;

  /// No description provided for @continueDraftTitle.
  ///
  /// In th, this message translates to:
  /// **'เขียนต่อจากที่ค้างไว้'**
  String get continueDraftTitle;

  /// No description provided for @continueDraftSubtitle.
  ///
  /// In th, this message translates to:
  /// **'มีฉบับร่าง {count} สูตร'**
  String continueDraftSubtitle(int count);

  /// No description provided for @firstRecipeTitle.
  ///
  /// In th, this message translates to:
  /// **'แบ่งปันสูตรแรกของคุณ'**
  String get firstRecipeTitle;

  /// No description provided for @firstRecipeSubtitleCreator.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตร Official และตั้งราคาขายได้'**
  String get firstRecipeSubtitleCreator;

  /// No description provided for @firstRecipeSubtitleUser.
  ///
  /// In th, this message translates to:
  /// **'สร้างสูตรแจกฟรีให้ทุกคนในคอมมูนิตี้'**
  String get firstRecipeSubtitleUser;
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
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
