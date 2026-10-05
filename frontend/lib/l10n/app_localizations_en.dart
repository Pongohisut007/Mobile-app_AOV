// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navCommunity => 'Community';

  @override
  String get navProfile => 'Profile';

  @override
  String get recommendedTitle => 'Recommended';

  @override
  String get seeMore => 'See more';

  @override
  String get allRecipesTitle => 'All recipes';

  @override
  String get searchRecipeHint => 'Search for a recipe';

  @override
  String get ratingNew => 'New';

  @override
  String get favoriteRemoveTooltip => 'Remove from favorites';

  @override
  String get favoriteAddTooltip => 'Save to favorites';

  @override
  String get loading => 'Loading...';

  @override
  String get noRecipesInCategory => 'No recipes in this category yet';

  @override
  String noRecipesNamed(String query) {
    return 'No recipes named \"$query\"';
  }

  @override
  String get loadMoreRecipesFailed => 'Couldn\'t load more recipes. Try again';

  @override
  String get cartFallbackTitle => 'This recipe';

  @override
  String cartAdded(String title) {
    return 'Added $title to cart';
  }

  @override
  String cartAlreadyIn(String title) {
    return '$title is already in your cart';
  }

  @override
  String cartAddFailed(String title) {
    return 'Couldn\'t add $title to cart';
  }

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get categoryAll => 'All';

  @override
  String get createRecipeTooltip => 'Create recipe';

  @override
  String get searchTooltip => 'Search';

  @override
  String get closeSearchTooltip => 'Close search';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get noPostsInCategory => 'No posts in this category yet';

  @override
  String noPostsNamed(String query) {
    return 'No posts named \"$query\"';
  }

  @override
  String get loadFailedTryAgain => 'Couldn\'t load. Try again';

  @override
  String get showMore => 'Show more';

  @override
  String get noData => 'No data available';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get anonymousUser => 'User';

  @override
  String get viewCommentsTooltip => 'View comments';

  @override
  String get signIn => 'Sign in';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get yourKitchenTitle => 'Your kitchen';

  @override
  String get yourKitchenSubtitle => 'Everything you cook and collect';

  @override
  String appVersionFooter(String appName, String version) {
    return '$appName · Version $version';
  }

  @override
  String get profileHeaderSubtitle => 'Your recipes, orders and preferences';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get cartTooltip => 'Cart';

  @override
  String get myRecipes => 'My recipes';

  @override
  String myRecipesDetail(int count) {
    return '$count published';
  }

  @override
  String get purchasedRecipes => 'Purchased';

  @override
  String purchasedDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get favorites => 'Favorites';

  @override
  String favoritesDetail(int count) {
    return '$count saved';
  }

  @override
  String get drafts => 'Drafts';

  @override
  String draftsDetail(int count) {
    return '$count unfinished';
  }

  @override
  String get guest => 'Guest';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get profileLoadFailed => 'Could not load your profile';

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get passwordChangedOthersSignedOut =>
      'Password changed. Other devices have been signed out';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'You can sign back in at any time to access your recipes.';

  @override
  String get signOutAllTitle => 'Sign out of all devices?';

  @override
  String get signOutAllMessage =>
      'Every device signed in to this account, including this one, will be signed out immediately';

  @override
  String get signOutAllAction => 'Sign out everywhere';

  @override
  String get signOutAllDevices => 'Sign out of all devices';

  @override
  String get signOutAllDevicesHint =>
      'Use this if your phone is lost or you suspect someone is using your account';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get changePassword => 'Change password';

  @override
  String get settingsHelpAndTerms => 'Help & terms';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get aboutApp => 'About';

  @override
  String aboutAppSubtitle(String version) {
    return 'Version $version · Open source licenses';
  }

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint =>
      'Close your account and erase personal data. This can\'t be undone';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get contactTeam => 'Contact the team';

  @override
  String get emailCopied => 'Email copied';

  @override
  String get noAccountPrompt => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get haveAccountPrompt => 'Already have an account? ';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get emailRequired => 'Please enter your email address';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordTooLong => 'Password must be 72 characters or less';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orSignInWith => 'or sign in with';

  @override
  String get orSignUpWith => 'or sign up with';

  @override
  String get acceptTermsRequired =>
      'Please accept the terms and privacy policy.';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'Enter your display name';

  @override
  String get displayNameRequired => 'Please enter your display name';

  @override
  String get displayNameTooLong =>
      'Display name must be 150 characters or less';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get termsAgreePrefix => 'I agree with the ';

  @override
  String get termsAgreeUserAgreement => 'User Agreement';

  @override
  String get termsAgreeAnd => ' and ';

  @override
  String get termsAgreePrivacy => 'Privacy Policy';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get saving => 'Saving...';

  @override
  String get currentPassword => 'Current password';

  @override
  String get currentPasswordRequired => 'Enter your current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordLengthHelper => '8-72 characters';

  @override
  String get newPasswordSameAsOld =>
      'New password must be different from the current one';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get newPasswordsDoNotMatch => 'New passwords do not match';

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get deleteAccountPermanently => 'Delete account permanently';

  @override
  String get deleteIrreversible => 'This can\'t be undone';

  @override
  String get deleteBulletSignOut =>
      'You\'ll be signed out everywhere and can\'t sign in to this account again';

  @override
  String get deleteBulletPersonalData =>
      'Your name, profile photo and email are erased. You can sign up again with the same email, but it will be a new account';

  @override
  String get deleteBulletRecipes =>
      'Recipes you created will be hidden from everyone, except people who already bought them';

  @override
  String get deleteBulletLibrary =>
      'Your favorites, cart and purchased recipes will be gone';

  @override
  String get deleteBulletComments =>
      'Comments and reviews stay, but show as \"Deleted user\"';

  @override
  String get confirmWithPassword => 'Confirm with your password';

  @override
  String get passwordEnter => 'Enter your password';

  @override
  String get deleteUnderstand =>
      'I understand that deleting my account can\'t be undone';

  @override
  String imageOpenFailed(String error) {
    return 'Couldn\'t open the image: $error';
  }

  @override
  String get save => 'Save';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get emailCannotChange =>
      'Your email is used to sign in and can\'t be changed';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get priceFree => 'Free';

  @override
  String get mockIapDisabled =>
      'Mock purchases are turned off. Please connect Google Play Billing';

  @override
  String get mockPaymentCancelled => 'Simulated a cancelled payment';

  @override
  String get mockPaymentFailed => 'Simulated a failed payment';

  @override
  String get mockBillingTitle => 'Google Play Billing — mock mode';

  @override
  String get mockBillingSubtitle =>
      'Choose the result to test. No real money is charged';

  @override
  String get mockPaySuccess => 'Simulate success';

  @override
  String get mockPayFail => 'Simulate failure';

  @override
  String get mockUserCancel => 'Simulate user cancel';

  @override
  String get clearCartTitle => 'Clear cart?';

  @override
  String get clearCartMessage => 'This removes every recipe from your cart.';

  @override
  String get clear => 'Clear';

  @override
  String get cartTitle => 'Cart';

  @override
  String get clearCartTooltip => 'Clear cart';

  @override
  String get cartLoadFailed => 'Could not load your cart.';

  @override
  String get selectAll => 'Select all';

  @override
  String selectedOfTotal(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyMessage => 'Recipes you add will show up here.';

  @override
  String get browseRecipes => 'Browse recipes';

  @override
  String selectItemForCheckout(String title) {
    return 'Select $title for checkout';
  }

  @override
  String get remove => 'Remove';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get paymentFailedTitle => 'Payment failed';

  @override
  String get purchaseIncomplete => 'Not all recipes were purchased';

  @override
  String purchasePartialMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes were purchased before the error.',
      one: '1 recipe was purchased before the error.',
    );
    return '$_temp0 The rest are still in your cart';
  }

  @override
  String get retry => 'Retry';

  @override
  String get backToCart => 'Back to cart';

  @override
  String get paymentSuccessTitle => 'Payment successful';

  @override
  String get purchaseSuccess => 'Purchase complete!';

  @override
  String purchaseUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unlocked $count recipes',
      one: 'Unlocked 1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get mockPaymentNotice =>
      'This was a simulated payment. No real money was charged';

  @override
  String get viewPurchasedRecipes => 'View purchased recipes';

  @override
  String get backToHome => 'Back to home';

  @override
  String get checkoutNow => 'Checkout now';

  @override
  String get buyNow => 'Buy now';

  @override
  String get recipeNotFound => 'This recipe could not be found';

  @override
  String get startCooking => 'Start cooking';

  @override
  String get deleteRecipe => 'Delete recipe';

  @override
  String get deleteRecipeConfirm =>
      'Do you want to delete this recipe?\nAll related data will be deleted too';

  @override
  String get delete => 'Delete';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get goBack => 'Go back';

  @override
  String get description => 'Description';

  @override
  String get edit => 'Edit';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get infoPrep => 'prep';

  @override
  String get infoCook => 'cook';

  @override
  String get infoServings => 'servings';

  @override
  String get infoLevel => 'level';

  @override
  String get event => 'Event';

  @override
  String get details => 'Details';

  @override
  String get eventNoDetails => 'No details for this event yet';

  @override
  String periodStarts(String date) {
    return 'Starts $date';
  }

  @override
  String periodEnds(String date) {
    return 'Until $date';
  }

  @override
  String get starLabel1 => 'Very bad';

  @override
  String get starLabel2 => 'Fair';

  @override
  String get starLabel3 => 'Good';

  @override
  String get starLabel4 => 'Very good';

  @override
  String get starLabel5 => 'Excellent!';

  @override
  String get rateThisRecipe => 'Rate this recipe';

  @override
  String get rateDialogSubtitle => 'Your feedback helps us make better recipes';

  @override
  String get tapStarsToRate => 'Tap the stars to rate';

  @override
  String get whatDidYouLike => 'What did you like?';

  @override
  String get tellMore => 'Tell us more ';

  @override
  String get optional => '(optional)';

  @override
  String get reviewCommentHint => 'How did this recipe turn out for you?';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get updateRating => 'Update rating';

  @override
  String get thanksForRating => 'Thanks for rating!';

  @override
  String get ratingAddedMessage =>
      'Your review was added to the recipe\nYou can change it anytime with \"Edit rating\"';

  @override
  String get backToRecipe => 'Back to recipe';

  @override
  String get close => 'Close';

  @override
  String get ratingLoadFailed => 'Couldn\'t load ratings';

  @override
  String get rate => 'Rate';

  @override
  String get editRating => 'Edit rating';

  @override
  String get latestReviews => 'Latest reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get ratingsAndReviews => 'Ratings & reviews';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String fromReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'from $count reviews',
      one: 'from 1 review',
    );
    return '$_temp0';
  }

  @override
  String starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get allReviews => 'All reviews';

  @override
  String get averageRating => 'Average rating';

  @override
  String get tagTasty => 'Tasty';

  @override
  String get tagEasy => 'Easy to make';

  @override
  String get tagSpicyRight => 'Just the right spice';

  @override
  String get tagEasyIngredients => 'Easy-to-find ingredients';

  @override
  String get commentMore => '...more';

  @override
  String get commentLess => '  less';

  @override
  String get actionFailed => 'Something went wrong';

  @override
  String get buyToComment => 'Buy this recipe to join the conversation';

  @override
  String get comments => 'Comments';

  @override
  String get commentsLoadFailed => 'Couldn\'t load comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get viewMoreComments => 'View more comments';

  @override
  String get loadMoreCommentsAgain => 'Try loading more comments again';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get deleteCommentConfirm => 'Delete this comment?';

  @override
  String get editComment => 'Edit comment';

  @override
  String get writeCommentHint => 'Write a comment';

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get sendComment => 'Send comment';

  @override
  String get manageComment => 'Comment options';

  @override
  String get askAiAboutRecipe => 'Ask AI about this recipe';

  @override
  String get pickFromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get newChat => 'New chat';

  @override
  String get chatEmptyHint =>
      'Ask anything about this recipe\ne.g. \"What can I use instead of fish sauce?\"';

  @override
  String get aiTyping => 'AI is typing...';

  @override
  String get attachImage => 'Attach image';

  @override
  String get chatInputHint => 'Type a question...';

  @override
  String get chatImageHint => 'Ask about this image (optional)';

  @override
  String openEditorFailed(String error) {
    return 'Could not open recipe editor: $error';
  }

  @override
  String get collectionEmptyMyRecipes => 'You have not published a recipe yet.';

  @override
  String get collectionEmptyPurchased => 'You have not purchased a recipe yet.';

  @override
  String get collectionEmptyFavorites => 'Your saved recipes will appear here.';

  @override
  String get collectionEmptyDrafts => 'You have no unfinished recipes.';

  @override
  String get pickCoverBeforePublish => 'Choose a cover photo before publishing';

  @override
  String get pickAtLeastOneCategory => 'Choose at least one category';

  @override
  String get addStepsBeforePublish => 'Add cooking steps before publishing';

  @override
  String get completeAllSteps => 'Fill in the title and details for every step';

  @override
  String defaultSectionTitle(int number) {
    return 'Step group $number';
  }

  @override
  String get draftRecipeTitle => 'Draft recipe';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get saveDraftBeforeLeaving => 'Save a draft before leaving?';

  @override
  String get saveDraftBeforeLeavingMessage =>
      'What you\'ve entered will be kept in Drafts on your Profile';

  @override
  String get stay => 'Stay';

  @override
  String get leaveWithoutSaving => 'Leave without saving';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get discardEditsTitle => 'Discard your edits?';

  @override
  String get discardEditsMessage => 'Unsaved changes will be lost';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get fileSelectedWillUpload =>
      'File selected. It will upload when you publish';

  @override
  String get cannotOpenSelectedFile => 'The selected file couldn\'t be opened';

  @override
  String fileTooLarge(int maxMb) {
    return 'Files must be $maxMb MB or smaller';
  }

  @override
  String get imageTypesOnly => 'Only JPG, PNG, WEBP or GIF files are supported';

  @override
  String get videoTypesOnly => 'Only MP4, WEBM or MOV files are supported';

  @override
  String fieldRequired(String field) {
    return 'Enter $field';
  }

  @override
  String fieldMustBeNonNegative(String field) {
    return '$field must be 0 or more';
  }

  @override
  String fieldMustBeWholeNumber(String field, int minimum) {
    return '$field must be a whole number of $minimum or more';
  }

  @override
  String get editRecipe => 'Edit recipe';

  @override
  String get createRecipe => 'Create recipe';

  @override
  String get uploadingFiles => 'Uploading files...';

  @override
  String get publishing => 'Publishing...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get publishRecipe => 'Publish recipe';

  @override
  String get uploading => 'Uploading...';

  @override
  String get publish => 'Publish';

  @override
  String get yourRecipe => 'Your recipe';

  @override
  String get yourRecipeSubtitle => 'Recipe name and a short story';

  @override
  String get thaiName => 'Thai name';

  @override
  String get thaiNameHint => 'e.g. ผัดกะเพราไก่';

  @override
  String get recipeNameField => 'the recipe name';

  @override
  String get englishName => 'English name';

  @override
  String get descriptionField => 'Description';

  @override
  String get descriptionHint => 'What makes this dish special?';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesPickMany => 'You can pick more than one';

  @override
  String categoriesSelected(int count) {
    return '$count selected';
  }

  @override
  String get noCategories => 'No categories available';

  @override
  String get searchCategoriesHint => 'Search categories...';

  @override
  String get coverPhoto => 'Cover photo';

  @override
  String get coverPhotoSubtitle => 'The first thing everyone sees';

  @override
  String get currentImage => 'Current image';

  @override
  String get showImageInCommunity => 'Show image in community';

  @override
  String get showImageInCommunityHint =>
      'Show a small image under the post in Community';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get imageRequirements => 'JPG, PNG, WEBP or GIF up to 10 MB';

  @override
  String get changeImage => 'Change image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get recipeDetails => 'Recipe details';

  @override
  String get recipeDetailsSubtitle => 'Time, servings and difficulty';

  @override
  String get price => 'Price';

  @override
  String get baht => 'baht';

  @override
  String get priceRequired => 'Enter a price';

  @override
  String get prepLabel => 'Prep';

  @override
  String get minutesUnit => 'min';

  @override
  String get prepTimeField => 'Prep time';

  @override
  String get cookLabel => 'Cook';

  @override
  String get cookTimeField => 'Cook time';

  @override
  String get servings => 'Servings';

  @override
  String get servingsUnit => 'servings';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get difficultyRequired => 'Choose a difficulty';

  @override
  String get cookingSteps => 'Cooking steps';

  @override
  String get tapToEditSteps => 'Tap to edit groups and steps';

  @override
  String get noStepGroupsYet => 'No step groups yet';

  @override
  String get statGroups => 'groups';

  @override
  String get statSteps => 'steps';

  @override
  String get editStepGroups => 'Edit step groups';

  @override
  String get addStepGroups => 'Add step groups';

  @override
  String get recipeType => 'Recipe type';

  @override
  String get recipeTypeSubtitle => 'You can change this until you publish';

  @override
  String get recipeTypeOfficial => 'Official (paid)';

  @override
  String get recipeTypeCommunity => 'Community (free)';

  @override
  String get mediaTypesOnly => 'Only image or video files are supported';

  @override
  String get minutesNonNegative => 'Enter the time in minutes (0 or more)';

  @override
  String get backAutoSave => 'Back (saves automatically)';

  @override
  String get addStep => 'Add step';

  @override
  String stepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get deleteStep => 'Delete step';

  @override
  String get collapseDetails => 'Collapse details';

  @override
  String get expandDetails => 'Expand details';

  @override
  String get subStepTitle => 'Step title';

  @override
  String get subStepTitleHint => 'e.g. Prepare the pork and seasoning';

  @override
  String get instructions => 'Instructions';

  @override
  String get instructionsHint => 'Describe what to do in this step';

  @override
  String get stepType => 'Step type';

  @override
  String get stepTypeTip => 'Tip';

  @override
  String get stepTypeWarning => 'Caution';

  @override
  String get stepTypeImage => 'Image';

  @override
  String get stepTypeVideo => 'Video clip';

  @override
  String get chooseMediaFile => 'Choose an image or video file';

  @override
  String get timeLabel => 'Time';

  @override
  String get useExistingVideo => 'Using the existing video';

  @override
  String get changeFile => 'Change file';

  @override
  String get chooseImageOrVideo => 'Choose an image or video';

  @override
  String get mediaRequirements => 'Images up to 10 MB · videos up to 100 MB';

  @override
  String get enterGroupTitleFirst => 'Enter a group title before adding steps';

  @override
  String get stepGroupTitle => 'Group title';

  @override
  String get stepGroupsHelp =>
      'Split the steps into groups such as \"Prep\", \"Cook\" and \"Serve\", then tap a card to add steps. Just go back when you\'re done — it saves automatically';

  @override
  String get noStepGroupsTitle => 'No step groups yet';

  @override
  String get noStepGroupsHint => 'Start by adding your first group below';

  @override
  String get cookingDone => 'You\'re done cooking!';

  @override
  String cookingDoneMessage(String recipe) {
    return 'You finished every step of $recipe';
  }

  @override
  String get backToRecipePage => 'Back to the recipe';

  @override
  String get stepDone => 'Done';

  @override
  String stepOfTotal(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepTypeVideoShort => 'Video';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String get stepHasNoVideo => 'This step has no video yet';

  @override
  String get previousStep => 'Previous step';

  @override
  String get finishCooking => 'Finish cooking';

  @override
  String get finishStep => 'Done with this step';

  @override
  String get cookingNow => 'Cooking now';

  @override
  String stepProgress(int current, int total) {
    return '$current / $total steps';
  }

  @override
  String get recipeHasNoSteps => 'This recipe has no steps yet';

  @override
  String get loadingVideo => 'Loading video...';

  @override
  String videoPlayFailedDetails(String details) {
    return 'Couldn\'t play the video\n$details';
  }

  @override
  String get videoPlayFailed => 'This video can\'t be played';

  @override
  String get rewind10 => 'Back 10 seconds';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get forward10 => 'Forward 10 seconds';

  @override
  String get unmute => 'Unmute';

  @override
  String get adjustVolume => 'Volume';

  @override
  String get mute => 'Mute';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get rotateScreen => 'Rotate screen';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get volumeDown => 'Volume down';

  @override
  String get volumeUp => 'Volume up';

  @override
  String groupNumber(int number) {
    return 'Group $number';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get collapseSteps => 'Hide steps';

  @override
  String get showSteps => 'Show steps';

  @override
  String get deleteStepGroup => 'Delete step group';

  @override
  String get noSubStepsHint => 'No steps yet. Tap the card to add some';

  @override
  String get untitledStep => 'Untitled step';

  @override
  String get errorInvalidResponse => 'The server returned an invalid response.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String errorConnection(String details) {
    return 'Could not connect to the server: $details';
  }

  @override
  String errorActionFailed(String action, int statusCode) {
    return 'Could not $action (HTTP $statusCode).';
  }

  @override
  String get loginFailed =>
      'Login failed. Please check your email and password.';

  @override
  String loadBannersFailed(int statusCode) {
    return 'Failed to load banners (HTTP $statusCode)';
  }

  @override
  String get loadCategoriesFailed => 'Failed to load categories';

  @override
  String get actionLoadCart => 'load your cart';

  @override
  String get actionOpenCart => 'open your cart';

  @override
  String get actionAddToCart => 'add this recipe to your cart';

  @override
  String get actionRemoveFromCart => 'remove this recipe from your cart';

  @override
  String get actionClearCart => 'clear your cart';

  @override
  String get cartSignInRequired => 'Please sign in to use your cart.';

  @override
  String get chatInvalidResponse => 'The AI replied in an unexpected format';

  @override
  String get chatBuyFirst => 'Buy this recipe to ask the AI about it';

  @override
  String get chatImageTooLarge => 'The image is too large (max 5MB)';

  @override
  String get chatUnavailable =>
      'The AI is temporarily unavailable. Please try again';

  @override
  String errorHttp(int statusCode) {
    return 'Something went wrong (HTTP $statusCode)';
  }

  @override
  String get chatTimeout => 'The AI took too long to reply. Please try again';

  @override
  String get actionLoadFavorites => 'load your favorites';

  @override
  String get actionSaveRecipe => 'save this recipe';

  @override
  String get actionUnsaveRecipe => 'unsave this recipe';

  @override
  String get favoriteSignInRequired => 'Please sign in to save recipes.';

  @override
  String get createRecipeFailed => 'Couldn\'t create the recipe';

  @override
  String get updateRecipeFailed => 'Couldn\'t update the recipe';

  @override
  String get loadRecipesFailed => 'Failed to load recipes';

  @override
  String get recipeNotFoundShort => 'Recipe not found';

  @override
  String get loadRecipeFailed => 'Failed to load the recipe';

  @override
  String get searchRecipesFailed => 'Failed to search recipes';

  @override
  String get deleteRecipeFailed => 'Failed to delete the recipe';

  @override
  String get actionLoadProfile => 'load profile';

  @override
  String get actionSaveProfile => 'save profile';

  @override
  String get signInRequired => 'Please sign in';

  @override
  String get signInBeforeCheckout => 'Please sign in before checking out';

  @override
  String mockPaymentFailedHttp(int statusCode) {
    return 'Mock payment failed (HTTP $statusCode)';
  }

  @override
  String get purchaseInvalidResult =>
      'The server returned an invalid payment result';

  @override
  String get purchaseTimeout => 'Timed out waiting for payment confirmation';

  @override
  String get actionLoadComments => 'load comments';

  @override
  String get actionCheckCommentPermission => 'check comment permission';

  @override
  String get actionSaveComment => 'save comment';

  @override
  String get actionUpdateComment => 'update comment';

  @override
  String get actionDeleteComment => 'delete comment';

  @override
  String get editOwnCommentOnly => 'You can only edit your own comments';

  @override
  String get deleteOwnCommentOnly => 'You can only delete your own comments';

  @override
  String get commentSignInRequired => 'Please sign in to comment.';

  @override
  String errorNoPermission(String action) {
    return 'You do not have permission to $action.';
  }

  @override
  String actionLoadCollection(String collection) {
    return 'load $collection';
  }

  @override
  String get librarySignInRequired => 'Please sign in to see your recipes.';

  @override
  String get actionLoadReviews => 'load reviews';

  @override
  String get actionLoadYourReview => 'load your review';

  @override
  String get actionSaveYourReview => 'save your review';

  @override
  String get reviewSignInRequired => 'Please sign in to review recipes.';

  @override
  String get buyToRate => 'Buy this recipe to rate it';

  @override
  String get uploadSignInRequired => 'Please sign in before uploading.';

  @override
  String get uploadPrepareFailed => 'Could not prepare upload';

  @override
  String uploadFailedHttp(int statusCode) {
    return 'Upload failed (HTTP $statusCode).';
  }

  @override
  String get uploadVerifyFailed => 'Could not verify uploaded file';

  @override
  String get commentEmpty => 'Your comment can\'t be empty';

  @override
  String get signInAgain => 'Please sign in again';

  @override
  String get roleCreator => 'Recipe creator';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleFoodLover => 'Food lover';

  @override
  String get faqCreateTitle => 'How do I create a recipe?';

  @override
  String get faqCreateBody =>
      'Tap the + button in one of two places\n• Community: create a free recipe everyone can see\n• Profile → My recipes: create an Official recipe you can sell\nAdd a name, cover photo, details, categories and steps, then tap \"Publish recipe\"';

  @override
  String get faqDraftTitle => 'Can I save an unfinished recipe?';

  @override
  String get faqDraftBody =>
      'Yes. Go back while creating a recipe and choose \"Save draft\". It will be in Profile → Drafts, where you can keep writing or publish it later';

  @override
  String get faqEditTitle => 'Edit or delete my recipe';

  @override
  String get faqEditBody =>
      'Open the recipe, tap ⋮ in the top-right corner and choose \"Edit\" or \"Delete recipe\"\nPublished Official recipes can\'t be edited (but can be deleted)';

  @override
  String get faqBuyTitle => 'How do I buy a recipe?';

  @override
  String get faqBuyBody =>
      'Open the recipe and tap \"Buy now\" to add it to your cart, then open the cart and check out. Purchased recipes are in Profile → Purchased';

  @override
  String get faqAiTitle => 'How do I ask the AI about a recipe?';

  @override
  String get faqAiBody =>
      'The \"Ask AI about this recipe\" button appears on recipes you\'ve bought or own. You can type a question or attach a photo of your food. AI answers aren\'t always right, so use your judgement — especially about food allergies';

  @override
  String get faqRateTitle => 'Rate and review a recipe';

  @override
  String get faqRateBody =>
      'You can only rate recipes you\'ve bought. Tap \"Rate\" on the recipe page; you can change your rating later. Community recipes can be commented on right away';

  @override
  String get faqProfileTitle => 'Change my profile photo or name';

  @override
  String get faqProfileBody =>
      'Go to Profile → Edit profile to change your photo and display name. Your email is used to sign in, so it can\'t be changed';

  @override
  String get faqForgotTitle => 'I forgot my password';

  @override
  String get faqForgotBody =>
      'Password reset by email isn\'t available yet. If you\'re still signed in, change it in Settings → Change password. If you can\'t sign in, please contact the team';

  @override
  String get faqLostTitle =>
      'My phone was lost, or someone may be using my account';

  @override
  String get faqLostBody =>
      'Go to Settings → Sign out of all devices, then change your password. Every signed-in device is signed out immediately';

  @override
  String get privacyCollectTitle => 'Information we collect';

  @override
  String get privacyCollectBody =>
      '• Account data: email, display name, profile photo and password (stored with one-way hashing — the team can\'t read your password)\n• Content you create: recipes, images, videos, comments and reviews\n• In-app activity: favorites, cart and recipe purchase history';

  @override
  String get privacyVisibleTitle => 'What others can see';

  @override
  String get privacyVisibleBody =>
      'Other users can see your display name, profile photo, published recipes, comments and reviews. Your email, favorites, cart and purchase history are visible only to you';

  @override
  String get privacyAiTitle => 'AI chat';

  @override
  String get privacyAiBody =>
      'Questions and images you send in the AI chat go to an external AI provider to generate answers. Conversations are remembered temporarily and forgotten after about 20 minutes of inactivity. We don\'t store images sent in the chat';

  @override
  String get privacyDeviceTitle => 'Data on your device';

  @override
  String get privacyDeviceBody =>
      'The app keeps your sign-in data in your device\'s secure storage and caches images you\'ve loaded so they open faster. Sign-in data is removed when you sign out';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'Delete your account in Settings → Delete account. Your email, name, profile photo, favorites and cart are erased. Your recipes are hidden, except from people who already bought them. Comments and reviews remain, shown as \"Deleted user\"';

  @override
  String get privacyContactTitle => 'Contact us';

  @override
  String get privacyContactBody =>
      'Questions about your personal data? Contact the team from Help & support';

  @override
  String get termsAccountTitle => 'Your account';

  @override
  String get termsAccountBody =>
      'You\'re responsible for keeping your password safe and for all activity on your account. If you suspect someone else is using it, sign out of all devices and change your password right away';

  @override
  String get termsContentTitle => 'Content you post';

  @override
  String get termsContentBody =>
      'Recipes, images, videos, comments and reviews you post must be yours or ones you have the right to publish. Don\'t post content that is illegal, infringes copyright or harms others. The team may remove content or suspend accounts that break these rules';

  @override
  String get termsPurchaseTitle => 'Buying recipes';

  @override
  String get termsPurchaseBody =>
      'Purchased recipes can be viewed in the app for personal use. Don\'t copy or redistribute them without the recipe creator\'s permission';

  @override
  String get termsAiTitle => 'AI answers';

  @override
  String get termsAiBody =>
      'AI suggestions are only a cooking aid and may be inaccurate or incomplete. Please check them yourself before relying on them, especially for food allergies and food safety';

  @override
  String get termsCloseTitle => 'Closing your account';

  @override
  String get termsCloseBody =>
      'You can delete your account at any time in Settings → Delete account';

  @override
  String get termsChangesTitle => 'Changes to these terms';

  @override
  String get termsChangesBody =>
      'These terms may be updated. Continuing to use the app after a change means you accept the new terms';

  @override
  String get settingsGeneral => 'General';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get englishNameHint => 'e.g. Spicy basil chicken';

  @override
  String get englishNameHelper => 'Optional. Shown when the app is in English';

  @override
  String get statRecipeRating => 'Recipe rating';

  @override
  String reviewsCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get statSales => 'Sold';

  @override
  String get statOfficialSaves => 'Official saves';

  @override
  String get statCommunitySaves => 'Community saves';

  @override
  String get statSavesReceived => 'Saves';

  @override
  String get statCommentsReceived => 'Comments';

  @override
  String get statReviewsWritten => 'Reviews written';
}
