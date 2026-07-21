import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'EduLinky'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Discover teachers, students & opportunities.'**
  String get tagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @iAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get iAlreadyHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to EduLinky'**
  String get signInToContinue;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @errGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get errGoogleSignInFailed;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @errAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get errAppleSignInFailed;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sarah Johnson'**
  String get fullNameHint;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'I am a…'**
  String get chooseYourRole;

  /// No description provided for @chooseYourRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3 — Choose your role. This cannot be changed later.'**
  String get chooseYourRoleSubtitle;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the right tutor or teacher for your learning goals'**
  String get roleStudentDesc;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleTeacherDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with students and institutions seeking your expertise'**
  String get roleTeacherDesc;

  /// No description provided for @roleInstitution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get roleInstitution;

  /// No description provided for @roleInstitutionDesc.
  ///
  /// In en, this message translates to:
  /// **'Post job openings and discover qualified educators'**
  String get roleInstitutionDesc;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get setUpProfile;

  /// No description provided for @cityLocation.
  ///
  /// In en, this message translates to:
  /// **'City / Location'**
  String get cityLocation;

  /// No description provided for @cityLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. London, UK'**
  String get cityLocationHint;

  /// No description provided for @primarySubject.
  ///
  /// In en, this message translates to:
  /// **'Primary subject'**
  String get primarySubject;

  /// No description provided for @primarySubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mathematics'**
  String get primarySubjectHint;

  /// No description provided for @createAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountBtn;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get displayNameHint;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add profile photo'**
  String get addProfilePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @uploadCertification.
  ///
  /// In en, this message translates to:
  /// **'Upload Certification'**
  String get uploadCertification;

  /// No description provided for @uploadCertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your teaching certificates or qualification documents. You can add more than one.'**
  String get uploadCertSubtitle;

  /// No description provided for @dragDropOrTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to select your documents'**
  String get dragDropOrTap;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: PDF, JPG, PNG'**
  String get supportedFormats;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File selected'**
  String get fileSelected;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitForReview;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @pendingVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get pendingVerificationTitle;

  /// No description provided for @pendingVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your certification is being reviewed by our team. We\'ll notify you once it\'s approved.'**
  String get pendingVerificationBody;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated review time: 24–48 hours'**
  String get estimatedTime;

  /// No description provided for @goToDiscover.
  ///
  /// In en, this message translates to:
  /// **'Go to Discover'**
  String get goToDiscover;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetworkUnavailable;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @swipesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} swipes left'**
  String swipesLeft(int count);

  /// No description provided for @swipesUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited swipes'**
  String get swipesUnlimited;

  /// No description provided for @noMoreCards.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everyone for now'**
  String get noMoreCards;

  /// No description provided for @noMoreCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back tomorrow for new matches'**
  String get noMoreCardsSubtitle;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(double distance);

  /// No description provided for @yearsExp.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs exp.'**
  String yearsExp(int years);

  /// No description provided for @itsAMatch.
  ///
  /// In en, this message translates to:
  /// **'You\'re connected!'**
  String get itsAMatch;

  /// No description provided for @matchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You and {name} can now message each other'**
  String matchSubtitle(String name);

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @keepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get keepSwiping;

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// No description provided for @matchesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String matchesTotal(int count);

  /// No description provided for @newMatchesSection.
  ///
  /// In en, this message translates to:
  /// **'New matches'**
  String get newMatchesSection;

  /// No description provided for @messagesSection.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesSection;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @noMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to find your perfect teacher'**
  String get noMatchesSubtitle;

  /// No description provided for @startDiscovering.
  ///
  /// In en, this message translates to:
  /// **'Start Discovering'**
  String get startDiscovering;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatInputHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @typingIndicator.
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get typingIndicator;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingBadge;

  /// No description provided for @featuredBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredBadge;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @subjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @experienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// No description provided for @qualificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Qualifications'**
  String get qualificationsLabel;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel;

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsLabel;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @ratingWithCount.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} reviews)'**
  String ratingWithCount(String rating, int count);

  /// No description provided for @messageBtnLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageBtnLabel;

  /// No description provided for @passBtn.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get passBtn;

  /// No description provided for @connectBtn.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectBtn;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'Tell teachers about yourself and your learning goals…'**
  String get aboutMeHint;

  /// No description provided for @subjectsInterested.
  ///
  /// In en, this message translates to:
  /// **'Subjects I\'m learning'**
  String get subjectsInterested;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @subscriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSection;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePlan;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumPlan;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @swipesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count} swipes / day'**
  String swipesPerDay(int count);

  /// No description provided for @unlimitedSwipes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited swipes'**
  String get unlimitedSwipes;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get planThreeMonths;

  /// No description provided for @planSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get planSixMonths;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get bestValue;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @teacherDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get teacherDiscoverTitle;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @tabJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get tabJobs;

  /// No description provided for @jobCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Opening'**
  String get jobCardLabel;

  /// No description provided for @salaryRange.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salaryRange;

  /// No description provided for @contractType.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractType;

  /// No description provided for @contractFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get contractFullTime;

  /// No description provided for @contractPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get contractPartTime;

  /// No description provided for @contractContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractContract;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by {institution}'**
  String postedBy(String institution);

  /// No description provided for @tabBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get tabBio;

  /// No description provided for @tabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabGallery;

  /// No description provided for @tabQualifications.
  ///
  /// In en, this message translates to:
  /// **'Qualifications'**
  String get tabQualifications;

  /// No description provided for @tabExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get tabExperience;

  /// No description provided for @tabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tabSchedule;

  /// No description provided for @tabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get tabVideos;

  /// No description provided for @subjectsITeach.
  ///
  /// In en, this message translates to:
  /// **'Subjects I teach'**
  String get subjectsITeach;

  /// No description provided for @aboutMeTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your teaching style, experience and what makes you stand out…'**
  String get aboutMeTeacherHint;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @galleryHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 6 photos to your profile'**
  String get galleryHint;

  /// No description provided for @addQualification.
  ///
  /// In en, this message translates to:
  /// **'Add Qualification'**
  String get addQualification;

  /// No description provided for @qualificationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BSc Mathematics — University of Melbourne'**
  String get qualificationHint;

  /// No description provided for @addExperience.
  ///
  /// In en, this message translates to:
  /// **'Add Experience'**
  String get addExperience;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution / School'**
  String get institution;

  /// No description provided for @yearFrom.
  ///
  /// In en, this message translates to:
  /// **'From (year)'**
  String get yearFrom;

  /// No description provided for @yearTo.
  ///
  /// In en, this message translates to:
  /// **'To (year or Present)'**
  String get yearTo;

  /// No description provided for @scheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the time slots when you are available to teach'**
  String get scheduleHint;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @addVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'Add Video URL'**
  String get addVideoUrl;

  /// No description provided for @videoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube, TikTok or Vimeo link'**
  String get videoUrlHint;

  /// No description provided for @videoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Video {number}'**
  String videoUrlLabel(int number);

  /// No description provided for @teacherMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get teacherMatchesTitle;

  /// No description provided for @sectionStudentMatches.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get sectionStudentMatches;

  /// No description provided for @sectionJobMatches.
  ///
  /// In en, this message translates to:
  /// **'Job Applications'**
  String get sectionJobMatches;

  /// No description provided for @noJobMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No job applications yet'**
  String get noJobMatchesYet;

  /// No description provided for @featuredProfile.
  ///
  /// In en, this message translates to:
  /// **'Featured Profile'**
  String get featuredProfile;

  /// No description provided for @featuredProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Appear at the top of search results'**
  String get featuredProfileDesc;

  /// No description provided for @featuredActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get featuredActive;

  /// No description provided for @featuredInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get featuredInactive;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Premium required'**
  String get premiumRequired;

  /// No description provided for @teacherSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get teacherSettingsTitle;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Institution Access'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to post jobs and connect with qualified teachers'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeatureJobs.
  ///
  /// In en, this message translates to:
  /// **'Post unlimited job cards'**
  String get paywallFeatureJobs;

  /// No description provided for @paywallFeatureBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse verified teacher profiles'**
  String get paywallFeatureBrowse;

  /// No description provided for @paywallFeatureMessaging.
  ///
  /// In en, this message translates to:
  /// **'Direct messaging with matched teachers'**
  String get paywallFeatureMessaging;

  /// No description provided for @paywallFeatureFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured placement in search results'**
  String get paywallFeatureFeatured;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a Plan'**
  String get choosePlan;

  /// No description provided for @startSubscription.
  ///
  /// In en, this message translates to:
  /// **'Start Subscription'**
  String get startSubscription;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime · No commitment'**
  String get cancelAnytime;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Job Cards'**
  String get dashboardTitle;

  /// No description provided for @postNewJob.
  ///
  /// In en, this message translates to:
  /// **'Post New Job'**
  String get postNewJob;

  /// No description provided for @noJobsPosted.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get noJobsPosted;

  /// No description provided for @noJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post your first job to start finding teachers'**
  String get noJobsSubtitle;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @applicantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} applicants'**
  String applicantsCount(int count);

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editJob;

  /// No description provided for @closeJob.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeJob;

  /// No description provided for @createJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get createJobTitle;

  /// No description provided for @editJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Job'**
  String get editJobTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the role, requirements and what you\'re looking for…'**
  String get descriptionHint;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @salaryFrom.
  ///
  /// In en, this message translates to:
  /// **'Min Pay'**
  String get salaryFrom;

  /// No description provided for @salaryTo.
  ///
  /// In en, this message translates to:
  /// **'Max Pay'**
  String get salaryTo;

  /// No description provided for @contractTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contractTypeLabel;

  /// No description provided for @postJobBtn.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJobBtn;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveAsDraft;

  /// No description provided for @jobDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetailTitle;

  /// No description provided for @applicantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get applicantsTitle;

  /// No description provided for @noApplicantsYet.
  ///
  /// In en, this message translates to:
  /// **'No applicants yet'**
  String get noApplicantsYet;

  /// No description provided for @noApplicantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Teachers will appear here when they apply to this role'**
  String get noApplicantsSubtitle;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @appliedToRole.
  ///
  /// In en, this message translates to:
  /// **'{name} applied to your {role} role'**
  String appliedToRole(String name, String role);

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navNotifications;

  /// No description provided for @subjectMaths.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get subjectMaths;

  /// No description provided for @subjectEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get subjectEnglish;

  /// No description provided for @subjectScience.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get subjectScience;

  /// No description provided for @subjectPhysics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get subjectPhysics;

  /// No description provided for @subjectChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get subjectChemistry;

  /// No description provided for @subjectBiology.
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get subjectBiology;

  /// No description provided for @subjectEconomics.
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get subjectEconomics;

  /// No description provided for @subjectFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get subjectFrench;

  /// No description provided for @subjectGeography.
  ///
  /// In en, this message translates to:
  /// **'Geography'**
  String get subjectGeography;

  /// No description provided for @subjectHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get subjectHistory;

  /// No description provided for @subjectICT.
  ///
  /// In en, this message translates to:
  /// **'ICT'**
  String get subjectICT;

  /// No description provided for @subjectOther.
  ///
  /// In en, this message translates to:
  /// **'Other (type your own)'**
  String get subjectOther;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlan;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @billingSection.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingSection;

  /// No description provided for @institutionProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Institution Profile'**
  String get institutionProfileTitle;

  /// No description provided for @institutionName.
  ///
  /// In en, this message translates to:
  /// **'Institution name'**
  String get institutionName;

  /// No description provided for @institutionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunshine Academy'**
  String get institutionNameHint;

  /// No description provided for @institutionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get institutionDescription;

  /// No description provided for @institutionDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell teachers about your institution…'**
  String get institutionDescriptionHint;

  /// No description provided for @institutionWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get institutionWebsite;

  /// No description provided for @institutionWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'https://yourschool.com'**
  String get institutionWebsiteHint;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get contactEmail;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @errEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get errEnterEmailPassword;

  /// No description provided for @errForgotPasswordNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above, then tap \"Forgot password\".'**
  String get errForgotPasswordNoEmail;

  /// No description provided for @msgResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}.'**
  String msgResetEmailSent(String email);

  /// No description provided for @msgGoogleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is coming soon.'**
  String get msgGoogleComingSoon;

  /// No description provided for @errFillNameEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your name, email, and password.'**
  String get errFillNameEmailPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errInvalidEmail;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errPasswordsMismatch;

  /// No description provided for @errRestartRegistration.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — please restart registration.'**
  String get errRestartRegistration;

  /// No description provided for @errSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select your city.'**
  String get errSelectCity;

  /// No description provided for @errFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Could not finish setting up your account. Please try again.'**
  String get errFinishSetup;

  /// No description provided for @warnAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready, but the photo could not be uploaded.'**
  String get warnAvatarUploadFailed;

  /// No description provided for @errSubmitCertificate.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your certificate: {error}'**
  String errSubmitCertificate(String error);

  /// No description provided for @adjustPhoto.
  ///
  /// In en, this message translates to:
  /// **'Adjust photo'**
  String get adjustPhoto;

  /// No description provided for @cropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reposition · pinch to zoom'**
  String get cropHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @selectYourCity.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get selectYourCity;

  /// No description provided for @searchForACity.
  ///
  /// In en, this message translates to:
  /// **'Search for a city…'**
  String get searchForACity;

  /// No description provided for @errCityNotSelectable.
  ///
  /// In en, this message translates to:
  /// **'Could not select that city. Try another.'**
  String get errCityNotSelectable;

  /// No description provided for @errLoadSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Could not load suggestions. Check your connection.'**
  String get errLoadSuggestions;

  /// No description provided for @errLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.\n{error}'**
  String errLoadProfile(String error);

  /// No description provided for @errSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile: {error}'**
  String errSaveProfile(String error);

  /// No description provided for @errUpdateCity.
  ///
  /// In en, this message translates to:
  /// **'Could not update your city: {error}'**
  String errUpdateCity(String error);

  /// No description provided for @errAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not add the photo: {error}'**
  String errAddPhoto(String error);

  /// No description provided for @errRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the photo: {error}'**
  String errRemovePhoto(String error);

  /// No description provided for @errSaveQualifications.
  ///
  /// In en, this message translates to:
  /// **'Could not save qualifications: {error}'**
  String errSaveQualifications(String error);

  /// No description provided for @errSaveExperience.
  ///
  /// In en, this message translates to:
  /// **'Could not save experience: {error}'**
  String errSaveExperience(String error);

  /// No description provided for @errSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not save your schedule: {error}'**
  String errSaveSchedule(String error);

  /// No description provided for @errSaveVideos.
  ///
  /// In en, this message translates to:
  /// **'Could not save your videos: {error}'**
  String errSaveVideos(String error);

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate'**
  String get hourlyRate;

  /// No description provided for @hourlyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get hourlyRateHint;

  /// No description provided for @videosAllowedHint.
  ///
  /// In en, this message translates to:
  /// **'Only YouTube and Vimeo links are accepted.'**
  String get videosAllowedHint;

  /// No description provided for @subscriptionProName.
  ///
  /// In en, this message translates to:
  /// **'Institution Pro'**
  String get subscriptionProName;

  /// No description provided for @subscriptionRenews.
  ///
  /// In en, this message translates to:
  /// **'Active · Renews {date}'**
  String subscriptionRenews(String date);

  /// No description provided for @appliedToJob.
  ///
  /// In en, this message translates to:
  /// **'Applied to \"{title}\" at {institution}'**
  String appliedToJob(String title, String institution);

  /// No description provided for @savedExclamation.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get savedExclamation;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'This profile is not available.'**
  String get profileNotFound;

  /// No description provided for @addAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to add another file'**
  String get addAnotherFile;

  /// No description provided for @certFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} documents selected'**
  String certFilesSelected(int count, int max);

  /// No description provided for @certMaxFiles.
  ///
  /// In en, this message translates to:
  /// **'You can upload at most {max} documents.'**
  String certMaxFiles(int max);

  /// No description provided for @certFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is larger than 10 MB and was skipped.'**
  String certFileTooLarge(String name);

  /// No description provided for @errCropFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not crop the image. Please try again.'**
  String get errCropFailed;

  /// No description provided for @pendingDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get pendingDiscoverTitle;

  /// No description provided for @pendingDiscoverBody.
  ///
  /// In en, this message translates to:
  /// **'You can discover students once an admin has approved your certificate. We\'ll let you know as soon as it\'s reviewed.'**
  String get pendingDiscoverBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @addSubject.
  ///
  /// In en, this message translates to:
  /// **'Add subject'**
  String get addSubject;

  /// No description provided for @addSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mandarin, Music Theory'**
  String get addSubjectHint;

  /// No description provided for @subjectsMax.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {max} subjects.'**
  String subjectsMax(int max);

  /// No description provided for @errSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not send: {error}'**
  String errSendMessage(String error);

  /// No description provided for @errLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load this conversation.\n{error}'**
  String errLoadMessages(String error);

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'You matched! Say hello.'**
  String get chatEmpty;

  /// No description provided for @errLoadMatches.
  ///
  /// In en, this message translates to:
  /// **'Could not load your matches.\n{error}'**
  String errLoadMatches(String error);

  /// No description provided for @noMatchesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep swiping — when someone likes you back, they\'ll appear here.'**
  String get noMatchesYetSubtitle;

  /// No description provided for @messagesLabel.
  ///
  /// In en, this message translates to:
  /// **'MESSAGES'**
  String get messagesLabel;

  /// No description provided for @newMatchesLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW MATCHES'**
  String get newMatchesLabel;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @errLoadActivity.
  ///
  /// In en, this message translates to:
  /// **'Could not load your activity.\n{error}'**
  String errLoadActivity(String error);

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noActivityYet;

  /// No description provided for @noActivityYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Matches, messages and account updates will show up here.'**
  String get noActivityYetSubtitle;

  /// No description provided for @refreshDeck.
  ///
  /// In en, this message translates to:
  /// **'Show people I passed'**
  String get refreshDeck;

  /// No description provided for @searchWider.
  ///
  /// In en, this message translates to:
  /// **'Search wider ({km} km)'**
  String searchWider(int km);

  /// No description provided for @searchRadiusNote.
  ///
  /// In en, this message translates to:
  /// **'Searching within {km} km'**
  String searchRadiusNote(int km);

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postJob;

  /// No description provided for @reopenJob.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenJob;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobDescription;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'This job card no longer exists.'**
  String get jobNotFound;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No job cards yet'**
  String get noJobsYet;

  /// No description provided for @noJobsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a job and approved teachers nearby will see it in their deck.'**
  String get noJobsYetSubtitle;

  /// No description provided for @applicantsSection.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get applicantsSection;

  /// No description provided for @applicantCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applicants} =1{1 applicant} other{{count} applicants}}'**
  String applicantCount(int count);

  /// No description provided for @errJobTitleSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'A title and subject are required.'**
  String get errJobTitleSubjectRequired;

  /// No description provided for @jobSubjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get jobSubjectsLabel;

  /// No description provided for @errJobSubjectsRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject.'**
  String get errJobSubjectsRequired;

  /// No description provided for @jobSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mathematics'**
  String get jobSubjectHint;

  /// No description provided for @jobLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level / Key Stage'**
  String get jobLevelLabel;

  /// No description provided for @jobLevelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. KS3, A-Level, Secondary'**
  String get jobLevelHint;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @startDateFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get startDateFlexible;

  /// No description provided for @jobVideoOptional.
  ///
  /// In en, this message translates to:
  /// **'Video URL (optional)'**
  String get jobVideoOptional;

  /// No description provided for @jobLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Posted in {city} — your institution\'s city'**
  String jobLocationNote(String city);

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @publishJob.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishJob;

  /// No description provided for @draftNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Drafts are not shown to teachers until you publish them.'**
  String get draftNotVisible;

  /// No description provided for @payPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay period'**
  String get payPeriodLabel;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get perHour;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get perDay;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get perMonth;

  /// No description provided for @payPerHourShort.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get payPerHourShort;

  /// No description provided for @payPerDayShort.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get payPerDayShort;

  /// No description provided for @payPerMonthShort.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get payPerMonthShort;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportUser;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportUserTitle(String name);

  /// No description provided for @reportUserBody.
  ///
  /// In en, this message translates to:
  /// **'Reports are reviewed by our team. Your name is never shown to the person you report.'**
  String get reportUserBody;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks — our team will review this.'**
  String get reportSent;

  /// No description provided for @reportAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reported this.'**
  String get reportAlreadySent;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockUserTitle(String name);

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to see you or message you, and you won\'t see them. Any existing conversation will be removed.'**
  String get blockUserBody;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked.'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked.'**
  String get userUnblocked;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reasonHarassment;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reasonInappropriate;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reasonSpam;

  /// No description provided for @reasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reasonFakeProfile;

  /// No description provided for @reasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'Underage user'**
  String get reasonUnderage;

  /// No description provided for @reasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get reasonSafety;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reasonOther;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @reportUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about harassment, spam or unsafe behaviour'**
  String get reportUserSubtitle;

  /// No description provided for @blockUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They can\'t see or message you, and you won\'t see them'**
  String get blockUserSubtitle;

  /// No description provided for @unblockUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They can appear in your deck again'**
  String get unblockUserSubtitle;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @noBlockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone you block will appear here, and you can unblock them at any time.'**
  String get noBlockedUsersSubtitle;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @noMoreJobs.
  ///
  /// In en, this message translates to:
  /// **'No more jobs right now'**
  String get noMoreJobs;

  /// No description provided for @noMoreJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You only see jobs in the subjects you teach. Add a subject to widen your search, or start over to revisit the ones you skipped — jobs you\'ve applied to won\'t come back.'**
  String get noMoreJobsSubtitle;

  /// No description provided for @startOverJobs.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOverJobs;

  /// No description provided for @editMySubjects.
  ///
  /// In en, this message translates to:
  /// **'Edit my subjects'**
  String get editMySubjects;

  /// No description provided for @benefitUnlimitedSwipes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited swipes — no daily limit'**
  String get benefitUnlimitedSwipes;

  /// No description provided for @benefitFeaturedBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured badge on your profile'**
  String get benefitFeaturedBadge;

  /// No description provided for @benefitPriorityDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Appear higher in discovery'**
  String get benefitPriorityDiscovery;

  /// No description provided for @manageSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Manage or cancel in your App Store / Play Store account settings.'**
  String get manageSubscriptionHint;

  /// No description provided for @subscribeBtn.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeBtn;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @premiumThanks.
  ///
  /// In en, this message translates to:
  /// **'You\'re premium. Enjoy unlimited swipes!'**
  String get premiumThanks;

  /// No description provided for @premiumRestored.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been restored.'**
  String get premiumRestored;

  /// No description provided for @premiumNothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found for this account.'**
  String get premiumNothingToRestore;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t available right now. Please try again later.'**
  String get premiumUnavailable;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your store account at confirmation. The subscription renews automatically unless cancelled at least 24 hours before the end of the period. Manage or cancel it in your account settings.'**
  String get subscriptionTerms;

  /// No description provided for @videosLabel.
  ///
  /// In en, this message translates to:
  /// **'Intro videos'**
  String get videosLabel;

  /// No description provided for @errOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open this video.'**
  String get errOpenVideo;

  /// No description provided for @subjectOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectOtherLabel;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editReview;

  /// No description provided for @yourReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get yourReviewLabel;

  /// No description provided for @reviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Review {name}'**
  String reviewSheetTitle(String name);

  /// No description provided for @reviewModerationNote.
  ///
  /// In en, this message translates to:
  /// **'Reviews are checked by our team before they appear.'**
  String get reviewModerationNote;

  /// No description provided for @yourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRatingLabel;

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What was it like learning with them? (optional)'**
  String get reviewCommentHint;

  /// No description provided for @submitReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReviewBtn;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your review will appear once it\'s approved.'**
  String get reviewSubmitted;

  /// No description provided for @reviewPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval — only you can see this.'**
  String get reviewPendingNote;

  /// No description provided for @reviewPublishedNote.
  ///
  /// In en, this message translates to:
  /// **'Published on their profile.'**
  String get reviewPublishedNote;

  /// No description provided for @reviewRejectedNote.
  ///
  /// In en, this message translates to:
  /// **'This review wasn\'t published. You can edit it and try again.'**
  String get reviewRejectedNote;

  /// No description provided for @reviewRejectedNoteWithReason.
  ///
  /// In en, this message translates to:
  /// **'This review wasn\'t published: {reason}'**
  String reviewRejectedNoteWithReason(String reason);

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your review. {error}'**
  String reviewFailed(String error);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
