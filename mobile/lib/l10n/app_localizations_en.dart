// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'EduLinky';

  @override
  String get tagline => 'Discover teachers, students & opportunities.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get iAlreadyHaveAccount => 'I already have an account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue to EduLinky';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get errGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get errAppleSignInFailed => 'Apple sign-in failed. Please try again.';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'e.g. Sarah Johnson';

  @override
  String get login => 'Login';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get createAccount => 'Create Account';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get chooseYourRole => 'I am a…';

  @override
  String get chooseYourRoleSubtitle =>
      'Step 2 of 3 — Choose your role. This cannot be changed later.';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleStudentDesc =>
      'Find the right tutor or teacher for your learning goals';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleTeacherDesc =>
      'Connect with students and institutions seeking your expertise';

  @override
  String get roleInstitution => 'Institution';

  @override
  String get roleInstitutionDesc =>
      'Post job openings and discover qualified educators';

  @override
  String get setUpProfile => 'Your profile';

  @override
  String get cityLocation => 'City / Location';

  @override
  String get cityLocationHint => 'e.g. London, UK';

  @override
  String get primarySubject => 'Primary subject';

  @override
  String get primarySubjectHint => 'e.g. Mathematics';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'How should we call you?';

  @override
  String get addProfilePhoto => 'Add profile photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get submit => 'Submit';

  @override
  String get uploadCertification => 'Upload Certification';

  @override
  String get uploadCertSubtitle =>
      'Upload your teaching certificates or qualification documents. You can add more than one.';

  @override
  String get dragDropOrTap => 'Tap to select your documents';

  @override
  String get supportedFormats => 'Supported formats: PDF, JPG, PNG';

  @override
  String get fileSelected => 'File selected';

  @override
  String get submitForReview => 'Submit for Review';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get pendingVerificationTitle => 'Under Review';

  @override
  String get pendingVerificationBody =>
      'Your certification is being reviewed by our team. We\'ll notify you once it\'s approved.';

  @override
  String get estimatedTime => 'Estimated review time: 24–48 hours';

  @override
  String get goToDiscover => 'Go to Discover';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get unsupportedAccountTitle => 'Use the web admin panel';

  @override
  String get unsupportedAccountBody =>
      'This account isn\'t set up for the app. Admin accounts are managed from the web admin panel.';

  @override
  String get errorNetworkUnavailable => 'No internet connection.';

  @override
  String get loading => 'Loading…';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMatches => 'Matches';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get discoverTitle => 'Discover';

  @override
  String swipesLeft(int count) {
    return '$count swipes left';
  }

  @override
  String get swipesUnlimited => 'Unlimited swipes';

  @override
  String get noMoreCards => 'You\'ve seen everyone for now';

  @override
  String get noMoreCardsSubtitle => 'Check back tomorrow for new matches';

  @override
  String kmAway(double distance) {
    return '$distance km away';
  }

  @override
  String yearsExp(int years) {
    return '$years yrs exp.';
  }

  @override
  String get itsAMatch => 'You\'re connected!';

  @override
  String matchSubtitle(String name) {
    return 'You and $name can now message each other';
  }

  @override
  String get sendMessage => 'Send Message';

  @override
  String get keepSwiping => 'Keep Swiping';

  @override
  String get matchesTitle => 'Matches';

  @override
  String matchesTotal(int count) {
    return '$count total';
  }

  @override
  String get newMatchesSection => 'New matches';

  @override
  String get messagesSection => 'Messages';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get noMatchesSubtitle => 'Start swiping to find your perfect teacher';

  @override
  String get startDiscovering => 'Start Discovering';

  @override
  String get chatInputHint => 'Type a message…';

  @override
  String get send => 'Send';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get typingIndicator => 'Typing…';

  @override
  String get verifiedBadge => 'Verified';

  @override
  String get pendingBadge => 'Pending Review';

  @override
  String get featuredBadge => 'Featured';

  @override
  String get aboutMe => 'About Me';

  @override
  String get subjectsLabel => 'Subjects';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get experienceLabel => 'Experience';

  @override
  String get qualificationsLabel => 'Qualifications';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String ratingWithCount(String rating, int count) {
    return '$rating ($count reviews)';
  }

  @override
  String get messageBtnLabel => 'Message';

  @override
  String get passBtn => 'Pass';

  @override
  String get connectBtn => 'Connect';

  @override
  String get myProfile => 'My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get aboutMeHint =>
      'Tell teachers about yourself and your learning goals…';

  @override
  String get subjectsInterested => 'Subjects I\'m learning';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get saved => 'Saved!';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get subscriptionSection => 'Subscription';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get freePlan => 'Free';

  @override
  String get premiumPlan => 'Premium';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String swipesPerDay(int count) {
    return '$count swipes / day';
  }

  @override
  String get unlimitedSwipes => 'Unlimited swipes';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planThreeMonths => '3 Months';

  @override
  String get planSixMonths => '6 Months';

  @override
  String get planYearly => 'Yearly';

  @override
  String get bestValue => 'Best Value';

  @override
  String get accountSection => 'Account';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get teacherDiscoverTitle => 'Discover';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get jobCardLabel => 'Job Opening';

  @override
  String get salaryRange => 'Salary';

  @override
  String get contractType => 'Contract';

  @override
  String get contractFullTime => 'Full-time';

  @override
  String get contractPartTime => 'Part-time';

  @override
  String get contractContract => 'Contract';

  @override
  String get applyNow => 'Apply Now';

  @override
  String postedBy(String institution) {
    return 'Posted by $institution';
  }

  @override
  String get tabBio => 'Bio';

  @override
  String get tabGallery => 'Gallery';

  @override
  String get tabQualifications => 'Qualifications';

  @override
  String get tabExperience => 'Experience';

  @override
  String get tabSchedule => 'Schedule';

  @override
  String get tabVideos => 'Videos';

  @override
  String get subjectsITeach => 'Subjects I teach';

  @override
  String get aboutMeTeacherHint =>
      'Describe your teaching style, experience and what makes you stand out…';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get galleryHint => 'Add up to 6 photos to your profile';

  @override
  String get addQualification => 'Add Qualification';

  @override
  String get qualificationHint =>
      'e.g. BSc Mathematics — University of Melbourne';

  @override
  String get addExperience => 'Add Experience';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get institution => 'Institution / School';

  @override
  String get yearFrom => 'From (year)';

  @override
  String get yearTo => 'To (year or Present)';

  @override
  String get scheduleHint =>
      'Tap the time slots when you are available to teach';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get addVideoUrl => 'Add Video URL';

  @override
  String get videoUrlHint => 'Paste a YouTube, TikTok or Vimeo link';

  @override
  String videoUrlLabel(int number) {
    return 'Video $number';
  }

  @override
  String get teacherMatchesTitle => 'Matches';

  @override
  String get sectionStudentMatches => 'Students';

  @override
  String get sectionJobMatches => 'Job Applications';

  @override
  String get noJobMatchesYet => 'No job applications yet';

  @override
  String get featuredProfile => 'Featured Profile';

  @override
  String get featuredProfileDesc => 'Appear at the top of search results';

  @override
  String get featuredActive => 'Active';

  @override
  String get featuredInactive => 'Inactive';

  @override
  String get premiumRequired => 'Premium required';

  @override
  String get teacherSettingsTitle => 'Settings';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get present => 'Present';

  @override
  String get paywallTitle => 'Unlock Institution Access';

  @override
  String get paywallSubtitle =>
      'Subscribe to post jobs and connect with qualified teachers';

  @override
  String get paywallFeatureJobs => 'Post unlimited job cards';

  @override
  String get paywallFeatureBrowse => 'Browse verified teacher profiles';

  @override
  String get paywallFeatureMessaging =>
      'Direct messaging with matched teachers';

  @override
  String get paywallFeatureFeatured => 'Featured placement in search results';

  @override
  String get choosePlan => 'Choose a Plan';

  @override
  String get startSubscription => 'Start Subscription';

  @override
  String get cancelAnytime => 'Cancel anytime · No commitment';

  @override
  String get dashboardTitle => 'My Job Cards';

  @override
  String get postNewJob => 'Post New Job';

  @override
  String get noJobsPosted => 'No jobs posted yet';

  @override
  String get noJobsSubtitle => 'Post your first job to start finding teachers';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusClosed => 'Closed';

  @override
  String applicantsCount(int count) {
    return '$count applicants';
  }

  @override
  String get editJob => 'Edit';

  @override
  String get closeJob => 'Close';

  @override
  String get createJobTitle => 'Post a Job';

  @override
  String get editJobTitle => 'Edit Job';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint =>
      'Describe the role, requirements and what you\'re looking for…';

  @override
  String get locationLabel => 'Location';

  @override
  String get salaryFrom => 'Min Pay';

  @override
  String get salaryTo => 'Max Pay';

  @override
  String get contractTypeLabel => 'Contract Type';

  @override
  String get postJobBtn => 'Post Job';

  @override
  String get saveAsDraft => 'Save as Draft';

  @override
  String get jobDetailTitle => 'Job Details';

  @override
  String get watchIntroVideo => 'Watch intro video';

  @override
  String get applicantsTitle => 'Applicants';

  @override
  String get noApplicantsYet => 'No applicants yet';

  @override
  String get noApplicantsSubtitle =>
      'Teachers will appear here when they apply to this role';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String appliedToRole(String name, String role) {
    return '$name applied to your $role role';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get subjectMaths => 'Mathematics';

  @override
  String get subjectEnglish => 'English';

  @override
  String get subjectScience => 'Sciences';

  @override
  String get subjectPhysics => 'Physics';

  @override
  String get subjectChemistry => 'Chemistry';

  @override
  String get subjectBiology => 'Biology';

  @override
  String get subjectEconomics => 'Economics';

  @override
  String get subjectFrench => 'French';

  @override
  String get subjectGeography => 'Geography';

  @override
  String get subjectHistory => 'History';

  @override
  String get subjectICT => 'ICT';

  @override
  String get subjectOther => 'Other (type your own)';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get changePlan => 'Change Plan';

  @override
  String get cancelSubscription => 'Cancel Subscription';

  @override
  String get billingSection => 'Billing';

  @override
  String get institutionProfileTitle => 'Institution Profile';

  @override
  String get institutionName => 'Institution name';

  @override
  String get institutionNameHint => 'e.g. Sunshine Academy';

  @override
  String get institutionDescription => 'Description';

  @override
  String get institutionDescriptionHint =>
      'Tell teachers about your institution…';

  @override
  String get institutionWebsite => 'Website';

  @override
  String get institutionWebsiteHint => 'https://yourschool.com';

  @override
  String get contactEmail => 'Contact email';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get errEnterEmailPassword => 'Please enter your email and password.';

  @override
  String get errForgotPasswordNoEmail =>
      'Enter your email above, then tap \"Forgot password\".';

  @override
  String msgResetEmailSent(String email) {
    return 'Password reset email sent to $email.';
  }

  @override
  String get msgGoogleComingSoon => 'Google sign-in is coming soon.';

  @override
  String get errFillNameEmailPassword =>
      'Please fill in your name, email, and password.';

  @override
  String get errInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get errPasswordsMismatch => 'Passwords do not match.';

  @override
  String get errRestartRegistration =>
      'Something went wrong — please restart registration.';

  @override
  String get errSelectCity => 'Please select your city.';

  @override
  String get errFinishSetup =>
      'Could not finish setting up your account. Please try again.';

  @override
  String get warnAvatarUploadFailed =>
      'Your account is ready, but the photo could not be uploaded.';

  @override
  String errSubmitCertificate(String error) {
    return 'Could not submit your certificate: $error';
  }

  @override
  String get adjustPhoto => 'Adjust photo';

  @override
  String get cropHint => 'Drag to reposition · pinch to zoom';

  @override
  String get done => 'Done';

  @override
  String get selectYourCity => 'Select your city';

  @override
  String get searchForACity => 'Search for a city…';

  @override
  String get errCityNotSelectable => 'Could not select that city. Try another.';

  @override
  String get errLoadSuggestions =>
      'Could not load suggestions. Check your connection.';

  @override
  String errLoadProfile(String error) {
    return 'Could not load your profile.\n$error';
  }

  @override
  String errSaveProfile(String error) {
    return 'Could not save your profile: $error';
  }

  @override
  String errUpdateCity(String error) {
    return 'Could not update your city: $error';
  }

  @override
  String errAddPhoto(String error) {
    return 'Could not add the photo: $error';
  }

  @override
  String errRemovePhoto(String error) {
    return 'Could not remove the photo: $error';
  }

  @override
  String errSaveQualifications(String error) {
    return 'Could not save qualifications: $error';
  }

  @override
  String errSaveExperience(String error) {
    return 'Could not save experience: $error';
  }

  @override
  String errSaveSchedule(String error) {
    return 'Could not save your schedule: $error';
  }

  @override
  String errSaveVideos(String error) {
    return 'Could not save your videos: $error';
  }

  @override
  String get hourlyRate => 'Hourly rate';

  @override
  String get hourlyRateHint => 'e.g. 25';

  @override
  String get videosAllowedHint => 'Only YouTube and Vimeo links are accepted.';

  @override
  String get subscriptionProName => 'Institution Pro';

  @override
  String subscriptionRenews(String date) {
    return 'Active · Renews $date';
  }

  @override
  String appliedToJob(String title, String institution) {
    return 'Applied to \"$title\" at $institution';
  }

  @override
  String get savedExclamation => 'Saved!';

  @override
  String get currency => 'Currency';

  @override
  String get profileNotFound => 'This profile is not available.';

  @override
  String get addAnotherFile => 'Tap to add another file';

  @override
  String certFilesSelected(int count, int max) {
    return '$count of $max documents selected';
  }

  @override
  String certMaxFiles(int max) {
    return 'You can upload at most $max documents.';
  }

  @override
  String certFileTooLarge(String name) {
    return '\"$name\" is larger than 10 MB and was skipped.';
  }

  @override
  String get errCropFailed => 'Could not crop the image. Please try again.';

  @override
  String get pendingDiscoverTitle => 'Verification pending';

  @override
  String get pendingDiscoverBody =>
      'You can discover students once an admin has approved your certificate. We\'ll let you know as soon as it\'s reviewed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get addSubject => 'Add subject';

  @override
  String get addSubjectHint => 'e.g. Mandarin, Music Theory';

  @override
  String subjectsMax(int max) {
    return 'You can select up to $max subjects.';
  }

  @override
  String errSendMessage(String error) {
    return 'Could not send: $error';
  }

  @override
  String errLoadMessages(String error) {
    return 'Could not load this conversation.\n$error';
  }

  @override
  String get chatEmpty => 'You matched! Say hello.';

  @override
  String errLoadMatches(String error) {
    return 'Could not load your matches.\n$error';
  }

  @override
  String get noMatchesYetSubtitle =>
      'Keep swiping — when someone likes you back, they\'ll appear here.';

  @override
  String get messagesLabel => 'MESSAGES';

  @override
  String get newMatchesLabel => 'NEW MATCHES';

  @override
  String get activityTitle => 'Activity';

  @override
  String errLoadActivity(String error) {
    return 'Could not load your activity.\n$error';
  }

  @override
  String get noActivityYet => 'Nothing here yet';

  @override
  String get noActivityYetSubtitle =>
      'Matches, messages and account updates will show up here.';

  @override
  String get refreshDeck => 'Show people I passed';

  @override
  String searchWider(int km) {
    return 'Search wider ($km km)';
  }

  @override
  String searchRadiusNote(int km) {
    return 'Searching within $km km';
  }

  @override
  String get postJob => 'Post a job';

  @override
  String get reopenJob => 'Reopen';

  @override
  String get jobDescription => 'Description';

  @override
  String get jobNotFound => 'This job card no longer exists.';

  @override
  String get noJobsYet => 'No job cards yet';

  @override
  String get noJobsYetSubtitle =>
      'Post a job and approved teachers nearby will see it in their deck.';

  @override
  String get applicantsSection => 'Applicants';

  @override
  String applicantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applicants',
      one: '1 applicant',
      zero: 'No applicants',
    );
    return '$_temp0';
  }

  @override
  String get errJobTitleSubjectRequired => 'A title and subject are required.';

  @override
  String get jobSubjectsLabel => 'Subject';

  @override
  String get errJobSubjectsRequired => 'Choose a subject.';

  @override
  String get jobSubjectHint => 'e.g. Mathematics';

  @override
  String get jobLevelLabel => 'Level / Key Stage';

  @override
  String get jobLevelHint => 'e.g. KS3, A-Level, Secondary';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get startDateFlexible => 'Flexible';

  @override
  String get jobVideoOptional => 'Video URL (optional)';

  @override
  String jobLocationNote(String city) {
    return 'Posted in $city — your institution\'s city';
  }

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get publishJob => 'Publish';

  @override
  String get draftNotVisible =>
      'Drafts are not shown to teachers until you publish them.';

  @override
  String get payPeriodLabel => 'Pay period';

  @override
  String get perHour => 'Per hour';

  @override
  String get perDay => 'Per day';

  @override
  String get perMonth => 'Per month';

  @override
  String get payPerHourShort => '/hr';

  @override
  String get payPerDayShort => '/day';

  @override
  String get payPerMonthShort => '/mo';

  @override
  String get reportUser => 'Report';

  @override
  String get blockUser => 'Block';

  @override
  String get unblockUser => 'Unblock';

  @override
  String reportUserTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportUserBody =>
      'Reports are reviewed by our team. Your name is never shown to the person you report.';

  @override
  String get reportSent => 'Thanks — our team will review this.';

  @override
  String get reportAlreadySent => 'You\'ve already reported this.';

  @override
  String blockUserTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockUserBody =>
      'They won\'t be able to see you or message you, and you won\'t see them. Any existing conversation will be removed.';

  @override
  String get userBlocked => 'Blocked.';

  @override
  String get userUnblocked => 'Unblocked.';

  @override
  String get reasonHarassment => 'Harassment or bullying';

  @override
  String get reasonInappropriate => 'Inappropriate content';

  @override
  String get reasonSpam => 'Spam or scam';

  @override
  String get reasonFakeProfile => 'Fake profile';

  @override
  String get reasonUnderage => 'Underage user';

  @override
  String get reasonSafety => 'Safety concern';

  @override
  String get reasonOther => 'Something else';

  @override
  String get moreOptions => 'More options';

  @override
  String get reportUserSubtitle =>
      'Tell us about harassment, spam or unsafe behaviour';

  @override
  String get blockUserSubtitle =>
      'They can\'t see or message you, and you won\'t see them';

  @override
  String get unblockUserSubtitle => 'They can appear in your deck again';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get noBlockedUsersSubtitle =>
      'Anyone you block will appear here, and you can unblock them at any time.';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get noMoreJobs => 'No more jobs right now';

  @override
  String get myApplications => 'My Applications';

  @override
  String get applied => 'Applied';

  @override
  String get noApplicationsYet => 'No applications yet';

  @override
  String get noApplicationsYetSubtitle =>
      'Jobs you apply to will show up here.';

  @override
  String get noMoreJobsSubtitle =>
      'You only see jobs in the subjects you teach. Add a subject to widen your search, or start over to revisit the ones you skipped — jobs you\'ve applied to won\'t come back.';

  @override
  String get startOverJobs => 'Start over';

  @override
  String get editMySubjects => 'Edit my subjects';

  @override
  String get benefitUnlimitedSwipes => 'Unlimited swipes — no daily limit';

  @override
  String get benefitFeaturedBadge => 'Featured badge on your profile';

  @override
  String get benefitPriorityDiscovery => 'Appear higher in discovery';

  @override
  String get manageSubscriptionHint =>
      'Manage or cancel in your App Store / Play Store account settings.';

  @override
  String get subscribeBtn => 'Subscribe';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get premiumThanks => 'You\'re premium. Enjoy unlimited swipes!';

  @override
  String get premiumRestored => 'Your subscription has been restored.';

  @override
  String get premiumNothingToRestore =>
      'No previous purchase found for this account.';

  @override
  String get premiumUnavailable =>
      'Subscriptions aren\'t available right now. Please try again later.';

  @override
  String get subscriptionTerms =>
      'Payment is charged to your store account at confirmation. The subscription renews automatically unless cancelled at least 24 hours before the end of the period. Manage or cancel it in your account settings.';

  @override
  String get videosLabel => 'Intro videos';

  @override
  String get errOpenVideo => 'Could not open this video.';

  @override
  String get subjectOtherLabel => 'Subject';

  @override
  String get writeReview => 'Write a review';

  @override
  String get editReview => 'Edit';

  @override
  String get yourReviewLabel => 'Your review';

  @override
  String reviewSheetTitle(String name) {
    return 'Review $name';
  }

  @override
  String get reviewModerationNote =>
      'Reviews are checked by our team before they appear.';

  @override
  String get yourRatingLabel => 'Your rating';

  @override
  String get reviewCommentHint =>
      'What was it like learning with them? (optional)';

  @override
  String get submitReviewBtn => 'Submit review';

  @override
  String get reviewSubmitted =>
      'Thanks — your review will appear once it\'s approved.';

  @override
  String get reviewPendingNote => 'Awaiting approval — only you can see this.';

  @override
  String get reviewPublishedNote => 'Published on their profile.';

  @override
  String get reviewRejectedNote =>
      'This review wasn\'t published. You can edit it and try again.';

  @override
  String reviewRejectedNoteWithReason(String reason) {
    return 'This review wasn\'t published: $reason';
  }

  @override
  String reviewFailed(String error) {
    return 'Could not submit your review. $error';
  }
}
