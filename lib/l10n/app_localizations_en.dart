// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hangout';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionMore => 'More';

  @override
  String get actionSave => 'Save';

  @override
  String get actionShare => 'Share';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionUndo => 'Undo';

  @override
  String get badgeHost => 'Host';

  @override
  String get badgeOwner => 'Owner';

  @override
  String get badgeYou => 'You';

  @override
  String nameYou(String name) {
    return '$name (you)';
  }

  @override
  String countOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String get errorGeneric =>
      'That didn’t work. Check your connection and try again.';

  @override
  String get errorCheckConnection => 'Check your connection and try again.';

  @override
  String get linkOpenFailed => 'Couldn’t open that link.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateFormatShort => 'd MMM';

  @override
  String get dateFormatLong => 'd MMM y';

  @override
  String get swipeYes => 'I’m in';

  @override
  String get swipeNo => 'Nope';

  @override
  String get swipePass => 'Pass';

  @override
  String get swipeDetails => 'Details';

  @override
  String get swipeCrewAllDone => 'Everyone’s voted';

  @override
  String swipeCrewProgress(int done, int total) {
    return '$done of $total friends done';
  }

  @override
  String get swipeNothingTitle => 'Nothing to swipe on';

  @override
  String get swipeNothingBody =>
      'No places came back for this search. Try a wider radius or fewer filters.';

  @override
  String get swipeSaveFailedTitle => 'Some swipes didn’t save';

  @override
  String get placeOpenNow => 'Open now';

  @override
  String get placeClosed => 'Closed';

  @override
  String get placeBookDineout => 'Find a table on Dineout';

  @override
  String get placeDirections => 'Directions';

  @override
  String get placeGetDirections => 'Get directions';

  @override
  String get placeEazyDiner => 'EazyDiner';

  @override
  String get placeWebsite => 'Website';

  @override
  String get placeGoogleMaps => 'Maps';

  @override
  String get placeOpenInMaps => 'Open in Maps';

  @override
  String get placeCall => 'Call';

  @override
  String get placeReviewsTitle => 'What people say';

  @override
  String placeShareMessage(String name, String link) {
    return 'How about $name? $link';
  }

  @override
  String get resultsDecidedTitle => 'It’s decided';

  @override
  String get resultsNoWinnerTitle => 'No clear winner';

  @override
  String resultsCrewPicked(String crew) {
    return '$crew picked a place.';
  }

  @override
  String get resultsNoYes => 'Nobody said yes to anything this round.';

  @override
  String resultsVotes(int yes, int total) {
    return '$yes of $total said yes';
  }

  @override
  String get resultsNoVotes => 'No votes recorded';

  @override
  String get resultsRunnersUp => 'Runners-up';

  @override
  String get resultsHowItWent => 'How it went';

  @override
  String resultsVoteShort(int yes, int no) {
    return '$yes yes · $no no';
  }

  @override
  String get resultsStartAgain => 'Start another round';

  @override
  String get resultsLoadFailed => 'Couldn’t load the results.';

  @override
  String resultsShareMessage(String name, String link) {
    return 'It’s decided: $name. $link';
  }

  @override
  String get soloPicksTitle => 'Your picks';

  @override
  String get soloNothingTitle => 'Nothing grabbed you';

  @override
  String soloLikedCount(int liked, int total) {
    return 'You liked $liked of $total.';
  }

  @override
  String soloNothingBody(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'You passed on all $total.',
      one: 'You passed on the only place.',
    );
    return '$_temp0 Try another area, or loosen the filters.';
  }

  @override
  String get soloPassedTitle => 'You passed on';

  @override
  String get soloSwipeAgain => 'Swipe somewhere else';

  @override
  String get billTileTitle => 'Split the bill';

  @override
  String get billTileEmpty => 'Paid for everyone? Friends pay you back by UPI.';

  @override
  String billTileTitleWithTotal(String amount) {
    return 'Bill · $amount';
  }

  @override
  String billTileYouOwe(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String get billTileSettled => 'Everyone’s settled up';

  @override
  String billTileProgress(String name, int paid, int total) {
    return '$name paid · $paid of $total settled';
  }

  @override
  String get billTitle => 'Split the bill';

  @override
  String get billNewIntro =>
      'Add what you paid and who came. Everyone sees their share and can pay you by UPI in one tap.';

  @override
  String get billTotalLabel => 'Total bill';

  @override
  String get billTotalHint => '2,400';

  @override
  String get billTotalError => 'Enter the total, like 2400 or 2400.50.';

  @override
  String get billUpiLabel => 'Your UPI ID';

  @override
  String get billUpiHint => 'yourname@okicici';

  @override
  String get billUpiHelper =>
      'Friends pay you here. It’s saved to your profile for next time.';

  @override
  String get billUpiError =>
      'That doesn’t look like a UPI ID. It’s usually name@bank, like asha@okicici.';

  @override
  String get billWhoCameTitle => 'Who came?';

  @override
  String get billYouPaid => 'You paid';

  @override
  String billEachAmount(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount each for $count people',
      one: '$amount for 1 person',
    );
    return '$_temp0';
  }

  @override
  String billEachUneven(String high, String low, int count) {
    return '$high or $low each for $count people';
  }

  @override
  String billCreateButton(String amount) {
    return 'Split $amount';
  }

  @override
  String get billCreateButtonEmpty => 'Split the bill';

  @override
  String get billAlreadyExists =>
      'Someone already added the bill for this hangout.';

  @override
  String get billNotAllowed => 'Only the person who paid can change this bill.';

  @override
  String get billNotRevealed => 'The bill opens once the winner is revealed.';

  @override
  String get billEditMustAddUp => 'The amounts have to add up to the total.';

  @override
  String billPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get billPaidByYou => 'You paid';

  @override
  String billAt(String place) {
    return 'at $place';
  }

  @override
  String billSettledProgress(int paid, int total) {
    return '$paid of $total settled';
  }

  @override
  String billYouOwe(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String billPayTo(String upi) {
    return 'To $upi';
  }

  @override
  String billPayWithUpi(String amount) {
    return 'Pay $amount with UPI';
  }

  @override
  String get billIvePaid => 'I’ve paid';

  @override
  String get billUpiNote => 'Hangout bill';

  @override
  String billUpiNoteAt(String place) {
    return 'Hangout · $place';
  }

  @override
  String billNoUpiApp(String upi) {
    return 'No UPI app opened. Pay $upi from any UPI app, then tap “I’ve paid”.';
  }

  @override
  String billAfterPayHint(String name) {
    return 'Paid? Tap “I’ve paid” so $name knows.';
  }

  @override
  String get billYoureSettled => 'You’re settled up';

  @override
  String billCollectAt(String upi) {
    return 'Friends pay you at $upi';
  }

  @override
  String get billAllSettled => 'Everyone’s paid you back';

  @override
  String billWaitingOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waiting on $count people',
      one: 'Waiting on 1 person',
    );
    return '$_temp0';
  }

  @override
  String get billRemind => 'Remind on WhatsApp';

  @override
  String billRemindMessage(String upi) {
    return 'Settling up for our hangout: your share is in Hangout. Pay me on UPI at $upi.';
  }

  @override
  String billRemindMessageAt(String place, String upi) {
    return 'Settling up for $place: your share is in Hangout. Pay me on UPI at $upi.';
  }

  @override
  String get billSharesTitle => 'Everyone’s share';

  @override
  String get billStatusPaid => 'Paid';

  @override
  String get billStatusOwes => 'Hasn’t paid yet';

  @override
  String get billStatusPayer => 'Paid the bill';

  @override
  String get billChangeAmounts => 'Change amounts';

  @override
  String get billDelete => 'Delete bill';

  @override
  String get billDeleteTitle => 'Delete this bill?';

  @override
  String get billDeleteBody => 'Everyone’s shares and paid marks go with it.';

  @override
  String get billMarkPaid => 'Mark as paid';

  @override
  String get billMarkUnpaid => 'Mark as not paid';

  @override
  String get billEditTitle => 'Change amounts';

  @override
  String billEditTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String billEditLeft(String amount) {
    return '$amount left to assign';
  }

  @override
  String billEditOver(String amount) {
    return '$amount over the total';
  }

  @override
  String get billEditAddsUp => 'Adds up to the total';

  @override
  String get billEditEvenly => 'Split evenly';

  @override
  String get billEditAmountError => 'Use numbers only, like 450 or 450.50.';

  @override
  String get billLoadFailed => 'Couldn’t load the bill.';

  @override
  String get revealAllDoneTitle => 'Everyone’s voted';

  @override
  String get revealWaitingTitle => 'Waiting on the crew';

  @override
  String get revealHostReady => 'Reveal the winner when you’re ready.';

  @override
  String get revealHostEarly =>
      'You can reveal now, or wait for everyone to finish.';

  @override
  String revealGuestBody(String host) {
    return '$host reveals the winner. You’ll see it here the moment they do.';
  }

  @override
  String get revealTheHost => 'The host';

  @override
  String revealProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get revealMemberDone => 'Done';

  @override
  String get revealMemberSwiping => 'Still swiping';

  @override
  String get revealButton => 'Reveal the winner';

  @override
  String get revealEarlyTitle => 'Reveal now?';

  @override
  String revealEarlyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people haven’t finished. Their votes so far will count.',
      one: '1 person hasn’t finished. Their votes so far will count.',
    );
    return '$_temp0';
  }

  @override
  String get revealEarlyWait => 'Wait';

  @override
  String get revealEarlyConfirm => 'Reveal';

  @override
  String get revealFailed =>
      'Couldn’t reveal the winner. Check your connection and try again.';

  @override
  String get lobbyEveryoneIn => 'Everyone’s in';

  @override
  String get lobbyDropPins => 'Drop your pins';

  @override
  String lobbySubtitleFood(String crew) {
    return '$crew · somewhere to eat';
  }

  @override
  String lobbySubtitlePlaces(String crew) {
    return '$crew · somewhere to go';
  }

  @override
  String get lobbyMidpoint =>
      'We search around the middle of everyone’s pins, so nobody has to cross town.';

  @override
  String get lobbyMyPin => 'My pin';

  @override
  String get lobbyPinFailed => 'Couldn’t save that pin.';

  @override
  String get lobbyPinDropped => 'Pin dropped';

  @override
  String get lobbyNoPinYet => 'Hasn’t dropped a pin yet';

  @override
  String get lobbyMovePin => 'Move my pin';

  @override
  String get lobbyDropPin => 'Drop my pin';

  @override
  String get lobbyFindingPlaces => 'Finding places…';

  @override
  String get lobbyStartSwiping => 'Start swiping';

  @override
  String lobbyStartWithPins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start with $count pins',
      one: 'Start with 1 pin',
    );
    return '$_temp0';
  }

  @override
  String get lobbyStartEarlyTitle => 'Start without everyone?';

  @override
  String lobbyStartEarlyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count people haven’t dropped a pin. We’ll search around the pins that are in, and they can still swipe.',
      one:
          '1 person hasn’t dropped a pin. We’ll search around the pins that are in, and they can still swipe.',
    );
    return '$_temp0';
  }

  @override
  String get lobbyStartEarlyWait => 'Wait';

  @override
  String get lobbyStartEarlyConfirm => 'Start';

  @override
  String get lobbyWaitingForHost => 'Waiting for the host to start';

  @override
  String lobbyWaitingOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waiting on $count more',
      one: 'Waiting on 1 more',
    );
    return '$_temp0';
  }

  @override
  String get lobbyNothingFoodNearby =>
      'No restaurants near the crew’s pins. Try a wider radius.';

  @override
  String get lobbyNothingNearby =>
      'No places near the crew’s pins. Try a wider radius.';

  @override
  String get crewSessionLoadFailed => 'Couldn’t load that session.';

  @override
  String get crewCodeRefreshFailed => 'Couldn’t get a new code.';

  @override
  String get crewCodeCopied => 'Code copied';

  @override
  String crewInviteMessage(String crew, String code) {
    return 'Join my Hangout crew *$crew*\n\nInvite code: *$code*\n\nGet Hangout and punch in the code.';
  }

  @override
  String get crewInviteCopied => 'Invite copied. Paste it anywhere.';

  @override
  String get crewDeleteTitle => 'Delete this crew?';

  @override
  String get crewLeaveTitle => 'Leave this crew?';

  @override
  String crewDeleteBody(String crew) {
    return 'This removes “$crew” for everyone.';
  }

  @override
  String crewLeaveBody(String crew) {
    return 'You’ll drop out of “$crew”.';
  }

  @override
  String get crewLeave => 'Leave';

  @override
  String get crewDeleteMenu => 'Delete crew';

  @override
  String get crewLeaveMenu => 'Leave crew';

  @override
  String crewMetaFood(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Food · $count people',
      one: 'Food · 1 person',
    );
    return '$_temp0';
  }

  @override
  String crewMetaPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Places · $count people',
      one: 'Places · 1 person',
    );
    return '$_temp0';
  }

  @override
  String get crewInviteTitle => 'Invite';

  @override
  String get crewMembersTitle => 'The crew';

  @override
  String get crewPastTitle => 'Past hangouts';

  @override
  String get crewFindFood => 'Find somewhere to eat';

  @override
  String get crewFindPlace => 'Find somewhere to go';

  @override
  String get crewSessionSetup => 'Waiting for everyone to drop a pin';

  @override
  String get crewSessionOpen => 'Open';

  @override
  String get crewSessionSwiping => 'Swiping has started';

  @override
  String get crewSessionSwipe => 'Swipe';

  @override
  String get crewPickingFood => 'Picking somewhere to eat';

  @override
  String get crewPickingPlace => 'Picking somewhere to go';

  @override
  String crewInviteCodeSemantics(String code) {
    return 'Invite code $code';
  }

  @override
  String get crewInviteHint => 'Friends join with this code';

  @override
  String get crewCopyCode => 'Copy code';

  @override
  String get crewShareInvite => 'Share invite';

  @override
  String get crewNewCode => 'Get a new code';

  @override
  String get crewNewCodeLoading => 'Getting a new code…';

  @override
  String get memoriesTitle => 'Memories';

  @override
  String get memoriesSubtitleEmpty => 'Where your crews ended up';

  @override
  String memoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hangouts so far',
      one: '1 hangout so far',
    );
    return '$_temp0';
  }

  @override
  String get memoriesEarlier => 'Earlier';

  @override
  String get memoriesEmptyTitle => 'Nothing here yet';

  @override
  String get memoriesEmptyBody =>
      'When a crew lands on a winner, it’s saved here: where you went, who came, and how close the vote was.';

  @override
  String get memoriesLoading => 'Loading memories';

  @override
  String get memoriesLoadFailed => 'Couldn’t load your hangouts.';

  @override
  String get memoryNoWinner => 'No winner';

  @override
  String get memoryNoWinnerLong => 'No winner this time';

  @override
  String get memoryOpenFailed => 'Couldn’t open that hangout.';

  @override
  String get memoryRemoved => 'Removed from your memories';

  @override
  String get memoryJustYou => 'Just you';

  @override
  String memoryMeta(String who, String date) {
    return '$who · $date';
  }

  @override
  String get memoryDidntGo => 'Didn’t go';

  @override
  String get memoryNobodyYes => 'Nobody said yes to anything';

  @override
  String memoryVotesShort(int yes, int total) {
    return '$yes/$total';
  }

  @override
  String get profileTitle => 'You';

  @override
  String get profileHangouts => 'Hangouts';

  @override
  String get profileCrews => 'Crews';

  @override
  String get profileEdit => 'Edit name and avatar';

  @override
  String get profileUpiAdd => 'Add your UPI ID';

  @override
  String get profileUpiHint => 'Where friends pay you back';

  @override
  String get profileUpiSheetBody =>
      'When you pay for the crew, friends pay you back here.';

  @override
  String get profileLicences => 'Open-source licences';

  @override
  String get profileLogOut => 'Log out';

  @override
  String get setupAlreadyDecidingTitle => 'Already deciding';

  @override
  String setupAlreadyDecidingBody(String crew) {
    return '$crew has a hangout going. Join that one instead of starting another.';
  }

  @override
  String get setupAlreadyDecidingOpen => 'Open it';

  @override
  String get setupNeedPlace => 'Drop a pin, or type an area name.';

  @override
  String get setupNothingFood =>
      'Nothing open around there. Try a wider radius?';

  @override
  String get setupNothingPlaces => 'Nothing around there. Try a wider radius?';

  @override
  String get setupAreaNotFound =>
      'We couldn’t find that area. Try adding the city.';

  @override
  String get setupJustMe => 'Just me';

  @override
  String get setupGroupTitleFood => 'Find food together';

  @override
  String get setupGroupTitlePlaces => 'Find a spot together';

  @override
  String get setupHowItGoes => 'Here’s how it goes.';

  @override
  String get setupStepPins => 'Everyone drops a pin in the lobby';

  @override
  String setupStepSwipe(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count of you swipe the same places',
      two: 'Both of you swipe the same places',
      one: 'You swipe the places',
    );
    return '$_temp0';
  }

  @override
  String get setupStepReveal => 'You reveal the winner when the crew’s done';

  @override
  String get setupOpenLobby => 'Open the lobby';

  @override
  String get setupSoloTitleFood => 'Where are you eating?';

  @override
  String get setupSoloTitlePlaces => 'Where are you headed?';

  @override
  String get setupPinDropped => 'Pin dropped';

  @override
  String get setupPickOnMap => 'Pick on the map';

  @override
  String get setupPickOnMapHint => 'Open the map and drop a pin';

  @override
  String get setupOrTypeArea => 'or type an area';

  @override
  String get setupAreaHintFood => 'Banjara Hills, Hyderabad';

  @override
  String get setupAreaHintPlaces => 'Charminar, Hyderabad';

  @override
  String get setupFindFood => 'Find places to eat';

  @override
  String get setupFindPlaces => 'Find places to go';

  @override
  String get navHome => 'Home';

  @override
  String get navCrews => 'Crews';

  @override
  String get navMemories => 'Memories';

  @override
  String get navYou => 'You';

  @override
  String get navStartHangout => 'Start a hangout';

  @override
  String get startSheetTitle => 'What are we deciding?';

  @override
  String get startSheetFood => 'Somewhere to eat';

  @override
  String get startSheetFoodHint => 'Restaurants, cafés, bars';

  @override
  String get startSheetPlaces => 'Somewhere to go';

  @override
  String get startSheetPlacesHint => 'Parks, museums, days out';

  @override
  String get homeProfile => 'Your profile';

  @override
  String get homeGreetingDay => 'Where to today?';

  @override
  String get homeGreetingNight => 'Where to tonight?';

  @override
  String get homeEat => 'Eat';

  @override
  String get homeExplore => 'Explore';

  @override
  String get homeLastTime => 'Last time';

  @override
  String get homeAllMemories => 'All memories';

  @override
  String get homeOpenFailed => 'Couldn’t open that hangout. Try again.';

  @override
  String get homeSwipingFood => 'Swiping for somewhere to eat';

  @override
  String get homeSwipingPlaces => 'Swiping for somewhere to go';

  @override
  String get homePinsFood => 'Dropping pins for somewhere to eat';

  @override
  String get homePinsPlaces => 'Dropping pins for somewhere to go';

  @override
  String get crewsTitle => 'Crews';

  @override
  String get crewsSubtitle => 'The people you decide with.';

  @override
  String get crewsJoin => 'Join';

  @override
  String get crewsNew => 'New';

  @override
  String get crewsLoading => 'Loading your crews';

  @override
  String get crewsEmptyTitle => 'No crews yet';

  @override
  String get crewsEmptyBody =>
      'A crew is the group you decide with. Start one and share the code, or join a friend’s.';

  @override
  String get crewsStart => 'Start a crew';

  @override
  String get crewsJoinWithCode => 'Join with a code';

  @override
  String get crewsLoadFailed => 'Couldn’t load your crews';

  @override
  String get crewsRetry => 'Retry';

  @override
  String get joinTitle => 'Join a crew';

  @override
  String get joinSubtitle => 'Enter the 6-character code your friend shared.';

  @override
  String get joinButton => 'Join crew';

  @override
  String get joinNotFound =>
      'That code didn’t match a crew. Check it and try again.';

  @override
  String joinFull(String crew) {
    return '“$crew” is full. Crews top out at 10 people.';
  }

  @override
  String get modeTitleFood => 'Where to eat';

  @override
  String get modeTitlePlaces => 'Where to go';

  @override
  String get modeSubtitle => 'Pick who’s deciding.';

  @override
  String get modeWithCrew => 'With a crew';

  @override
  String get modeStart => 'Start';

  @override
  String get modeOnYourOwn => 'On your own';

  @override
  String get modeJustMeHint => 'Swipe solo and decide fast';

  @override
  String get modeNoCrewsFood => 'No food crews yet';

  @override
  String get modeNoCrewsPlaces => 'No explore crews yet';

  @override
  String get modeNoCrewsBody =>
      'Start one, share the code, and everyone swipes on the same places.';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get createTitle => 'New crew';

  @override
  String get createSubtitle =>
      'The people you decide with. You’ll get a code to share.';

  @override
  String get createDecideLabel => 'What will you decide?';

  @override
  String get createModeFood => 'Food';

  @override
  String get createModePlaces => 'Places';

  @override
  String get createNameLabel => 'Crew name';

  @override
  String get createNameHintFood => 'Friday dinner lot';

  @override
  String get createNameHintPlaces => 'Weekend wanderers';

  @override
  String get createNameEmpty => 'Give the crew a name';

  @override
  String get createNameShort => 'A bit longer than that';

  @override
  String get createButton => 'Create crew';

  @override
  String get loginHeadline => 'We should hang out sometime.';

  @override
  String get loginBody =>
      'Swipe on places with your crew. Everyone votes, one spot wins.';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginOrPhone => 'or use your phone';

  @override
  String get loginPhoneHint => 'Mobile number';

  @override
  String get loginPhoneEmpty => 'Enter your mobile number';

  @override
  String get loginPhoneInvalid => 'That’s not a 10-digit number';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginGoogleFailed => 'Google sign-in didn’t work. Try again?';

  @override
  String get loginSendFailed =>
      'We couldn’t send that code. Check the number and try again.';

  @override
  String loginLegal(String terms, String privacy) {
    return 'By continuing you agree to the $terms and $privacy.';
  }

  @override
  String get loginTerms => 'Terms of Service';

  @override
  String get loginPrivacy => 'Privacy Policy';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSentTo(String phone) {
    return 'We texted a 6-digit code to $phone';
  }

  @override
  String get otpVerify => 'Verify & continue';

  @override
  String get otpWrong => 'That code didn’t match. Try again.';

  @override
  String get otpResendFailed => 'We couldn’t resend that code.';

  @override
  String get otpResent => 'Code sent again';

  @override
  String get otpDidntGetIt => 'Didn’t get it?';

  @override
  String get otpResend => 'Send it again';

  @override
  String otpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String otpDigit(int position) {
    return 'Digit $position of 6';
  }

  @override
  String get avatarNeedNickname => 'Pick a nickname first';

  @override
  String get avatarSaveFailed =>
      'Couldn’t save that. Check your connection and try again.';

  @override
  String get avatarEditTitle => 'Edit profile';

  @override
  String get avatarTitle => 'Make it yours';

  @override
  String get avatarBody =>
      'This is how your crews will see you. You can change it later.';

  @override
  String get avatarNicknameLabel => 'Nickname';

  @override
  String get avatarNicknameHelper => 'Shuffle for a new one, or type your own.';

  @override
  String get avatarNewNickname => 'New nickname';

  @override
  String get avatarLetsGo => 'Let’s go';

  @override
  String avatarPick(String name) {
    return 'Avatar $name';
  }

  @override
  String get pickerSearchHere => 'Search here';

  @override
  String get pickerTapMap => 'Tap the map to drop a pin';

  @override
  String get pickerMyLocation => 'Use my location';

  @override
  String get pickerConfirm => 'Search around here';

  @override
  String get pickerLocationOff => 'Turn on location to use where you are.';

  @override
  String get pickerLocationDenied =>
      'Location permission is off. You can still tap the map.';

  @override
  String get filtersTitle => 'Narrow it down';

  @override
  String get filtersBody => 'Everything here is optional.';

  @override
  String get filtersCraving => 'Craving';

  @override
  String get filtersCategories => 'Categories';

  @override
  String get filtersPickFew => 'Pick a few, or leave it open.';

  @override
  String get filtersBudget => 'Budget';

  @override
  String get filtersBudgetHint => 'Skip anything pricier.';

  @override
  String get filtersAny => 'Any';

  @override
  String get filtersOpenNow => 'Open now';

  @override
  String get filtersOpenNowHint => 'Only somewhere you can walk into.';

  @override
  String get filtersOpenNowSwitch => 'Only places open now';

  @override
  String get filtersHowFar => 'How far';

  @override
  String filtersHowFarHint(int km) {
    return '$km km from your spot.';
  }

  @override
  String filtersKm(int km) {
    return '$km km';
  }

  @override
  String get catPizza => 'Pizza';

  @override
  String get catBurgers => 'Burgers';

  @override
  String get catSushi => 'Sushi';

  @override
  String get catNoodles => 'Noodles';

  @override
  String get catBiryani => 'Biryani';

  @override
  String get catArabian => 'Arabian';

  @override
  String get catCafe => 'Cafe';

  @override
  String get catBrewery => 'Brewery';

  @override
  String get catNorthIndian => 'North Indian';

  @override
  String get catSouthIndian => 'South Indian';

  @override
  String get catBreakfast => 'Breakfast';

  @override
  String get catDesserts => 'Desserts';

  @override
  String get catMuseums => 'Museums';

  @override
  String get catParks => 'Parks';

  @override
  String get catAmusement => 'Amusement';

  @override
  String get catGalleries => 'Art galleries';

  @override
  String get catHistoric => 'Historic sites';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get notifyOpen => 'Open';
}
