import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/links.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';

/// Everything about one place, and the ways to get there: book, get
/// directions, call, visit the website.
///
/// The photos run edge to edge under glass controls; once they scroll away
/// the bar turns solid and takes the place's name.
class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  /// 'hunger' or 'travel' — decides whether booking or directions leads.
  final String mode;

  /// How the vote went, when this place came out of one ("4 of 5 said yes").
  final String? voteLine;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    required this.mode,
    this.voteLine,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  Place get place => widget.place;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _heroHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.9).clamp(260.0, 420.0);

  void _onScroll() {
    final threshold =
        _heroHeight(context) -
        kToolbarHeight -
        MediaQuery.paddingOf(context).top -
        8;
    final collapsed = _scroll.offset > threshold;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final glass = !_collapsed && place.photos.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _heroHeight(context),
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            systemOverlayStyle:
                glass ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: HangoutIconButton(
                icon: Icons.arrow_back_rounded,
                size: 40,
                variant:
                    glass
                        ? HangoutIconButtonVariant.glass
                        : HangoutIconButtonVariant.plain,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: AppMotion.fast,
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
            ),
            actions: [
              HangoutIconButton(
                icon: Icons.share_rounded,
                size: 40,
                variant:
                    glass
                        ? HangoutIconButtonVariant.glass
                        : HangoutIconButtonVariant.plain,
                tooltip: l10n.actionShare,
                onPressed: () => sharePlace(context, place),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _Gallery(place: place),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.x5,
              AppSpacing.gutter,
              AppSpacing.x10,
            ),
            sliver: SliverList.list(
              children: [
                Text(place.name, style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.x2),
                PlaceFacts(place: place, showRating: place.photos.isEmpty),
                if (widget.voteLine != null) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    widget.voteLine!,
                    style: AppTextStyles.smallStrong.copyWith(
                      color: AppColors.avocado700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x6),
                PlaceActions(place: place, isFood: widget.mode == 'hunger'),
                const SizedBox(height: AppSpacing.x8),
                HangoutListGroup(
                  children: [
                    if (place.address != null)
                      HangoutListRow(
                        leading: const _RowIcon(Icons.place_outlined),
                        title: place.address!,
                        titleMaxLines: 2,
                        subtitle: l10n.placeOpenInMaps,
                        onTap: () => openLink(context, place.mapsUri),
                      ),
                    if (place.phone != null)
                      HangoutListRow(
                        leading: const _RowIcon(Icons.call_outlined),
                        title: place.phone!,
                        subtitle: l10n.placeCall,
                        onTap:
                            () => openLink(
                              context,
                              Uri(
                                scheme: 'tel',
                                path: place.phone!.replaceAll(' ', ''),
                              ),
                            ),
                      ),
                    if (place.websiteUrl != null)
                      HangoutListRow(
                        leading: const _RowIcon(Icons.language_rounded),
                        title:
                            Uri.tryParse(place.websiteUrl!)?.host ??
                            place.websiteUrl!,
                        subtitle: l10n.placeWebsite,
                        onTap:
                            () =>
                                openLink(context, Uri.parse(place.websiteUrl!)),
                      ),
                  ],
                ),
                if (place.reviews.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x8),
                  SectionHeader(title: l10n.placeReviewsTitle),
                  const SizedBox(height: AppSpacing.x2),
                  HangoutListGroup(
                    children: [
                      for (final r in place.reviews.take(5))
                        ReviewTile(review: r),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens WhatsApp with the place and a Maps link, ready to send to the crew.
Future<void> sharePlace(BuildContext context, Place place) {
  HapticFeedback.selectionClick();
  final text = context.l10n.placeShareMessage(
    place.name,
    place.mapsUri.toString(),
  );
  return openLink(context, whatsAppShareUri(text));
}

/// Price, open now, and what kind of place it is — one quiet line of tags.
/// Neutral sand, so paprika stays with the action below; only "Open now" is
/// avocado. The rating joins them when there's no photo to float it on.
class PlaceFacts extends StatelessWidget {
  final Place place;
  final bool showRating;

  const PlaceFacts({super.key, required this.place, this.showRating = true});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showRating && place.rating != null)
          HangoutBadge.rating(place.rating!),
        if (place.priceDisplay.isNotEmpty)
          HangoutTag(label: place.priceDisplay, tone: TagTone.neutral),
        if (place.isOpenNow != null)
          HangoutTag(
            label: place.isOpenNow! ? l10n.placeOpenNow : l10n.placeClosed,
            tone: place.isOpenNow! ? TagTone.fresh : TagTone.outline,
          ),
        if (place.cuisineType != null)
          HangoutTag(label: place.cuisineType!, tone: TagTone.neutral),
      ],
    );
  }
}

/// The honey rating chip, floated on a photo's top-left corner.
class PhotoRating extends StatelessWidget {
  final Place place;

  const PhotoRating({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    if (place.rating == null) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      left: 12,
      child: HangoutBadge.rating(place.rating!),
    );
  }
}

/// The ways out of the app to the place. Food leads with booking a table;
/// everything else leads with directions. One primary, two quiet options.
///
/// [compact] keeps only directions, for lists where several places sit on
/// one screen; the place's own page has the rest.
class PlaceActions extends StatelessWidget {
  final Place place;
  final bool isFood;
  final bool compact;

  const PlaceActions({
    super.key,
    required this.place,
    required this.isFood,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final website =
        place.websiteUrl == null ? null : Uri.tryParse(place.websiteUrl!);

    void open(Uri uri) => openLink(context, uri);
    final dineout = Uri.parse(place.dineoutUrl);

    if (compact) {
      return _secondary(
        l10n.placeDirections,
        Icons.directions_rounded,
        () => open(place.directionsUri),
      );
    }

    final List<Widget> secondary;
    if (isFood) {
      secondary = [
        _secondary(
          l10n.placeDirections,
          Icons.directions_rounded,
          () => open(place.directionsUri),
        ),
        _secondary(
          l10n.placeEazyDiner,
          Icons.open_in_new_rounded,
          () => open(Uri.parse(place.eazyDinerUrl)),
        ),
      ];
    } else {
      secondary = [
        if (website != null)
          _secondary(
            l10n.placeWebsite,
            Icons.language_rounded,
            () => open(website),
          ),
        _secondary(
          l10n.placeGoogleMaps,
          Icons.map_outlined,
          () => open(place.mapsUri),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HangoutButton(
          label: isFood ? l10n.placeBookDineout : l10n.placeGetDirections,
          size: HangoutButtonSize.lg,
          block: true,
          iconLeft: isFood ? null : Icons.directions_rounded,
          iconRight: isFood ? Icons.open_in_new_rounded : null,
          onPressed: () => open(isFood ? dineout : place.directionsUri),
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          children: [
            for (var i = 0; i < secondary.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.x2),
              Expanded(child: secondary[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _secondary(String label, IconData icon, VoidCallback onPressed) =>
      HangoutButton(
        label: label,
        iconLeft: icon,
        block: true,
        variant: HangoutButtonVariant.secondary,
        onPressed: onPressed,
      );
}

class _Gallery extends StatefulWidget {
  final Place place;

  const _Gallery({required this.place});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.place.photos;
    if (photos.isEmpty) return const HangoutPhoto();

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => HangoutPhoto(url: photos[i].url),
        ),
        // Protection for the status bar and the glass controls.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66241A16), Color(0x00241A16)],
                ),
              ),
            ),
          ),
        ),
        if (widget.place.rating != null)
          Positioned(
            left: 16,
            bottom: 14,
            child: HangoutBadge.rating(widget.place.rating!),
          ),
        if (photos.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            i == _page
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: AppShadows.sm,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;

  const _RowIcon(this.icon);

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 32, child: Icon(icon, color: AppColors.textMuted));
}

/// One Google review: who, when, how many stars, and a few lines of it.
class ReviewTile extends StatelessWidget {
  final PlaceReview review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HangoutAvatar(name: review.authorName, size: 32),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionStrong,
                    ),
                    if (review.relativeTime != null)
                      Text(review.relativeTime!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (review.rating != null) HangoutBadge.rating(review.rating!),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Text(
              review.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small,
            ),
          ],
        ],
      ),
    );
  }
}
