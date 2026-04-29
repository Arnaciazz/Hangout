# Decisionly 🎯

A **gamified social decision-making** Flutter app where groups of friends swipe, vote, and decide on restaurants, activities, and hangout spots together.

Built from the [Stitch design project](https://stitch.google.com) "Decide: Gamified Social Bento".

## ✨ Features

- **Home Dashboard** — Active sessions, quick actions bento grid, spending tracker, bucket list matches
- **Swipe Experience** — Tinder-style restaurant cards with drag gestures, vibe tags, menus & reviews
- **Memory Lane** — Timeline of past hangouts with staggered animations and stats
- **Match Celebration** — Confetti animation, group consensus display, booking CTA
- **Profile** — User stats, achievements badges, and settings menu

## 🎨 Design System

| Token | Value |
|---|---|
| Primary | Action Green `#58CC02` |
| Secondary | Berry Purple `#CE82FF` |
| Tertiary | Sunset Orange `#FF9600` |
| Font | Plus Jakarta Sans |
| Style | Bento Box + Gamified Neumorphism |
| Radius | 32px cards, pill buttons |

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.7+)
- Android Studio or VS Code with Flutter extensions

### Setup

```bash
# 1. Navigate to the project
cd hangout

# 2. Generate platform files (if needed)
flutter create .

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point & shell
├── theme/
│   ├── app_colors.dart        # Color palette
│   ├── app_text_styles.dart   # Typography
│   └── app_theme.dart         # Material3 theme
├── models/
│   ├── restaurant.dart        # Restaurant + menu + reviews
│   ├── memory.dart            # Past hangout memories
│   ├── session.dart           # Group decision sessions
│   └── user_profile.dart      # User profile
├── screens/
│   ├── home_screen.dart       # Dashboard
│   ├── swipe_screen.dart      # Card swiping
│   ├── memory_screen.dart     # Timeline
│   ├── match_screen.dart      # Celebration
│   └── profile_screen.dart    # Profile & settings
└── widgets/
    ├── bento_card.dart        # Core card component
    ├── bottom_nav_bar.dart    # Custom navigation
    ├── restaurant_card.dart   # Swipeable card
    └── memory_card.dart       # Memory timeline card
```

## 📦 Dependencies

- `google_fonts` — Plus Jakarta Sans typography
- `confetti` — Match celebration effects
- `shimmer` — Loading states
- `smooth_page_indicator` — Page indicators
- `flutter_staggered_animations` — List animations
