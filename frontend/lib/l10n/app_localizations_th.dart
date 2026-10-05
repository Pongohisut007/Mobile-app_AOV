// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navCommunity => 'คอมมูนิตี้';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get recommendedTitle => 'เมนูแนะนำ';

  @override
  String get seeMore => 'ดูทั้งหมด';

  @override
  String get allRecipesTitle => 'สูตรทั้งหมด';

  @override
  String get searchRecipeHint => 'ค้นหาสูตรอาหาร';

  @override
  String get ratingNew => 'ใหม่';

  @override
  String get favoriteRemoveTooltip => 'เอาออกจากรายการโปรด';

  @override
  String get favoriteAddTooltip => 'บันทึกลงรายการโปรด';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get noRecipesInCategory => 'ยังไม่มีเมนูในหมวดนี้';

  @override
  String noRecipesNamed(String query) {
    return 'ไม่พบเมนูที่ชื่อ \"$query\"';
  }

  @override
  String get loadMoreRecipesFailed => 'โหลดเมนูเพิ่มไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get cartFallbackTitle => 'เมนูนี้';

  @override
  String cartAdded(String title) {
    return 'เพิ่ม $title ลงตะกร้าแล้ว';
  }

  @override
  String cartAlreadyIn(String title) {
    return '$title อยู่ในตะกร้าแล้ว';
  }

  @override
  String cartAddFailed(String title) {
    return 'เพิ่ม $title ลงตะกร้าไม่สำเร็จ';
  }

  @override
  String get routeNotFound => 'ไม่พบหน้านี้';

  @override
  String get categoryAll => 'ทั้งหมด';

  @override
  String get createRecipeTooltip => 'สร้างสูตร';

  @override
  String get searchTooltip => 'ค้นหา';

  @override
  String get closeSearchTooltip => 'ปิดการค้นหา';

  @override
  String errorWithMessage(String message) {
    return 'เกิดข้อผิดพลาด: $message';
  }

  @override
  String get noPostsInCategory => 'ยังไม่มีโพสต์ในหมวดนี้';

  @override
  String noPostsNamed(String query) {
    return 'ไม่พบโพสต์ที่ชื่อ \"$query\"';
  }

  @override
  String get loadFailedTryAgain => 'โหลดไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get showMore => 'แสดงเพิ่ม';

  @override
  String get noData => 'ไม่มีข้อมูล';

  @override
  String get timeJustNow => 'เมื่อกี้';

  @override
  String timeMinutesAgo(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ชั่วโมงที่แล้ว';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count วันที่แล้ว';
  }

  @override
  String timeMonthsAgo(int count) {
    return '$count เดือนที่แล้ว';
  }

  @override
  String timeYearsAgo(int count) {
    return '$count ปีที่แล้ว';
  }

  @override
  String get anonymousUser => 'ผู้ใช้งาน';

  @override
  String get viewCommentsTooltip => 'ดูความคิดเห็น';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get editProfile => 'แก้ไขโปรไฟล์';

  @override
  String get yourKitchenTitle => 'ครัวของคุณ';

  @override
  String appVersionFooter(String appName, String version) {
    return '$appName · เวอร์ชัน $version';
  }

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get cartTooltip => 'ตะกร้า';

  @override
  String get myRecipes => 'สูตรของฉัน';

  @override
  String myRecipesDetail(int count) {
    return 'เผยแพร่ $count สูตร';
  }

  @override
  String get purchasedRecipes => 'ซื้อแล้ว';

  @override
  String purchasedDetail(int count) {
    return '$count สูตร';
  }

  @override
  String get favorites => 'รายการโปรด';

  @override
  String favoritesDetail(int count) {
    return 'บันทึกไว้ $count สูตร';
  }

  @override
  String get drafts => 'ฉบับร่าง';

  @override
  String draftsDetail(int count) {
    return 'ยังไม่เสร็จ $count สูตร';
  }

  @override
  String get guest => 'ผู้เยี่ยมชม';

  @override
  String get fieldName => 'ชื่อ';

  @override
  String get fieldEmail => 'อีเมล';

  @override
  String get profileLoadFailed => 'โหลดโปรไฟล์ไม่สำเร็จ';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get passwordChangedOthersSignedOut =>
      'เปลี่ยนรหัสผ่านแล้ว อุปกรณ์อื่นถูกออกจากระบบ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get signOutConfirmTitle => 'ออกจากระบบ?';

  @override
  String get signOutConfirmMessage =>
      'คุณเข้าสู่ระบบใหม่เพื่อดูสูตรของคุณได้ทุกเมื่อ';

  @override
  String get signOutAllTitle => 'ออกจากระบบทุกอุปกรณ์?';

  @override
  String get signOutAllMessage =>
      'ทุกเครื่องที่เข้าสู่ระบบด้วยบัญชีนี้ รวมถึงเครื่องนี้ จะถูกออกจากระบบทันที';

  @override
  String get signOutAllAction => 'ออกจากระบบทั้งหมด';

  @override
  String get signOutAllDevices => 'ออกจากระบบทุกอุปกรณ์';

  @override
  String get signOutAllDevicesHint =>
      'ใช้เมื่อมือถือหาย หรือสงสัยว่ามีคนใช้บัญชี';

  @override
  String versionLabel(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get settingsAccount => 'บัญชี';

  @override
  String get changePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get settingsHelpAndTerms => 'ความช่วยเหลือและข้อกำหนด';

  @override
  String get helpAndSupport => 'ช่วยเหลือและติดต่อ';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get termsOfUse => 'ข้อกำหนดการใช้งาน';

  @override
  String get aboutApp => 'เกี่ยวกับแอป';

  @override
  String aboutAppSubtitle(String version) {
    return 'เวอร์ชัน $version · ไลเซนส์โอเพนซอร์ส';
  }

  @override
  String get dangerZone => 'โซนอันตราย';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get deleteAccountHint => 'ปิดบัญชีและลบข้อมูลส่วนตัว กู้คืนไม่ได้';

  @override
  String get faqTitle => 'คำถามที่พบบ่อย';

  @override
  String get contactTeam => 'ติดต่อทีมงาน';

  @override
  String get emailCopied => 'คัดลอกอีเมลแล้ว';

  @override
  String get noAccountPrompt => 'ยังไม่มีบัญชี? ';

  @override
  String get signUp => 'สมัครสมาชิก';

  @override
  String get haveAccountPrompt => 'มีบัญชีอยู่แล้ว? ';

  @override
  String get emailAddress => 'อีเมล';

  @override
  String get emailHint => 'กรอกอีเมลของคุณ';

  @override
  String get emailRequired => 'กรุณากรอกอีเมล';

  @override
  String get emailInvalid => 'กรอกอีเมลให้ถูกต้อง';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get passwordHint => 'กรอกรหัสผ่าน';

  @override
  String get passwordRequired => 'กรุณากรอกรหัสผ่าน';

  @override
  String get passwordTooShort => 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';

  @override
  String get passwordTooLong => 'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร';

  @override
  String get showPassword => 'แสดงรหัสผ่าน';

  @override
  String get hidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get orSignInWith => 'หรือเข้าสู่ระบบด้วย';

  @override
  String get orSignUpWith => 'หรือสมัครด้วย';

  @override
  String get acceptTermsRequired =>
      'กรุณายอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว';

  @override
  String get displayName => 'ชื่อที่แสดง';

  @override
  String get displayNameHint => 'กรอกชื่อที่แสดง';

  @override
  String get displayNameRequired => 'กรุณากรอกชื่อที่แสดง';

  @override
  String get displayNameTooLong => 'ชื่อที่แสดงต้องไม่เกิน 150 ตัวอักษร';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get confirmPasswordHint => 'กรอกรหัสผ่านอีกครั้ง';

  @override
  String get confirmPasswordRequired => 'กรุณายืนยันรหัสผ่าน';

  @override
  String get passwordsDoNotMatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get termsAgreePrefix => 'ฉันยอมรับ';

  @override
  String get termsAgreeUserAgreement => 'ข้อกำหนดการใช้งาน';

  @override
  String get termsAgreeAnd => ' และ';

  @override
  String get termsAgreePrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get sessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';

  @override
  String get saving => 'กำลังบันทึก...';

  @override
  String get currentPassword => 'รหัสผ่านปัจจุบัน';

  @override
  String get currentPasswordRequired => 'กรอกรหัสผ่านปัจจุบัน';

  @override
  String get newPassword => 'รหัสผ่านใหม่';

  @override
  String get passwordLengthHelper => '8-72 ตัวอักษร';

  @override
  String get newPasswordSameAsOld => 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม';

  @override
  String get confirmNewPassword => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get newPasswordsDoNotMatch => 'รหัสผ่านใหม่ไม่ตรงกัน';

  @override
  String get deletingAccount => 'กำลังลบบัญชี...';

  @override
  String get deleteAccountPermanently => 'ลบบัญชีถาวร';

  @override
  String get deleteIrreversible => 'ลบแล้วกู้คืนไม่ได้';

  @override
  String get deleteBulletSignOut =>
      'ออกจากระบบทุกอุปกรณ์ และเข้าสู่ระบบด้วยบัญชีนี้ไม่ได้อีก';

  @override
  String get deleteBulletPersonalData =>
      'ชื่อ รูปโปรไฟล์ และอีเมลถูกลบ กลับมาสมัครใหม่ด้วยอีเมลเดิมได้ แต่จะเป็นบัญชีใหม่';

  @override
  String get deleteBulletRecipes =>
      'สูตรที่คุณสร้างจะไม่แสดงให้ใครเห็นอีก ยกเว้นคนที่ซื้อไปแล้วยังเปิดดูได้';

  @override
  String get deleteBulletLibrary =>
      'รายการโปรด ตะกร้า และสูตรที่คุณซื้อไว้จะหายไป';

  @override
  String get deleteBulletComments =>
      'คอมเมนต์และรีวิวยังอยู่ แต่จะแสดงเป็น \"ผู้ใช้ที่ลบบัญชีแล้ว\"';

  @override
  String get confirmWithPassword => 'ยืนยันด้วยรหัสผ่าน';

  @override
  String get passwordEnter => 'กรอกรหัสผ่าน';

  @override
  String get deleteUnderstand => 'ฉันเข้าใจว่าการลบบัญชีกู้คืนไม่ได้';

  @override
  String imageOpenFailed(String error) {
    return 'เปิดรูปไม่ได้: $error';
  }

  @override
  String get save => 'บันทึก';

  @override
  String get changeProfilePhoto => 'เปลี่ยนรูปโปรไฟล์';

  @override
  String get emailCannotChange => 'อีเมลใช้สำหรับเข้าสู่ระบบ แก้ไขไม่ได้';

  @override
  String get difficultyEasy => 'ง่าย';

  @override
  String get difficultyMedium => 'ปานกลาง';

  @override
  String get difficultyHard => 'ยาก';

  @override
  String get priceFree => 'ฟรี';

  @override
  String get mockIapDisabled =>
      'โหมดซื้อจำลองถูกปิดอยู่ กรุณาเชื่อม Google Play Billing';

  @override
  String get mockPaymentCancelled => 'จำลองการยกเลิกการชำระเงินแล้ว';

  @override
  String get mockPaymentFailed => 'จำลองการชำระเงินไม่สำเร็จ';

  @override
  String get mockBillingTitle => 'Google Play Billing — โหมดจำลอง';

  @override
  String get mockBillingSubtitle =>
      'เลือกผลลัพธ์ที่ต้องการทดสอบ ระบบนี้ไม่ตัดเงินจริง';

  @override
  String get mockPaySuccess => 'จำลองชำระสำเร็จ';

  @override
  String get mockPayFail => 'จำลองชำระไม่สำเร็จ';

  @override
  String get mockUserCancel => 'จำลองผู้ใช้ยกเลิก';

  @override
  String get clearCartTitle => 'ล้างตะกร้า?';

  @override
  String get clearCartMessage => 'สูตรทั้งหมดในตะกร้าจะถูกเอาออก';

  @override
  String get clear => 'ล้าง';

  @override
  String get cartTitle => 'ตะกร้า';

  @override
  String get clearCartTooltip => 'ล้างตะกร้า';

  @override
  String get cartLoadFailed => 'โหลดตะกร้าไม่สำเร็จ';

  @override
  String get selectAll => 'เลือกทั้งหมด';

  @override
  String selectedOfTotal(int selected, int total) {
    return 'เลือก $selected จาก $total รายการ';
  }

  @override
  String get cartEmptyTitle => 'ตะกร้าว่างเปล่า';

  @override
  String get cartEmptyMessage => 'สูตรที่คุณเพิ่มจะแสดงที่นี่';

  @override
  String get browseRecipes => 'ดูสูตรอาหาร';

  @override
  String selectItemForCheckout(String title) {
    return 'เลือก $title เพื่อชำระเงิน';
  }

  @override
  String get remove => 'เอาออก';

  @override
  String itemCount(int count) {
    return '$count รายการ';
  }

  @override
  String get checkout => 'ชำระเงิน';

  @override
  String get paymentFailedTitle => 'ชำระเงินไม่สำเร็จ';

  @override
  String get purchaseIncomplete => 'ยังซื้อสูตรไม่ครบ';

  @override
  String purchasePartialMessage(int count) {
    return 'ก่อนเกิดข้อผิดพลาด ซื้อสำเร็จแล้ว $count สูตร สูตรที่เหลือยังอยู่ในตะกร้า';
  }

  @override
  String get retry => 'ลองใหม่';

  @override
  String get backToCart => 'กลับไปตะกร้า';

  @override
  String get paymentSuccessTitle => 'ชำระเงินสำเร็จ';

  @override
  String get purchaseSuccess => 'ซื้อสูตรสำเร็จ!';

  @override
  String purchaseUnlocked(int count) {
    return 'เปิดสิทธิ์เข้าถึง $count สูตรแล้ว';
  }

  @override
  String get mockPaymentNotice =>
      'รายการนี้เป็นการชำระเงินจำลอง ไม่มีการตัดเงินจริง';

  @override
  String get viewPurchasedRecipes => 'ดูสูตรที่ซื้อแล้ว';

  @override
  String get backToHome => 'กลับหน้าหลัก';

  @override
  String get checkoutNow => 'ชำระเงินเลย';

  @override
  String get buyNow => 'ซื้อเลย';

  @override
  String get recipeNotFound => 'ไม่พบข้อมูลเมนูนี้';

  @override
  String get startCooking => 'เริ่มทำอาหาร';

  @override
  String get deleteRecipe => 'ลบสูตรอาหาร';

  @override
  String get deleteRecipeConfirm =>
      'คุณต้องการลบสูตรอาหารนี้ใช่หรือไม่?\nข้อมูลที่เกี่ยวข้องทั้งหมดจะถูกลบด้วย';

  @override
  String get delete => 'ลบ';

  @override
  String get changesSaved => 'บันทึกการแก้ไขแล้ว';

  @override
  String get goBack => 'ย้อนกลับ';

  @override
  String get description => 'รายละเอียด';

  @override
  String get edit => 'แก้ไข';

  @override
  String minutesShort(int count) {
    return '$count น.';
  }

  @override
  String get infoPrep => 'เตรียม';

  @override
  String get infoCook => 'ปรุง';

  @override
  String get infoServings => 'เสิร์ฟ';

  @override
  String get infoLevel => 'ระดับ';

  @override
  String get event => 'กิจกรรม';

  @override
  String get details => 'รายละเอียด';

  @override
  String get eventNoDetails => 'ยังไม่มีรายละเอียดของกิจกรรมนี้';

  @override
  String periodStarts(String date) {
    return 'เริ่ม $date';
  }

  @override
  String periodEnds(String date) {
    return 'ถึง $date';
  }

  @override
  String get starLabel1 => 'แย่มาก';

  @override
  String get starLabel2 => 'พอใช้';

  @override
  String get starLabel3 => 'ดี';

  @override
  String get starLabel4 => 'ดีมาก';

  @override
  String get starLabel5 => 'ยอดเยี่ยม!';

  @override
  String get rateThisRecipe => 'ให้คะแนนสูตรนี้';

  @override
  String get rateDialogSubtitle =>
      'ความคิดเห็นของคุณช่วยให้เราพัฒนาสูตรอาหารให้ดียิ่งขึ้น';

  @override
  String get tapStarsToRate => 'แตะดาวเพื่อให้คะแนน';

  @override
  String get whatDidYouLike => 'ชอบอะไรในสูตรนี้';

  @override
  String get tellMore => 'เล่าเพิ่มเติม ';

  @override
  String get optional => '(ไม่บังคับ)';

  @override
  String get reviewCommentHint => 'เล่าว่าทำสูตรนี้แล้วเป็นยังไงบ้าง';

  @override
  String get submitRating => 'ส่งคะแนน';

  @override
  String get updateRating => 'อัปเดตคะแนน';

  @override
  String get thanksForRating => 'ขอบคุณสำหรับคะแนน!';

  @override
  String get ratingAddedMessage =>
      'รีวิวของคุณถูกเพิ่มในหน้าสูตรแล้ว\nแก้ไขได้ทุกเมื่อจากปุ่ม \"แก้ไขคะแนน\"';

  @override
  String get backToRecipe => 'กลับไปที่สูตร';

  @override
  String get close => 'ปิด';

  @override
  String get ratingLoadFailed => 'โหลดคะแนนไม่สำเร็จ';

  @override
  String get rate => 'ให้คะแนน';

  @override
  String get editRating => 'แก้ไขคะแนน';

  @override
  String get latestReviews => 'รีวิวล่าสุด';

  @override
  String get noReviewsYet => 'ยังไม่มีรีวิว';

  @override
  String get ratingsAndReviews => 'คะแนนและรีวิว';

  @override
  String get noRatingsYet => 'ยังไม่มีคะแนน';

  @override
  String fromReviewCount(int count) {
    return 'จาก $count รีวิว';
  }

  @override
  String starCount(int count) {
    return '$count ดาว';
  }

  @override
  String get allReviews => 'รีวิวทั้งหมด';

  @override
  String get averageRating => 'คะแนนเฉลี่ย';

  @override
  String get tagTasty => 'รสชาติดี';

  @override
  String get tagEasy => 'ทำง่าย';

  @override
  String get tagSpicyRight => 'เผ็ดกำลังดี';

  @override
  String get tagEasyIngredients => 'วัตถุดิบหาง่าย';

  @override
  String get commentMore => '...เพิ่มเติม';

  @override
  String get commentLess => '  ย่อ';

  @override
  String get actionFailed => 'ทำรายการไม่สำเร็จ';

  @override
  String get buyToComment => 'ซื้อสูตรนี้ก่อนจึงจะแสดงความคิดเห็นได้';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get commentsLoadFailed => 'โหลดความคิดเห็นไม่สำเร็จ';

  @override
  String get noCommentsYet => 'ยังไม่มีความคิดเห็น';

  @override
  String get viewMoreComments => 'ดูความคิดเห็นเพิ่มเติม';

  @override
  String get loadMoreCommentsAgain => 'โหลดความคิดเห็นเพิ่มอีกครั้ง';

  @override
  String get deleteComment => 'ลบความคิดเห็น';

  @override
  String get deleteCommentConfirm => 'ต้องการลบความคิดเห็นนี้ใช่ไหม';

  @override
  String get editComment => 'แก้ไขความคิดเห็น';

  @override
  String get writeCommentHint => 'เขียนความคิดเห็น';

  @override
  String get addCommentHint => 'เพิ่มความคิดเห็น...';

  @override
  String get sendComment => 'ส่งความคิดเห็น';

  @override
  String get manageComment => 'จัดการความคิดเห็น';

  @override
  String get askAiAboutRecipe => 'ถาม AI เกี่ยวกับสูตรนี้';

  @override
  String get pickFromGallery => 'เลือกจากคลังรูป';

  @override
  String get takePhoto => 'ถ่ายรูป';

  @override
  String get newChat => 'เริ่มแชทใหม่';

  @override
  String get chatEmptyHint =>
      'ถามอะไรก็ได้เกี่ยวกับสูตรนี้\nเช่น \"ใช้อะไรแทนน้ำปลาได้บ้าง\"';

  @override
  String get aiTyping => 'AI กำลังพิมพ์...';

  @override
  String get attachImage => 'แนบรูป';

  @override
  String get chatInputHint => 'พิมพ์คำถาม...';

  @override
  String get chatImageHint => 'ถามเกี่ยวกับรูปนี้ (ไม่พิมพ์ก็ได้)';

  @override
  String openEditorFailed(String error) {
    return 'เปิดหน้าแก้ไขสูตรไม่ได้: $error';
  }

  @override
  String get collectionEmptyMyRecipes => 'คุณยังไม่ได้เผยแพร่สูตรเลย';

  @override
  String get collectionEmptyPurchased => 'คุณยังไม่ได้ซื้อสูตรเลย';

  @override
  String get collectionEmptyFavorites => 'สูตรที่คุณบันทึกไว้จะแสดงที่นี่';

  @override
  String get collectionEmptyDrafts => 'คุณไม่มีสูตรที่ยังทำไม่เสร็จ';

  @override
  String get pickCoverBeforePublish => 'เลือกรูปตัวอย่างอาหารก่อนเผยแพร่สูตร';

  @override
  String get pickAtLeastOneCategory => 'เลือกหมวดหมู่อย่างน้อย 1 หมวด';

  @override
  String get addStepsBeforePublish => 'เพิ่มขั้นตอนการทำอาหารก่อนเผยแพร่สูตร';

  @override
  String get completeAllSteps => 'กรอกชื่อและรายละเอียดให้ครบทุกขั้นตอน';

  @override
  String defaultSectionTitle(int number) {
    return 'หัวข้อชุดขั้นตอน $number';
  }

  @override
  String get draftRecipeTitle => 'สูตรอาหารฉบับร่าง';

  @override
  String get draftSaved => 'บันทึกฉบับร่างแล้ว';

  @override
  String get saveDraftBeforeLeaving => 'บันทึกฉบับร่างก่อนออกไหม?';

  @override
  String get saveDraftBeforeLeavingMessage =>
      'ข้อมูลที่กรอกไว้จะถูกเก็บในฉบับร่างบนหน้าโปรไฟล์';

  @override
  String get stay => 'อยู่ต่อ';

  @override
  String get leaveWithoutSaving => 'ออกโดยไม่บันทึก';

  @override
  String get saveDraft => 'บันทึกฉบับร่าง';

  @override
  String get discardEditsTitle => 'ยกเลิกการแก้ไขไหม?';

  @override
  String get discardEditsMessage => 'การแก้ไขที่ยังไม่ได้บันทึกจะหายไป';

  @override
  String get keepEditing => 'แก้ไขต่อ';

  @override
  String get fileSelectedWillUpload =>
      'เลือกไฟล์แล้ว จะอัปโหลดเมื่อเผยแพร่สูตร';

  @override
  String get cannotOpenSelectedFile => 'ไม่สามารถเปิดไฟล์ที่เลือกได้';

  @override
  String fileTooLarge(int maxMb) {
    return 'ไฟล์ต้องมีขนาดไม่เกิน $maxMb MB';
  }

  @override
  String get imageTypesOnly => 'รองรับไฟล์ JPG, PNG, WEBP หรือ GIF เท่านั้น';

  @override
  String get videoTypesOnly => 'รองรับไฟล์ MP4, WEBM หรือ MOV เท่านั้น';

  @override
  String fieldRequired(String field) {
    return 'กรอก$field';
  }

  @override
  String fieldMustBeNonNegative(String field) {
    return '$fieldต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป';
  }

  @override
  String fieldMustBeWholeNumber(String field, int minimum) {
    return '$fieldต้องเป็นจำนวนเต็มตั้งแต่ $minimum ขึ้นไป';
  }

  @override
  String get editRecipe => 'แก้ไขสูตรอาหาร';

  @override
  String get createRecipe => 'สร้างสูตรอาหาร';

  @override
  String get uploadingFiles => 'กำลังอัปโหลดไฟล์...';

  @override
  String get publishing => 'กำลังเผยแพร่...';

  @override
  String get saveChanges => 'บันทึกการแก้ไข';

  @override
  String get publishRecipe => 'เผยแพร่สูตรอาหาร';

  @override
  String get uploading => 'กำลังอัปโหลด...';

  @override
  String get publish => 'เผยแพร่';

  @override
  String get yourRecipe => 'สูตรของคุณ';

  @override
  String get yourRecipeSubtitle => 'ชื่อเมนูและเรื่องราวสั้น ๆ';

  @override
  String get thaiName => 'ชื่อภาษาไทย';

  @override
  String get thaiNameHint => 'เช่น ผัดกะเพราไก่';

  @override
  String get recipeNameField => 'ชื่อสูตรอาหาร';

  @override
  String get englishName => 'ชื่อภาษาอังกฤษ';

  @override
  String get descriptionField => 'คำอธิบาย';

  @override
  String get descriptionHint => 'เล่าจุดเด่นหรือรสชาติของเมนูนี้';

  @override
  String get categories => 'หมวดหมู่';

  @override
  String get categoriesPickMany => 'เลือกได้มากกว่า 1 หมวด';

  @override
  String categoriesSelected(int count) {
    return 'เลือกแล้ว $count หมวด';
  }

  @override
  String get noCategories => 'ไม่มีหมวดหมู่ให้เลือก';

  @override
  String get searchCategoriesHint => 'ค้นหาหมวดหมู่...';

  @override
  String get coverPhoto => 'รูปตัวอย่างอาหาร';

  @override
  String get coverPhotoSubtitle => 'รูปหน้าปกที่ทุกคนจะเห็นก่อน';

  @override
  String get currentImage => 'รูปเดิม';

  @override
  String get showImageInCommunity => 'แสดงรูปในชุมชน';

  @override
  String get showImageInCommunityHint => 'โชว์รูปเล็กใต้โพสต์ในหน้าคอมมูนิตี้';

  @override
  String get chooseImage => 'เลือกรูปภาพ';

  @override
  String get imageRequirements => 'JPG, PNG, WEBP หรือ GIF ไม่เกิน 10 MB';

  @override
  String get changeImage => 'เปลี่ยนรูปภาพ';

  @override
  String get removeImage => 'ลบรูปภาพ';

  @override
  String get recipeDetails => 'รายละเอียดสูตร';

  @override
  String get recipeDetailsSubtitle => 'เวลา จำนวนที่เสิร์ฟ และความยาก';

  @override
  String get price => 'ราคา';

  @override
  String get baht => 'บาท';

  @override
  String get priceRequired => 'กรอกราคา';

  @override
  String get prepLabel => 'เตรียม';

  @override
  String get minutesUnit => 'นาที';

  @override
  String get prepTimeField => 'เวลาเตรียม';

  @override
  String get cookLabel => 'ปรุง';

  @override
  String get cookTimeField => 'เวลาปรุง';

  @override
  String get servings => 'จำนวนที่รับประทาน';

  @override
  String get servingsUnit => 'ที่';

  @override
  String get difficulty => 'ระดับความยาก';

  @override
  String get difficultyRequired => 'เลือกระดับความยาก';

  @override
  String get cookingSteps => 'ขั้นตอนการทำอาหาร';

  @override
  String get tapToEditSteps => 'แตะเพื่อแก้ไขหัวข้อและขั้นตอน';

  @override
  String get noStepGroupsYet => 'ยังไม่ได้เพิ่มหัวข้อขั้นตอน';

  @override
  String get statGroups => 'ชุด';

  @override
  String get statSteps => 'ขั้นตอน';

  @override
  String get editStepGroups => 'แก้ไขหัวข้อขั้นตอน';

  @override
  String get addStepGroups => 'เพิ่มหัวข้อขั้นตอน';

  @override
  String get recipeType => 'ประเภทสูตร';

  @override
  String get recipeTypeSubtitle => 'เปลี่ยนได้จนกว่าจะเผยแพร่';

  @override
  String get recipeTypeOfficial => 'Official (ขาย)';

  @override
  String get recipeTypeCommunity => 'Community (ฟรี)';

  @override
  String get mediaTypesOnly => 'รองรับไฟล์รูปภาพหรือวิดีโอเท่านั้น';

  @override
  String get minutesNonNegative => 'ใส่เวลาเป็นจำนวนนาทีตั้งแต่ 0';

  @override
  String get backAutoSave => 'กลับ (บันทึกอัตโนมัติ)';

  @override
  String get addStep => 'เพิ่มขั้นตอน';

  @override
  String stepNumber(int number) {
    return 'ขั้นตอนที่ $number';
  }

  @override
  String get deleteStep => 'ลบขั้นตอน';

  @override
  String get collapseDetails => 'พับรายละเอียด';

  @override
  String get expandDetails => 'ขยายรายละเอียด';

  @override
  String get subStepTitle => 'ชื่อขั้นตอนย่อย';

  @override
  String get subStepTitleHint => 'เช่น เตรียมหมูและเครื่องปรุง';

  @override
  String get instructions => 'วิธีทำ';

  @override
  String get instructionsHint => 'อธิบายสิ่งที่ต้องทำในขั้นตอนนี้';

  @override
  String get stepType => 'ชนิดขั้นตอน';

  @override
  String get stepTypeTip => 'เคล็ดลับ';

  @override
  String get stepTypeWarning => 'ข้อควรระวัง';

  @override
  String get stepTypeImage => 'รูปภาพ';

  @override
  String get stepTypeVideo => 'คลิปวิดีโอ';

  @override
  String get chooseMediaFile => 'เลือกไฟล์รูปภาพหรือวิดีโอ';

  @override
  String get timeLabel => 'เวลา';

  @override
  String get useExistingVideo => 'ใช้คลิปวิดีโอเดิม';

  @override
  String get changeFile => 'เปลี่ยนไฟล์';

  @override
  String get chooseImageOrVideo => 'เลือกรูปภาพหรือวิดีโอ';

  @override
  String get mediaRequirements => 'รูปไม่เกิน 10 MB · วิดีโอไม่เกิน 100 MB';

  @override
  String get enterGroupTitleFirst => 'กรอกหัวข้อขั้นตอนก่อนเพิ่มขั้นตอน';

  @override
  String get stepGroupTitle => 'หัวข้อขั้นตอน';

  @override
  String get stepGroupsHelp =>
      'แบ่งขั้นตอนเป็นชุด เช่น \"เตรียมวัตถุดิบ\" \"ปรุง\" \"จัดเสิร์ฟ\" แล้วแตะการ์ดเพื่อเพิ่มขั้นตอนย่อย กดย้อนกลับได้เลย ระบบบันทึกให้อัตโนมัติ';

  @override
  String get noStepGroupsTitle => 'ยังไม่มีหัวข้อขั้นตอน';

  @override
  String get noStepGroupsHint => 'เริ่มจากเพิ่มหัวข้อชุดแรกด้านล่าง';

  @override
  String get cookingDone => 'ทำอาหารเสร็จแล้ว!';

  @override
  String cookingDoneMessage(String recipe) {
    return 'คุณทำ $recipe ครบทุกขั้นตอนแล้ว';
  }

  @override
  String get backToRecipePage => 'กลับไปหน้าสูตรอาหาร';

  @override
  String get stepDone => 'เสร็จแล้ว';

  @override
  String stepOfTotal(int current, int total) {
    return 'ขั้นตอน $current จาก $total';
  }

  @override
  String get stepTypeVideoShort => 'วิดีโอ';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes นาที $seconds วินาที';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds วินาที';
  }

  @override
  String get stepHasNoVideo => 'ขั้นตอนนี้ยังไม่มีวิดีโอ';

  @override
  String get previousStep => 'ขั้นตอนก่อนหน้า';

  @override
  String get finishCooking => 'ทำอาหารเสร็จแล้ว';

  @override
  String get finishStep => 'เสร็จขั้นตอนนี้';

  @override
  String get cookingNow => 'กำลังทำอาหาร';

  @override
  String stepProgress(int current, int total) {
    return '$current / $total ขั้นตอน';
  }

  @override
  String get recipeHasNoSteps => 'สูตรนี้ยังไม่มีขั้นตอนการทำ';

  @override
  String get loadingVideo => 'กำลังโหลดวิดีโอ...';

  @override
  String videoPlayFailedDetails(String details) {
    return 'เล่นวิดีโอไม่ได้\n$details';
  }

  @override
  String get videoPlayFailed => 'ไม่สามารถเล่นวิดีโอนี้ได้';

  @override
  String get rewind10 => 'ย้อนกลับ 10 วินาที';

  @override
  String get pause => 'หยุดชั่วคราว';

  @override
  String get play => 'เล่น';

  @override
  String get forward10 => 'เดินหน้า 10 วินาที';

  @override
  String get unmute => 'เปิดเสียง';

  @override
  String get adjustVolume => 'ปรับเสียง';

  @override
  String get mute => 'ปิดเสียง';

  @override
  String get playbackSpeed => 'ความเร็วการเล่น';

  @override
  String get rotateScreen => 'หมุนหน้าจอ';

  @override
  String get exitFullscreen => 'ออกจากเต็มจอ';

  @override
  String get fullscreen => 'เต็มจอ';

  @override
  String get volumeDown => 'ลดเสียง';

  @override
  String get volumeUp => 'เพิ่มเสียง';

  @override
  String groupNumber(int number) {
    return 'ชุดที่ $number';
  }

  @override
  String stepsCount(int count) {
    return '$count ขั้นตอน';
  }

  @override
  String get collapseSteps => 'พับขั้นตอน';

  @override
  String get showSteps => 'แสดงขั้นตอน';

  @override
  String get deleteStepGroup => 'ลบหัวข้อขั้นตอน';

  @override
  String get noSubStepsHint => 'ยังไม่มีขั้นตอนย่อย แตะการ์ดเพื่อเพิ่ม';

  @override
  String get untitledStep => 'ยังไม่มีชื่อขั้นตอนย่อย';

  @override
  String get errorInvalidResponse => 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง';

  @override
  String get errorTimeout => 'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่อีกครั้ง';

  @override
  String errorConnection(String details) {
    return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $details';
  }

  @override
  String errorActionFailed(String action, int statusCode) {
    return '$actionไม่สำเร็จ (HTTP $statusCode)';
  }

  @override
  String get loginFailed => 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอีเมลและรหัสผ่าน';

  @override
  String loadBannersFailed(int statusCode) {
    return 'โหลดแบนเนอร์ไม่สำเร็จ (HTTP $statusCode)';
  }

  @override
  String get loadCategoriesFailed => 'โหลดหมวดหมู่ไม่สำเร็จ';

  @override
  String get actionLoadCart => 'โหลดตะกร้า';

  @override
  String get actionOpenCart => 'เปิดตะกร้า';

  @override
  String get actionAddToCart => 'เพิ่มสูตรนี้ลงตะกร้า';

  @override
  String get actionRemoveFromCart => 'เอาสูตรนี้ออกจากตะกร้า';

  @override
  String get actionClearCart => 'ล้างตะกร้า';

  @override
  String get cartSignInRequired => 'กรุณาเข้าสู่ระบบเพื่อใช้ตะกร้า';

  @override
  String get chatInvalidResponse => 'AI ตอบกลับมาในรูปแบบที่ไม่ถูกต้อง';

  @override
  String get chatBuyFirst => 'ต้องซื้อสูตรนี้ก่อนจึงจะถาม AI ได้';

  @override
  String get chatImageTooLarge => 'รูปใหญ่เกินไป (ไม่เกิน 5MB)';

  @override
  String get chatUnavailable => 'AI ไม่พร้อมใช้งานชั่วคราว ลองใหม่อีกครั้ง';

  @override
  String errorHttp(int statusCode) {
    return 'เกิดข้อผิดพลาด (HTTP $statusCode)';
  }

  @override
  String get chatTimeout => 'AI ตอบช้าเกินไป ลองใหม่อีกครั้ง';

  @override
  String get actionLoadFavorites => 'โหลดรายการโปรด';

  @override
  String get actionSaveRecipe => 'บันทึกสูตรนี้';

  @override
  String get actionUnsaveRecipe => 'เอาสูตรนี้ออกจากรายการโปรด';

  @override
  String get favoriteSignInRequired => 'กรุณาเข้าสู่ระบบเพื่อบันทึกสูตร';

  @override
  String get createRecipeFailed => 'สร้างสูตรอาหารไม่สำเร็จ';

  @override
  String get updateRecipeFailed => 'แก้ไขสูตรอาหารไม่สำเร็จ';

  @override
  String get loadRecipesFailed => 'โหลดสูตรอาหารไม่สำเร็จ';

  @override
  String get recipeNotFoundShort => 'ไม่พบเมนูนี้';

  @override
  String get loadRecipeFailed => 'โหลดสูตรอาหารไม่สำเร็จ';

  @override
  String get searchRecipesFailed => 'ค้นหาสูตรอาหารไม่สำเร็จ';

  @override
  String get deleteRecipeFailed => 'ลบสูตรอาหารไม่สำเร็จ';

  @override
  String get actionLoadProfile => 'โหลดโปรไฟล์';

  @override
  String get actionSaveProfile => 'บันทึกโปรไฟล์';

  @override
  String get signInRequired => 'กรุณาเข้าสู่ระบบ';

  @override
  String get signInBeforeCheckout => 'กรุณาเข้าสู่ระบบก่อนชำระเงิน';

  @override
  String mockPaymentFailedHttp(int statusCode) {
    return 'ชำระเงินจำลองไม่สำเร็จ (HTTP $statusCode)';
  }

  @override
  String get purchaseInvalidResult => 'ผลการชำระเงินจากเซิร์ฟเวอร์ไม่ถูกต้อง';

  @override
  String get purchaseTimeout => 'หมดเวลารอการยืนยันการชำระเงิน';

  @override
  String get actionLoadComments => 'โหลดความคิดเห็น';

  @override
  String get actionCheckCommentPermission => 'ตรวจสอบสิทธิ์แสดงความคิดเห็น';

  @override
  String get actionSaveComment => 'บันทึกความคิดเห็น';

  @override
  String get actionUpdateComment => 'แก้ไขความคิดเห็น';

  @override
  String get actionDeleteComment => 'ลบความคิดเห็น';

  @override
  String get editOwnCommentOnly => 'แก้ไขได้เฉพาะความคิดเห็นของตัวเอง';

  @override
  String get deleteOwnCommentOnly => 'ลบได้เฉพาะความคิดเห็นของตัวเอง';

  @override
  String get commentSignInRequired => 'กรุณาเข้าสู่ระบบเพื่อแสดงความคิดเห็น';

  @override
  String errorNoPermission(String action) {
    return 'คุณไม่มีสิทธิ์$action';
  }

  @override
  String actionLoadCollection(String collection) {
    return 'โหลด$collection';
  }

  @override
  String get librarySignInRequired => 'กรุณาเข้าสู่ระบบเพื่อดูสูตรของคุณ';

  @override
  String get actionLoadReviews => 'โหลดรีวิว';

  @override
  String get actionLoadYourReview => 'โหลดรีวิวของคุณ';

  @override
  String get actionSaveYourReview => 'บันทึกรีวิวของคุณ';

  @override
  String get reviewSignInRequired => 'กรุณาเข้าสู่ระบบเพื่อรีวิวสูตร';

  @override
  String get buyToRate => 'ต้องซื้อสูตรนี้ก่อนจึงจะให้คะแนนได้';

  @override
  String get uploadSignInRequired => 'กรุณาเข้าสู่ระบบก่อนอัปโหลด';

  @override
  String get uploadPrepareFailed => 'เตรียมการอัปโหลดไม่สำเร็จ';

  @override
  String uploadFailedHttp(int statusCode) {
    return 'อัปโหลดไฟล์ไม่สำเร็จ (HTTP $statusCode)';
  }

  @override
  String get uploadVerifyFailed => 'ตรวจสอบไฟล์ที่อัปโหลดไม่สำเร็จ';

  @override
  String get commentEmpty => 'ความคิดเห็นต้องไม่ว่าง';

  @override
  String get signInAgain => 'กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get roleCreator => 'ผู้สร้างสูตร';

  @override
  String get roleAdmin => 'ผู้ดูแลระบบ';

  @override
  String get roleFoodLover => 'คนรักอาหาร';

  @override
  String get faqCreateTitle => 'สร้างสูตรอาหารยังไง';

  @override
  String get faqCreateBody =>
      'กดปุ่ม + ได้ 2 ที่\n• หน้าคอมมูนิตี้: สร้างสูตรแจกฟรีให้ทุกคนดู\n• โปรไฟล์ → สูตรของฉัน: สร้างสูตรแบบ Official ตั้งราคาขายได้\nกรอกชื่อ รูปปก รายละเอียด หมวดหมู่ และขั้นตอน แล้วกด \"เผยแพร่สูตรอาหาร\"';

  @override
  String get faqDraftTitle => 'ยังเขียนสูตรไม่เสร็จ เก็บไว้ก่อนได้ไหม';

  @override
  String get faqDraftBody =>
      'ได้ กดย้อนกลับระหว่างสร้างสูตรแล้วเลือก \"บันทึกฉบับร่าง\" สูตรจะอยู่ใน โปรไฟล์ → ฉบับร่าง กลับมาเขียนต่อหรือเผยแพร่ทีหลังได้';

  @override
  String get faqEditTitle => 'แก้ไขหรือลบสูตรของฉัน';

  @override
  String get faqEditBody =>
      'เปิดสูตรแล้วกดปุ่ม ⋮ มุมขวาบน เลือก \"แก้ไข\" หรือ \"ลบสูตรอาหาร\"\nสูตร Official ที่เผยแพร่แล้วแก้ไขไม่ได้ (ลบได้)';

  @override
  String get faqBuyTitle => 'ซื้อสูตรยังไง';

  @override
  String get faqBuyBody =>
      'เปิดสูตรแล้วกด \"ซื้อเลย\" เพื่อใส่ตะกร้า จากนั้นเข้าตะกร้าแล้วกดชำระเงิน สูตรที่ซื้อแล้วดูได้ที่ โปรไฟล์ → ซื้อแล้ว';

  @override
  String get faqAiTitle => 'ถาม AI เกี่ยวกับสูตรได้ยังไง';

  @override
  String get faqAiBody =>
      'ปุ่ม \"ถาม AI เกี่ยวกับสูตรนี้\" จะขึ้นในสูตรที่คุณซื้อแล้วหรือเป็นเจ้าของ พิมพ์คำถามหรือแนบรูปอาหารได้ คำตอบจาก AI อาจไม่ถูกต้องทุกครั้ง โปรดใช้วิจารณญาณ โดยเฉพาะเรื่องการแพ้อาหาร';

  @override
  String get faqRateTitle => 'ให้คะแนนและรีวิวสูตร';

  @override
  String get faqRateBody =>
      'ให้คะแนนได้เฉพาะสูตรที่ซื้อแล้ว กด \"ให้คะแนน\" ในหน้าสูตร แก้คะแนนทีหลังได้ ส่วนสูตรในคอมมูนิตี้แสดงความคิดเห็นได้เลย';

  @override
  String get faqProfileTitle => 'เปลี่ยนรูปโปรไฟล์หรือชื่อ';

  @override
  String get faqProfileBody =>
      'โปรไฟล์ → แก้ไขโปรไฟล์ เปลี่ยนรูปและชื่อที่แสดงได้ อีเมลใช้เข้าสู่ระบบจึงเปลี่ยนไม่ได้';

  @override
  String get faqForgotTitle => 'ลืมรหัสผ่าน';

  @override
  String get faqForgotBody =>
      'ตอนนี้ยังไม่มีระบบรีเซ็ตรหัสผ่านผ่านอีเมล ถ้ายังเข้าสู่ระบบอยู่ เปลี่ยนรหัสได้ที่ ตั้งค่า → เปลี่ยนรหัสผ่าน ถ้าเข้าไม่ได้แล้วโปรดติดต่อทีมงาน';

  @override
  String get faqLostTitle => 'มือถือหาย หรือสงสัยว่ามีคนใช้บัญชีของฉัน';

  @override
  String get faqLostBody =>
      'ตั้งค่า → ออกจากระบบทุกอุปกรณ์ แล้วเปลี่ยนรหัสผ่าน ทุกเครื่องที่เข้าสู่ระบบอยู่จะหลุดออกทันที';

  @override
  String get privacyCollectTitle => 'ข้อมูลที่เราเก็บ';

  @override
  String get privacyCollectBody =>
      '• ข้อมูลบัญชี: อีเมล ชื่อที่แสดง รูปโปรไฟล์ และรหัสผ่าน (เก็บแบบเข้ารหัสทางเดียว ทีมงานอ่านรหัสผ่านของคุณไม่ได้)\n• เนื้อหาที่คุณสร้าง: สูตรอาหาร รูปภาพ วิดีโอ คอมเมนต์ และรีวิว\n• การใช้งานในแอป: รายการโปรด ตะกร้า และประวัติการซื้อสูตร';

  @override
  String get privacyVisibleTitle => 'ข้อมูลที่คนอื่นมองเห็น';

  @override
  String get privacyVisibleBody =>
      'ชื่อที่แสดง รูปโปรไฟล์ สูตรที่เผยแพร่ คอมเมนต์ และรีวิวของคุณ ผู้ใช้คนอื่นมองเห็นได้ ส่วนอีเมล รายการโปรด ตะกร้า และประวัติการซื้อ เห็นได้เฉพาะคุณ';

  @override
  String get privacyAiTitle => 'แชทถาม AI';

  @override
  String get privacyAiBody =>
      'คำถามและรูปที่คุณส่งในแชท AI จะถูกส่งไปยังผู้ให้บริการ AI ภายนอกเพื่อสร้างคำตอบ บทสนทนาถูกจำไว้ชั่วคราวและถูกลืมเมื่อไม่มีการใช้งานประมาณ 20 นาที เราไม่เก็บรูปที่ส่งในแชท';

  @override
  String get privacyDeviceTitle => 'ข้อมูลบนเครื่องของคุณ';

  @override
  String get privacyDeviceBody =>
      'แอปเก็บข้อมูลเข้าสู่ระบบไว้ในพื้นที่ปลอดภัยของเครื่อง และเก็บรูปภาพที่เคยโหลดไว้ในเครื่องเพื่อให้เปิดได้เร็วขึ้น ข้อมูลเข้าสู่ระบบถูกลบเมื่อคุณออกจากระบบ';

  @override
  String get privacyDeleteTitle => 'การลบข้อมูล';

  @override
  String get privacyDeleteBody =>
      'ลบบัญชีได้ที่ ตั้งค่า → ลบบัญชี อีเมล ชื่อ รูปโปรไฟล์ รายการโปรด และตะกร้าจะถูกลบ สูตรของคุณจะไม่แสดงอีก ยกเว้นผู้ที่ซื้อไปแล้ว คอมเมนต์และรีวิวยังอยู่โดยแสดงเป็น \"ผู้ใช้ที่ลบบัญชีแล้ว\"';

  @override
  String get privacyContactTitle => 'ติดต่อเรา';

  @override
  String get privacyContactBody =>
      'มีคำถามเรื่องข้อมูลส่วนตัว ติดต่อทีมงานได้ที่หน้าช่วยเหลือและติดต่อ';

  @override
  String get termsAccountTitle => 'บัญชีผู้ใช้';

  @override
  String get termsAccountBody =>
      'คุณต้องรับผิดชอบการรักษารหัสผ่านและการใช้งานทั้งหมดที่เกิดจากบัญชีของคุณ ถ้าสงสัยว่ามีผู้อื่นใช้บัญชี ให้ออกจากระบบทุกอุปกรณ์และเปลี่ยนรหัสผ่านทันที';

  @override
  String get termsContentTitle => 'เนื้อหาที่คุณโพสต์';

  @override
  String get termsContentBody =>
      'สูตร รูป วิดีโอ คอมเมนต์ และรีวิวที่คุณโพสต์ต้องเป็นของคุณหรือคุณมีสิทธิ์เผยแพร่ ห้ามโพสต์เนื้อหาที่ผิดกฎหมาย ละเมิดลิขสิทธิ์ หรือทำร้ายผู้อื่น ทีมงานอาจลบเนื้อหาหรือระงับบัญชีที่ฝ่าฝืน';

  @override
  String get termsPurchaseTitle => 'การซื้อสูตร';

  @override
  String get termsPurchaseBody =>
      'สูตรที่ซื้อแล้วเปิดดูได้ในแอปเพื่อใช้ส่วนตัว ห้ามคัดลอกหรือนำไปเผยแพร่ต่อโดยไม่ได้รับอนุญาตจากผู้สร้างสูตร';

  @override
  String get termsAiTitle => 'คำตอบจาก AI';

  @override
  String get termsAiBody =>
      'คำแนะนำจาก AI ใช้ประกอบการทำอาหารเท่านั้น อาจไม่ถูกต้องหรือไม่ครบถ้วน โปรดตรวจสอบเองก่อนใช้ โดยเฉพาะเรื่องการแพ้อาหารและความปลอดภัยของอาหาร';

  @override
  String get termsCloseTitle => 'การปิดบัญชี';

  @override
  String get termsCloseBody => 'คุณลบบัญชีได้ทุกเมื่อที่ ตั้งค่า → ลบบัญชี';

  @override
  String get termsChangesTitle => 'การเปลี่ยนแปลงข้อกำหนด';

  @override
  String get termsChangesBody =>
      'ข้อกำหนดนี้อาจมีการปรับปรุง การใช้งานแอปต่อหลังมีการเปลี่ยนแปลง ถือว่าคุณยอมรับข้อกำหนดฉบับใหม่';

  @override
  String get settingsGeneral => 'ทั่วไป';

  @override
  String get language => 'ภาษา';

  @override
  String get chooseLanguage => 'เลือกภาษา';

  @override
  String get englishNameHint => 'เช่น Spicy basil chicken';

  @override
  String get englishNameHelper => 'ไม่บังคับ ใช้แสดงเมื่อผู้ใช้เลือกภาษาอังกฤษ';

  @override
  String get statRecipeRating => 'คะแนนสูตร';

  @override
  String reviewsCountShort(int count) {
    return '$count รีวิว';
  }

  @override
  String get statSales => 'ขายได้';

  @override
  String get statOfficialSaves => 'บันทึกสูตร Official';

  @override
  String get statCommunitySaves => 'บันทึกสูตรคอมมูนิตี้';

  @override
  String get statSavesReceived => 'ถูกบันทึก';

  @override
  String get statCommentsReceived => 'ความคิดเห็น';

  @override
  String get statReviewsWritten => 'รีวิวที่เขียน';

  @override
  String get recentPurchases => 'ซื้อล่าสุด';

  @override
  String get continueDraftTitle => 'เขียนต่อจากที่ค้างไว้';

  @override
  String continueDraftSubtitle(int count) {
    return 'มีฉบับร่าง $count สูตร';
  }

  @override
  String get firstRecipeTitle => 'แบ่งปันสูตรแรกของคุณ';

  @override
  String get firstRecipeSubtitleCreator =>
      'สร้างสูตร Official และตั้งราคาขายได้';

  @override
  String get firstRecipeSubtitleUser => 'สร้างสูตรแจกฟรีให้ทุกคนในคอมมูนิตี้';

  @override
  String get authTagline => 'วันนี้ทำอะไรอร่อยดี';
}
