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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hangout'**
  String get appName;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get actionMore;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @badgeHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get badgeHost;

  /// No description provided for @badgeOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get badgeOwner;

  /// No description provided for @badgeYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get badgeYou;

  /// No description provided for @nameYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String nameYou(String name);

  /// No description provided for @countOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String countOf(int done, int total);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'That didn’t work. Check your connection and try again.'**
  String get errorGeneric;

  /// No description provided for @errorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorCheckConnection;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open that link.'**
  String get linkOpenFailed;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateFormatShort.
  ///
  /// In en, this message translates to:
  /// **'d MMM'**
  String get dateFormatShort;

  /// No description provided for @dateFormatLong.
  ///
  /// In en, this message translates to:
  /// **'d MMM y'**
  String get dateFormatLong;

  /// No description provided for @swipeYes.
  ///
  /// In en, this message translates to:
  /// **'I’m in'**
  String get swipeYes;

  /// No description provided for @swipeNo.
  ///
  /// In en, this message translates to:
  /// **'Nope'**
  String get swipeNo;

  /// No description provided for @swipePass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get swipePass;

  /// No description provided for @swipeDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get swipeDetails;

  /// No description provided for @swipeCrewAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s voted'**
  String get swipeCrewAllDone;

  /// No description provided for @swipeCrewProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} friends done'**
  String swipeCrewProgress(int done, int total);

  /// No description provided for @swipeNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to swipe on'**
  String get swipeNothingTitle;

  /// No description provided for @swipeNothingBody.
  ///
  /// In en, this message translates to:
  /// **'No places came back for this search. Try a wider radius or fewer filters.'**
  String get swipeNothingBody;

  /// No description provided for @swipeSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Some swipes didn’t save'**
  String get swipeSaveFailedTitle;

  /// No description provided for @placeOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get placeOpenNow;

  /// No description provided for @placeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get placeClosed;

  /// No description provided for @placeBookDineout.
  ///
  /// In en, this message translates to:
  /// **'Find a table on Dineout'**
  String get placeBookDineout;

  /// No description provided for @placeDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get placeDirections;

  /// No description provided for @placeGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get placeGetDirections;

  /// No description provided for @placeEazyDiner.
  ///
  /// In en, this message translates to:
  /// **'EazyDiner'**
  String get placeEazyDiner;

  /// No description provided for @placeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get placeWebsite;

  /// No description provided for @placeGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get placeGoogleMaps;

  /// No description provided for @placeOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get placeOpenInMaps;

  /// No description provided for @placeCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get placeCall;

  /// No description provided for @placeReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'What people say'**
  String get placeReviewsTitle;

  /// No description provided for @placeShareMessage.
  ///
  /// In en, this message translates to:
  /// **'How about {name}? {link}'**
  String placeShareMessage(String name, String link);

  /// No description provided for @resultsDecidedTitle.
  ///
  /// In en, this message translates to:
  /// **'It’s decided'**
  String get resultsDecidedTitle;

  /// No description provided for @resultsNoWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'No clear winner'**
  String get resultsNoWinnerTitle;

  /// No description provided for @resultsCrewPicked.
  ///
  /// In en, this message translates to:
  /// **'{crew} picked a place.'**
  String resultsCrewPicked(String crew);

  /// No description provided for @resultsNoYes.
  ///
  /// In en, this message translates to:
  /// **'Nobody said yes to anything this round.'**
  String get resultsNoYes;

  /// No description provided for @resultsVotes.
  ///
  /// In en, this message translates to:
  /// **'{yes} of {total} said yes'**
  String resultsVotes(int yes, int total);

  /// No description provided for @resultsNoVotes.
  ///
  /// In en, this message translates to:
  /// **'No votes recorded'**
  String get resultsNoVotes;

  /// No description provided for @resultsRunnersUp.
  ///
  /// In en, this message translates to:
  /// **'Runners-up'**
  String get resultsRunnersUp;

  /// No description provided for @resultsHowItWent.
  ///
  /// In en, this message translates to:
  /// **'How it went'**
  String get resultsHowItWent;

  /// No description provided for @resultsVoteShort.
  ///
  /// In en, this message translates to:
  /// **'{yes} yes · {no} no'**
  String resultsVoteShort(int yes, int no);

  /// No description provided for @resultsStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start another round'**
  String get resultsStartAgain;

  /// No description provided for @resultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the results.'**
  String get resultsLoadFailed;

  /// No description provided for @resultsShareMessage.
  ///
  /// In en, this message translates to:
  /// **'It’s decided: {name}. {link}'**
  String resultsShareMessage(String name, String link);

  /// No description provided for @soloPicksTitle.
  ///
  /// In en, this message translates to:
  /// **'Your picks'**
  String get soloPicksTitle;

  /// No description provided for @soloNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing grabbed you'**
  String get soloNothingTitle;

  /// No description provided for @soloLikedCount.
  ///
  /// In en, this message translates to:
  /// **'You liked {liked} of {total}.'**
  String soloLikedCount(int liked, int total);

  /// No description provided for @soloNothingBody.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{You passed on the only place.} other{You passed on all {total}.}} Try another area, or loosen the filters.'**
  String soloNothingBody(int total);

  /// No description provided for @soloPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'You passed on'**
  String get soloPassedTitle;

  /// No description provided for @soloSwipeAgain.
  ///
  /// In en, this message translates to:
  /// **'Swipe somewhere else'**
  String get soloSwipeAgain;

  /// No description provided for @billTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Split the bill'**
  String get billTileTitle;

  /// No description provided for @billTileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paid for everyone? Friends pay you back by UPI.'**
  String get billTileEmpty;

  /// No description provided for @billTileTitleWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Bill · {amount}'**
  String billTileTitleWithTotal(String amount);

  /// No description provided for @billTileYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String billTileYouOwe(String name, String amount);

  /// No description provided for @billTileSettled.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s settled up'**
  String get billTileSettled;

  /// No description provided for @billTileProgress.
  ///
  /// In en, this message translates to:
  /// **'{name} paid · {paid} of {total} settled'**
  String billTileProgress(String name, int paid, int total);

  /// No description provided for @billTitle.
  ///
  /// In en, this message translates to:
  /// **'Split the bill'**
  String get billTitle;

  /// No description provided for @billNewIntro.
  ///
  /// In en, this message translates to:
  /// **'Add what you paid and who came. Everyone sees their share and can pay you by UPI in one tap.'**
  String get billNewIntro;

  /// No description provided for @billTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total bill'**
  String get billTotalLabel;

  /// No description provided for @billTotalHint.
  ///
  /// In en, this message translates to:
  /// **'2,400'**
  String get billTotalHint;

  /// No description provided for @billTotalError.
  ///
  /// In en, this message translates to:
  /// **'Enter the total, like 2400 or 2400.50.'**
  String get billTotalError;

  /// No description provided for @billUpiLabel.
  ///
  /// In en, this message translates to:
  /// **'Your UPI ID'**
  String get billUpiLabel;

  /// No description provided for @billUpiHint.
  ///
  /// In en, this message translates to:
  /// **'yourname@okicici'**
  String get billUpiHint;

  /// No description provided for @billUpiHelper.
  ///
  /// In en, this message translates to:
  /// **'Friends pay you here. It’s saved to your profile for next time.'**
  String get billUpiHelper;

  /// No description provided for @billUpiError.
  ///
  /// In en, this message translates to:
  /// **'That doesn’t look like a UPI ID. It’s usually name@bank, like asha@okicici.'**
  String get billUpiError;

  /// No description provided for @billWhoCameTitle.
  ///
  /// In en, this message translates to:
  /// **'Who came?'**
  String get billWhoCameTitle;

  /// No description provided for @billYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get billYouPaid;

  /// No description provided for @billEachAmount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} for 1 person} other{{amount} each for {count} people}}'**
  String billEachAmount(int count, String amount);

  /// No description provided for @billEachUneven.
  ///
  /// In en, this message translates to:
  /// **'{high} or {low} each for {count} people'**
  String billEachUneven(String high, String low, int count);

  /// No description provided for @billCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Split {amount}'**
  String billCreateButton(String amount);

  /// No description provided for @billCreateButtonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Split the bill'**
  String get billCreateButtonEmpty;

  /// No description provided for @billAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Someone already added the bill for this hangout.'**
  String get billAlreadyExists;

  /// No description provided for @billNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only the person who paid can change this bill.'**
  String get billNotAllowed;

  /// No description provided for @billNotRevealed.
  ///
  /// In en, this message translates to:
  /// **'The bill opens once the winner is revealed.'**
  String get billNotRevealed;

  /// No description provided for @billEditMustAddUp.
  ///
  /// In en, this message translates to:
  /// **'The amounts have to add up to the total.'**
  String get billEditMustAddUp;

  /// No description provided for @billPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String billPaidBy(String name);

  /// No description provided for @billPaidByYou.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get billPaidByYou;

  /// No description provided for @billAt.
  ///
  /// In en, this message translates to:
  /// **'at {place}'**
  String billAt(String place);

  /// No description provided for @billSettledProgress.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} settled'**
  String billSettledProgress(int paid, int total);

  /// No description provided for @billYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String billYouOwe(String name, String amount);

  /// No description provided for @billPayTo.
  ///
  /// In en, this message translates to:
  /// **'To {upi}'**
  String billPayTo(String upi);

  /// No description provided for @billPayWithUpi.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} with UPI'**
  String billPayWithUpi(String amount);

  /// No description provided for @billIvePaid.
  ///
  /// In en, this message translates to:
  /// **'I’ve paid'**
  String get billIvePaid;

  /// No description provided for @billUpiNote.
  ///
  /// In en, this message translates to:
  /// **'Hangout bill'**
  String get billUpiNote;

  /// No description provided for @billUpiNoteAt.
  ///
  /// In en, this message translates to:
  /// **'Hangout · {place}'**
  String billUpiNoteAt(String place);

  /// No description provided for @billNoUpiApp.
  ///
  /// In en, this message translates to:
  /// **'No UPI app opened. Pay {upi} from any UPI app, then tap “I’ve paid”.'**
  String billNoUpiApp(String upi);

  /// No description provided for @billAfterPayHint.
  ///
  /// In en, this message translates to:
  /// **'Paid? Tap “I’ve paid” so {name} knows.'**
  String billAfterPayHint(String name);

  /// No description provided for @billYoureSettled.
  ///
  /// In en, this message translates to:
  /// **'You’re settled up'**
  String get billYoureSettled;

  /// No description provided for @billCollectAt.
  ///
  /// In en, this message translates to:
  /// **'Friends pay you at {upi}'**
  String billCollectAt(String upi);

  /// No description provided for @billAllSettled.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s paid you back'**
  String get billAllSettled;

  /// No description provided for @billWaitingOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Waiting on 1 person} other{Waiting on {count} people}}'**
  String billWaitingOn(int count);

  /// No description provided for @billRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind on WhatsApp'**
  String get billRemind;

  /// No description provided for @billRemindMessage.
  ///
  /// In en, this message translates to:
  /// **'Settling up for our hangout: your share is in Hangout. Pay me on UPI at {upi}.'**
  String billRemindMessage(String upi);

  /// No description provided for @billRemindMessageAt.
  ///
  /// In en, this message translates to:
  /// **'Settling up for {place}: your share is in Hangout. Pay me on UPI at {upi}.'**
  String billRemindMessageAt(String place, String upi);

  /// No description provided for @billSharesTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s share'**
  String get billSharesTitle;

  /// No description provided for @billStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billStatusPaid;

  /// No description provided for @billStatusOwes.
  ///
  /// In en, this message translates to:
  /// **'Hasn’t paid yet'**
  String get billStatusOwes;

  /// No description provided for @billStatusPayer.
  ///
  /// In en, this message translates to:
  /// **'Paid the bill'**
  String get billStatusPayer;

  /// No description provided for @billChangeAmounts.
  ///
  /// In en, this message translates to:
  /// **'Change amounts'**
  String get billChangeAmounts;

  /// No description provided for @billDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get billDelete;

  /// No description provided for @billDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this bill?'**
  String get billDeleteTitle;

  /// No description provided for @billDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s shares and paid marks go with it.'**
  String get billDeleteBody;

  /// No description provided for @billMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get billMarkPaid;

  /// No description provided for @billMarkUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as not paid'**
  String get billMarkUnpaid;

  /// No description provided for @billEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change amounts'**
  String get billEditTitle;

  /// No description provided for @billEditTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String billEditTotal(String amount);

  /// No description provided for @billEditLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to assign'**
  String billEditLeft(String amount);

  /// No description provided for @billEditOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over the total'**
  String billEditOver(String amount);

  /// No description provided for @billEditAddsUp.
  ///
  /// In en, this message translates to:
  /// **'Adds up to the total'**
  String get billEditAddsUp;

  /// No description provided for @billEditEvenly.
  ///
  /// In en, this message translates to:
  /// **'Split evenly'**
  String get billEditEvenly;

  /// No description provided for @billEditAmountError.
  ///
  /// In en, this message translates to:
  /// **'Use numbers only, like 450 or 450.50.'**
  String get billEditAmountError;

  /// No description provided for @billLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the bill.'**
  String get billLoadFailed;

  /// No description provided for @revealAllDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s voted'**
  String get revealAllDoneTitle;

  /// No description provided for @revealWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting on the crew'**
  String get revealWaitingTitle;

  /// No description provided for @revealHostReady.
  ///
  /// In en, this message translates to:
  /// **'Reveal the winner when you’re ready.'**
  String get revealHostReady;

  /// No description provided for @revealHostEarly.
  ///
  /// In en, this message translates to:
  /// **'You can reveal now, or wait for everyone to finish.'**
  String get revealHostEarly;

  /// No description provided for @revealGuestBody.
  ///
  /// In en, this message translates to:
  /// **'{host} reveals the winner. You’ll see it here the moment they do.'**
  String revealGuestBody(String host);

  /// No description provided for @revealTheHost.
  ///
  /// In en, this message translates to:
  /// **'The host'**
  String get revealTheHost;

  /// No description provided for @revealProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String revealProgress(int done, int total);

  /// No description provided for @revealMemberDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get revealMemberDone;

  /// No description provided for @revealMemberSwiping.
  ///
  /// In en, this message translates to:
  /// **'Still swiping'**
  String get revealMemberSwiping;

  /// No description provided for @revealButton.
  ///
  /// In en, this message translates to:
  /// **'Reveal the winner'**
  String get revealButton;

  /// No description provided for @revealEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal now?'**
  String get revealEarlyTitle;

  /// No description provided for @revealEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person hasn’t finished. Their votes so far will count.} other{{count} people haven’t finished. Their votes so far will count.}}'**
  String revealEarlyBody(int count);

  /// No description provided for @revealEarlyWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get revealEarlyWait;

  /// No description provided for @revealEarlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get revealEarlyConfirm;

  /// No description provided for @revealFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reveal the winner. Check your connection and try again.'**
  String get revealFailed;

  /// No description provided for @lobbyEveryoneIn.
  ///
  /// In en, this message translates to:
  /// **'Everyone’s in'**
  String get lobbyEveryoneIn;

  /// No description provided for @lobbyDropPins.
  ///
  /// In en, this message translates to:
  /// **'Drop your pins'**
  String get lobbyDropPins;

  /// No description provided for @lobbySubtitleFood.
  ///
  /// In en, this message translates to:
  /// **'{crew} · somewhere to eat'**
  String lobbySubtitleFood(String crew);

  /// No description provided for @lobbySubtitlePlaces.
  ///
  /// In en, this message translates to:
  /// **'{crew} · somewhere to go'**
  String lobbySubtitlePlaces(String crew);

  /// No description provided for @lobbyMidpoint.
  ///
  /// In en, this message translates to:
  /// **'We search around the middle of everyone’s pins, so nobody has to cross town.'**
  String get lobbyMidpoint;

  /// No description provided for @lobbyMyPin.
  ///
  /// In en, this message translates to:
  /// **'My pin'**
  String get lobbyMyPin;

  /// No description provided for @lobbyPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save that pin.'**
  String get lobbyPinFailed;

  /// No description provided for @lobbyPinDropped.
  ///
  /// In en, this message translates to:
  /// **'Pin dropped'**
  String get lobbyPinDropped;

  /// No description provided for @lobbyNoPinYet.
  ///
  /// In en, this message translates to:
  /// **'Hasn’t dropped a pin yet'**
  String get lobbyNoPinYet;

  /// No description provided for @lobbyMovePin.
  ///
  /// In en, this message translates to:
  /// **'Move my pin'**
  String get lobbyMovePin;

  /// No description provided for @lobbyDropPin.
  ///
  /// In en, this message translates to:
  /// **'Drop my pin'**
  String get lobbyDropPin;

  /// No description provided for @lobbyFindingPlaces.
  ///
  /// In en, this message translates to:
  /// **'Finding places…'**
  String get lobbyFindingPlaces;

  /// No description provided for @lobbyStartSwiping.
  ///
  /// In en, this message translates to:
  /// **'Start swiping'**
  String get lobbyStartSwiping;

  /// No description provided for @lobbyStartWithPins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Start with 1 pin} other{Start with {count} pins}}'**
  String lobbyStartWithPins(int count);

  /// No description provided for @lobbyStartEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start without everyone?'**
  String get lobbyStartEarlyTitle;

  /// No description provided for @lobbyStartEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person hasn’t dropped a pin. We’ll search around the pins that are in, and they can still swipe.} other{{count} people haven’t dropped a pin. We’ll search around the pins that are in, and they can still swipe.}}'**
  String lobbyStartEarlyBody(int count);

  /// No description provided for @lobbyStartEarlyWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get lobbyStartEarlyWait;

  /// No description provided for @lobbyStartEarlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get lobbyStartEarlyConfirm;

  /// No description provided for @lobbyWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start'**
  String get lobbyWaitingForHost;

  /// No description provided for @lobbyWaitingOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Waiting on 1 more} other{Waiting on {count} more}}'**
  String lobbyWaitingOn(int count);

  /// No description provided for @lobbyNothingFoodNearby.
  ///
  /// In en, this message translates to:
  /// **'No restaurants near the crew’s pins. Try a wider radius.'**
  String get lobbyNothingFoodNearby;

  /// No description provided for @lobbyNothingNearby.
  ///
  /// In en, this message translates to:
  /// **'No places near the crew’s pins. Try a wider radius.'**
  String get lobbyNothingNearby;

  /// No description provided for @crewSessionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load that session.'**
  String get crewSessionLoadFailed;

  /// No description provided for @crewCodeRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t get a new code.'**
  String get crewCodeRefreshFailed;

  /// No description provided for @crewCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get crewCodeCopied;

  /// No description provided for @crewInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my Hangout crew *{crew}*\n\nInvite code: *{code}*\n\nGet Hangout and punch in the code.'**
  String crewInviteMessage(String crew, String code);

  /// No description provided for @crewInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied. Paste it anywhere.'**
  String get crewInviteCopied;

  /// No description provided for @crewDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this crew?'**
  String get crewDeleteTitle;

  /// No description provided for @crewLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this crew?'**
  String get crewLeaveTitle;

  /// No description provided for @crewDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes “{crew}” for everyone.'**
  String crewDeleteBody(String crew);

  /// No description provided for @crewLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You’ll drop out of “{crew}”.'**
  String crewLeaveBody(String crew);

  /// No description provided for @crewLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get crewLeave;

  /// No description provided for @crewDeleteMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete crew'**
  String get crewDeleteMenu;

  /// No description provided for @crewLeaveMenu.
  ///
  /// In en, this message translates to:
  /// **'Leave crew'**
  String get crewLeaveMenu;

  /// No description provided for @crewMetaFood.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Food · 1 person} other{Food · {count} people}}'**
  String crewMetaFood(int count);

  /// No description provided for @crewMetaPlaces.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Places · 1 person} other{Places · {count} people}}'**
  String crewMetaPlaces(int count);

  /// No description provided for @crewInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get crewInviteTitle;

  /// No description provided for @crewMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'The crew'**
  String get crewMembersTitle;

  /// No description provided for @crewPastTitle.
  ///
  /// In en, this message translates to:
  /// **'Past hangouts'**
  String get crewPastTitle;

  /// No description provided for @crewFindFood.
  ///
  /// In en, this message translates to:
  /// **'Find somewhere to eat'**
  String get crewFindFood;

  /// No description provided for @crewFindPlace.
  ///
  /// In en, this message translates to:
  /// **'Find somewhere to go'**
  String get crewFindPlace;

  /// No description provided for @crewSessionSetup.
  ///
  /// In en, this message translates to:
  /// **'Waiting for everyone to drop a pin'**
  String get crewSessionSetup;

  /// No description provided for @crewSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get crewSessionOpen;

  /// No description provided for @crewSessionSwiping.
  ///
  /// In en, this message translates to:
  /// **'Swiping has started'**
  String get crewSessionSwiping;

  /// No description provided for @crewSessionSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get crewSessionSwipe;

  /// No description provided for @crewPickingFood.
  ///
  /// In en, this message translates to:
  /// **'Picking somewhere to eat'**
  String get crewPickingFood;

  /// No description provided for @crewPickingPlace.
  ///
  /// In en, this message translates to:
  /// **'Picking somewhere to go'**
  String get crewPickingPlace;

  /// No description provided for @crewInviteCodeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Invite code {code}'**
  String crewInviteCodeSemantics(String code);

  /// No description provided for @crewInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Friends join with this code'**
  String get crewInviteHint;

  /// No description provided for @crewCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get crewCopyCode;

  /// No description provided for @crewShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get crewShareInvite;

  /// No description provided for @crewNewCode.
  ///
  /// In en, this message translates to:
  /// **'Get a new code'**
  String get crewNewCode;

  /// No description provided for @crewNewCodeLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting a new code…'**
  String get crewNewCodeLoading;

  /// No description provided for @memoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoriesTitle;

  /// No description provided for @memoriesSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Where your crews ended up'**
  String get memoriesSubtitleEmpty;

  /// No description provided for @memoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hangout so far} other{{count} hangouts so far}}'**
  String memoriesCount(int count);

  /// No description provided for @memoriesEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get memoriesEarlier;

  /// No description provided for @memoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get memoriesEmptyTitle;

  /// No description provided for @memoriesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When a crew lands on a winner, it’s saved here: where you went, who came, and how close the vote was.'**
  String get memoriesEmptyBody;

  /// No description provided for @memoriesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading memories'**
  String get memoriesLoading;

  /// No description provided for @memoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your hangouts.'**
  String get memoriesLoadFailed;

  /// No description provided for @memoryNoWinner.
  ///
  /// In en, this message translates to:
  /// **'No winner'**
  String get memoryNoWinner;

  /// No description provided for @memoryNoWinnerLong.
  ///
  /// In en, this message translates to:
  /// **'No winner this time'**
  String get memoryNoWinnerLong;

  /// No description provided for @memoryOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open that hangout.'**
  String get memoryOpenFailed;

  /// No description provided for @memoryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from your memories'**
  String get memoryRemoved;

  /// No description provided for @memoryJustYou.
  ///
  /// In en, this message translates to:
  /// **'Just you'**
  String get memoryJustYou;

  /// No description provided for @memoryMeta.
  ///
  /// In en, this message translates to:
  /// **'{who} · {date}'**
  String memoryMeta(String who, String date);

  /// No description provided for @memoryDidntGo.
  ///
  /// In en, this message translates to:
  /// **'Didn’t go'**
  String get memoryDidntGo;

  /// No description provided for @memoryNobodyYes.
  ///
  /// In en, this message translates to:
  /// **'Nobody said yes to anything'**
  String get memoryNobodyYes;

  /// No description provided for @memoryVotesShort.
  ///
  /// In en, this message translates to:
  /// **'{yes}/{total}'**
  String memoryVotesShort(int yes, int total);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileTitle;

  /// No description provided for @profileHangouts.
  ///
  /// In en, this message translates to:
  /// **'Hangouts'**
  String get profileHangouts;

  /// No description provided for @profileCrews.
  ///
  /// In en, this message translates to:
  /// **'Crews'**
  String get profileCrews;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit name and avatar'**
  String get profileEdit;

  /// No description provided for @profileUpiAdd.
  ///
  /// In en, this message translates to:
  /// **'Add your UPI ID'**
  String get profileUpiAdd;

  /// No description provided for @profileUpiHint.
  ///
  /// In en, this message translates to:
  /// **'Where friends pay you back'**
  String get profileUpiHint;

  /// No description provided for @profileUpiSheetBody.
  ///
  /// In en, this message translates to:
  /// **'When you pay for the crew, friends pay you back here.'**
  String get profileUpiSheetBody;

  /// No description provided for @profileLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get profileLicences;

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogOut;

  /// No description provided for @setupAlreadyDecidingTitle.
  ///
  /// In en, this message translates to:
  /// **'Already deciding'**
  String get setupAlreadyDecidingTitle;

  /// No description provided for @setupAlreadyDecidingBody.
  ///
  /// In en, this message translates to:
  /// **'{crew} has a hangout going. Join that one instead of starting another.'**
  String setupAlreadyDecidingBody(String crew);

  /// No description provided for @setupAlreadyDecidingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get setupAlreadyDecidingOpen;

  /// No description provided for @setupNeedPlace.
  ///
  /// In en, this message translates to:
  /// **'Drop a pin, or type an area name.'**
  String get setupNeedPlace;

  /// No description provided for @setupNothingFood.
  ///
  /// In en, this message translates to:
  /// **'Nothing open around there. Try a wider radius?'**
  String get setupNothingFood;

  /// No description provided for @setupNothingPlaces.
  ///
  /// In en, this message translates to:
  /// **'Nothing around there. Try a wider radius?'**
  String get setupNothingPlaces;

  /// No description provided for @setupAreaNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find that area. Try adding the city.'**
  String get setupAreaNotFound;

  /// No description provided for @setupJustMe.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get setupJustMe;

  /// No description provided for @setupGroupTitleFood.
  ///
  /// In en, this message translates to:
  /// **'Find food together'**
  String get setupGroupTitleFood;

  /// No description provided for @setupGroupTitlePlaces.
  ///
  /// In en, this message translates to:
  /// **'Find a spot together'**
  String get setupGroupTitlePlaces;

  /// No description provided for @setupHowItGoes.
  ///
  /// In en, this message translates to:
  /// **'Here’s how it goes.'**
  String get setupHowItGoes;

  /// No description provided for @setupStepPins.
  ///
  /// In en, this message translates to:
  /// **'Everyone drops a pin in the lobby'**
  String get setupStepPins;

  /// No description provided for @setupStepSwipe.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You swipe the places} =2{Both of you swipe the same places} other{All {count} of you swipe the same places}}'**
  String setupStepSwipe(int count);

  /// No description provided for @setupStepReveal.
  ///
  /// In en, this message translates to:
  /// **'You reveal the winner when the crew’s done'**
  String get setupStepReveal;

  /// No description provided for @setupOpenLobby.
  ///
  /// In en, this message translates to:
  /// **'Open the lobby'**
  String get setupOpenLobby;

  /// No description provided for @setupSoloTitleFood.
  ///
  /// In en, this message translates to:
  /// **'Where are you eating?'**
  String get setupSoloTitleFood;

  /// No description provided for @setupSoloTitlePlaces.
  ///
  /// In en, this message translates to:
  /// **'Where are you headed?'**
  String get setupSoloTitlePlaces;

  /// No description provided for @setupPinDropped.
  ///
  /// In en, this message translates to:
  /// **'Pin dropped'**
  String get setupPinDropped;

  /// No description provided for @setupPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on the map'**
  String get setupPickOnMap;

  /// No description provided for @setupPickOnMapHint.
  ///
  /// In en, this message translates to:
  /// **'Open the map and drop a pin'**
  String get setupPickOnMapHint;

  /// No description provided for @setupOrTypeArea.
  ///
  /// In en, this message translates to:
  /// **'or type an area'**
  String get setupOrTypeArea;

  /// No description provided for @setupAreaHintFood.
  ///
  /// In en, this message translates to:
  /// **'Banjara Hills, Hyderabad'**
  String get setupAreaHintFood;

  /// No description provided for @setupAreaHintPlaces.
  ///
  /// In en, this message translates to:
  /// **'Charminar, Hyderabad'**
  String get setupAreaHintPlaces;

  /// No description provided for @setupFindFood.
  ///
  /// In en, this message translates to:
  /// **'Find places to eat'**
  String get setupFindFood;

  /// No description provided for @setupFindPlaces.
  ///
  /// In en, this message translates to:
  /// **'Find places to go'**
  String get setupFindPlaces;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCrews.
  ///
  /// In en, this message translates to:
  /// **'Crews'**
  String get navCrews;

  /// No description provided for @navMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get navMemories;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @navStartHangout.
  ///
  /// In en, this message translates to:
  /// **'Start a hangout'**
  String get navStartHangout;

  /// No description provided for @startSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What are we deciding?'**
  String get startSheetTitle;

  /// No description provided for @startSheetFood.
  ///
  /// In en, this message translates to:
  /// **'Somewhere to eat'**
  String get startSheetFood;

  /// No description provided for @startSheetFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Restaurants, cafés, bars'**
  String get startSheetFoodHint;

  /// No description provided for @startSheetPlaces.
  ///
  /// In en, this message translates to:
  /// **'Somewhere to go'**
  String get startSheetPlaces;

  /// No description provided for @startSheetPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Parks, museums, days out'**
  String get startSheetPlacesHint;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get homeProfile;

  /// No description provided for @homeGreetingDay.
  ///
  /// In en, this message translates to:
  /// **'Where to today?'**
  String get homeGreetingDay;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Where to tonight?'**
  String get homeGreetingNight;

  /// No description provided for @homeEat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get homeEat;

  /// No description provided for @homeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeExplore;

  /// No description provided for @homeLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time'**
  String get homeLastTime;

  /// No description provided for @homeAllMemories.
  ///
  /// In en, this message translates to:
  /// **'All memories'**
  String get homeAllMemories;

  /// No description provided for @homeOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open that hangout. Try again.'**
  String get homeOpenFailed;

  /// No description provided for @homeSwipingFood.
  ///
  /// In en, this message translates to:
  /// **'Swiping for somewhere to eat'**
  String get homeSwipingFood;

  /// No description provided for @homeSwipingPlaces.
  ///
  /// In en, this message translates to:
  /// **'Swiping for somewhere to go'**
  String get homeSwipingPlaces;

  /// No description provided for @homePinsFood.
  ///
  /// In en, this message translates to:
  /// **'Dropping pins for somewhere to eat'**
  String get homePinsFood;

  /// No description provided for @homePinsPlaces.
  ///
  /// In en, this message translates to:
  /// **'Dropping pins for somewhere to go'**
  String get homePinsPlaces;

  /// No description provided for @crewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Crews'**
  String get crewsTitle;

  /// No description provided for @crewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The people you decide with.'**
  String get crewsSubtitle;

  /// No description provided for @crewsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get crewsJoin;

  /// No description provided for @crewsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get crewsNew;

  /// No description provided for @crewsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your crews'**
  String get crewsLoading;

  /// No description provided for @crewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No crews yet'**
  String get crewsEmptyTitle;

  /// No description provided for @crewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A crew is the group you decide with. Start one and share the code, or join a friend’s.'**
  String get crewsEmptyBody;

  /// No description provided for @crewsStart.
  ///
  /// In en, this message translates to:
  /// **'Start a crew'**
  String get crewsStart;

  /// No description provided for @crewsJoinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get crewsJoinWithCode;

  /// No description provided for @crewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your crews'**
  String get crewsLoadFailed;

  /// No description provided for @crewsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get crewsRetry;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a crew'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-character code your friend shared.'**
  String get joinSubtitle;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join crew'**
  String get joinButton;

  /// No description provided for @joinNotFound.
  ///
  /// In en, this message translates to:
  /// **'That code didn’t match a crew. Check it and try again.'**
  String get joinNotFound;

  /// No description provided for @joinFull.
  ///
  /// In en, this message translates to:
  /// **'“{crew}” is full. Crews top out at 10 people.'**
  String joinFull(String crew);

  /// No description provided for @modeTitleFood.
  ///
  /// In en, this message translates to:
  /// **'Where to eat'**
  String get modeTitleFood;

  /// No description provided for @modeTitlePlaces.
  ///
  /// In en, this message translates to:
  /// **'Where to go'**
  String get modeTitlePlaces;

  /// No description provided for @modeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick who’s deciding.'**
  String get modeSubtitle;

  /// No description provided for @modeWithCrew.
  ///
  /// In en, this message translates to:
  /// **'With a crew'**
  String get modeWithCrew;

  /// No description provided for @modeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get modeStart;

  /// No description provided for @modeOnYourOwn.
  ///
  /// In en, this message translates to:
  /// **'On your own'**
  String get modeOnYourOwn;

  /// No description provided for @modeJustMeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe solo and decide fast'**
  String get modeJustMeHint;

  /// No description provided for @modeNoCrewsFood.
  ///
  /// In en, this message translates to:
  /// **'No food crews yet'**
  String get modeNoCrewsFood;

  /// No description provided for @modeNoCrewsPlaces.
  ///
  /// In en, this message translates to:
  /// **'No explore crews yet'**
  String get modeNoCrewsPlaces;

  /// No description provided for @modeNoCrewsBody.
  ///
  /// In en, this message translates to:
  /// **'Start one, share the code, and everyone swipes on the same places.'**
  String get modeNoCrewsBody;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String memberCount(int count);

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'New crew'**
  String get createTitle;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The people you decide with. You’ll get a code to share.'**
  String get createSubtitle;

  /// No description provided for @createDecideLabel.
  ///
  /// In en, this message translates to:
  /// **'What will you decide?'**
  String get createDecideLabel;

  /// No description provided for @createModeFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get createModeFood;

  /// No description provided for @createModePlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get createModePlaces;

  /// No description provided for @createNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Crew name'**
  String get createNameLabel;

  /// No description provided for @createNameHintFood.
  ///
  /// In en, this message translates to:
  /// **'Friday dinner lot'**
  String get createNameHintFood;

  /// No description provided for @createNameHintPlaces.
  ///
  /// In en, this message translates to:
  /// **'Weekend wanderers'**
  String get createNameHintPlaces;

  /// No description provided for @createNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give the crew a name'**
  String get createNameEmpty;

  /// No description provided for @createNameShort.
  ///
  /// In en, this message translates to:
  /// **'A bit longer than that'**
  String get createNameShort;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create crew'**
  String get createButton;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'We should hang out sometime.'**
  String get loginHeadline;

  /// No description provided for @loginBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe on places with your crew. Everyone votes, one spot wins.'**
  String get loginBody;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginOrPhone.
  ///
  /// In en, this message translates to:
  /// **'or use your phone'**
  String get loginOrPhone;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get loginPhoneHint;

  /// No description provided for @loginPhoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get loginPhoneEmpty;

  /// No description provided for @loginPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'That’s not a 10-digit number'**
  String get loginPhoneInvalid;

  /// No description provided for @loginSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get loginSendCode;

  /// No description provided for @loginGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn’t work. Try again?'**
  String get loginGoogleFailed;

  /// No description provided for @loginSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t send that code. Check the number and try again.'**
  String get loginSendFailed;

  /// No description provided for @loginLegal.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the {terms} and {privacy}.'**
  String loginLegal(String terms, String privacy);

  /// No description provided for @loginTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get loginTerms;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get loginPrivacy;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We texted a 6-digit code to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get otpVerify;

  /// No description provided for @otpWrong.
  ///
  /// In en, this message translates to:
  /// **'That code didn’t match. Try again.'**
  String get otpWrong;

  /// No description provided for @otpResendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t resend that code.'**
  String get otpResendFailed;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'Code sent again'**
  String get otpResent;

  /// No description provided for @otpDidntGetIt.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get it?'**
  String get otpDidntGetIt;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpDigit.
  ///
  /// In en, this message translates to:
  /// **'Digit {position} of 6'**
  String otpDigit(int position);

  /// No description provided for @avatarNeedNickname.
  ///
  /// In en, this message translates to:
  /// **'Pick a nickname first'**
  String get avatarNeedNickname;

  /// No description provided for @avatarSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save that. Check your connection and try again.'**
  String get avatarSaveFailed;

  /// No description provided for @avatarEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get avatarEditTitle;

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get avatarTitle;

  /// No description provided for @avatarBody.
  ///
  /// In en, this message translates to:
  /// **'This is how your crews will see you. You can change it later.'**
  String get avatarBody;

  /// No description provided for @avatarNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get avatarNicknameLabel;

  /// No description provided for @avatarNicknameHelper.
  ///
  /// In en, this message translates to:
  /// **'Shuffle for a new one, or type your own.'**
  String get avatarNicknameHelper;

  /// No description provided for @avatarNewNickname.
  ///
  /// In en, this message translates to:
  /// **'New nickname'**
  String get avatarNewNickname;

  /// No description provided for @avatarLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let’s go'**
  String get avatarLetsGo;

  /// No description provided for @avatarPick.
  ///
  /// In en, this message translates to:
  /// **'Avatar {name}'**
  String avatarPick(String name);

  /// No description provided for @pickerSearchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get pickerSearchHere;

  /// No description provided for @pickerTapMap.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop a pin'**
  String get pickerTapMap;

  /// No description provided for @pickerMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get pickerMyLocation;

  /// No description provided for @pickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Search around here'**
  String get pickerConfirm;

  /// No description provided for @pickerLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to use where you are.'**
  String get pickerLocationOff;

  /// No description provided for @pickerLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off. You can still tap the map.'**
  String get pickerLocationDenied;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Narrow it down'**
  String get filtersTitle;

  /// No description provided for @filtersBody.
  ///
  /// In en, this message translates to:
  /// **'Everything here is optional.'**
  String get filtersBody;

  /// No description provided for @filtersCraving.
  ///
  /// In en, this message translates to:
  /// **'Craving'**
  String get filtersCraving;

  /// No description provided for @filtersCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get filtersCategories;

  /// No description provided for @filtersPickFew.
  ///
  /// In en, this message translates to:
  /// **'Pick a few, or leave it open.'**
  String get filtersPickFew;

  /// No description provided for @filtersBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get filtersBudget;

  /// No description provided for @filtersBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Skip anything pricier.'**
  String get filtersBudgetHint;

  /// No description provided for @filtersAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filtersAny;

  /// No description provided for @filtersOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get filtersOpenNow;

  /// No description provided for @filtersOpenNowHint.
  ///
  /// In en, this message translates to:
  /// **'Only somewhere you can walk into.'**
  String get filtersOpenNowHint;

  /// No description provided for @filtersOpenNowSwitch.
  ///
  /// In en, this message translates to:
  /// **'Only places open now'**
  String get filtersOpenNowSwitch;

  /// No description provided for @filtersHowFar.
  ///
  /// In en, this message translates to:
  /// **'How far'**
  String get filtersHowFar;

  /// No description provided for @filtersHowFarHint.
  ///
  /// In en, this message translates to:
  /// **'{km} km from your spot.'**
  String filtersHowFarHint(int km);

  /// No description provided for @filtersKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String filtersKm(int km);

  /// No description provided for @catPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get catPizza;

  /// No description provided for @catBurgers.
  ///
  /// In en, this message translates to:
  /// **'Burgers'**
  String get catBurgers;

  /// No description provided for @catSushi.
  ///
  /// In en, this message translates to:
  /// **'Sushi'**
  String get catSushi;

  /// No description provided for @catNoodles.
  ///
  /// In en, this message translates to:
  /// **'Noodles'**
  String get catNoodles;

  /// No description provided for @catBiryani.
  ///
  /// In en, this message translates to:
  /// **'Biryani'**
  String get catBiryani;

  /// No description provided for @catArabian.
  ///
  /// In en, this message translates to:
  /// **'Arabian'**
  String get catArabian;

  /// No description provided for @catCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get catCafe;

  /// No description provided for @catBrewery.
  ///
  /// In en, this message translates to:
  /// **'Brewery'**
  String get catBrewery;

  /// No description provided for @catNorthIndian.
  ///
  /// In en, this message translates to:
  /// **'North Indian'**
  String get catNorthIndian;

  /// No description provided for @catSouthIndian.
  ///
  /// In en, this message translates to:
  /// **'South Indian'**
  String get catSouthIndian;

  /// No description provided for @catBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get catBreakfast;

  /// No description provided for @catDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get catDesserts;

  /// No description provided for @catMuseums.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get catMuseums;

  /// No description provided for @catParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get catParks;

  /// No description provided for @catAmusement.
  ///
  /// In en, this message translates to:
  /// **'Amusement'**
  String get catAmusement;

  /// No description provided for @catGalleries.
  ///
  /// In en, this message translates to:
  /// **'Art galleries'**
  String get catGalleries;

  /// No description provided for @catHistoric.
  ///
  /// In en, this message translates to:
  /// **'Historic sites'**
  String get catHistoric;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @notifyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifyOpen;
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
