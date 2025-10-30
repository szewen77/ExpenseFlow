# 💰 ExpenseFlow

A beautiful and intuitive Flutter expense tracking application with AI-powered financial insights, animated charts, and smart budget management.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-green)
![License](https://img.shields.io/badge/License-MIT-blue)

## ✨ Features

### 💳 Transaction Management
- **Easy Transaction Entry**: Quick add transactions with calendar integration
- **Smart Category Recognition**: AI automatically suggests categories based on transaction titles
- **Income & Expense Tracking**: Separate tracking for both income and expenses
- **Transaction History**: View all transactions with beautiful cards and filters

### 📊 Beautiful Visualizations
- **Animated Charts**: Smooth animations on pie, bar, and line charts
- **Spending Breakdown**: Visual representation of expenses by category
- **Trend Analysis**: Track spending patterns over 7, 30, or 90 days
- **Real-time Updates**: Charts update instantly as you add transactions

### 🤖 AI-Powered Insights
- **Daily Financial Tips**: Personalized recommendations based on spending behavior
- **Behavioral Analysis**: Smart tips when overspending or good saving habits detected
- **Rotating Tips**: 10+ general financial tips that rotate daily
- **Category Optimization**: Alerts when specific categories consume too much budget

### 💰 Budget Management
- **Category Budgets**: Set spending limits for each category
- **Instant Alerts**: Get notified immediately when budgets are exceeded
- **Budget Tracking**: Visual progress bars showing budget utilization
- **Smart Warnings**: Budget alerts appear when adding transactions

### 🎯 Goal Tracking
- **Savings Goals**: Set financial goals with target amounts and deadlines
- **Pixel-Art Progress Bar**: Gamified tug-of-war style progress visualization
- **Goal Status**: "Goal Failed" vs "Goal Achieved" with animations
- **Motivation**: Real-time progress tracking to keep you motivated

### 🎨 Modern UI/UX
- **Pixel-Perfect Design**: Beautiful, modern interface with smooth animations
- **Dark Mode Support**: Comfortable viewing in any lighting condition
- **Responsive Layout**: Works seamlessly on phones, tablets, and web
- **Haptic Feedback**: Tactile responses for better user experience
- **Pull to Refresh**: Intuitive gesture controls

### 📱 Additional Features
- **Profile Management**: Customize your name and monthly income
- **Data Backup**: Export and import your data for safekeeping
- **Multi-Platform**: Works on iOS, Android, Web, Windows, Linux, and macOS
- **Offline First**: All data stored locally with SQLite
- **No Ads**: Clean, distraction-free experience

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- iOS Simulator / Android Emulator / Chrome (for development)

### Installation

1. **Clone the repository**
```bash
git clone git@github.com:szewen77/ExpenseFlow.git
cd ExpenseFlow
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# For Web
flutter run -d chrome

# For macOS
flutter run -d macos
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.4.1           # Local database
  path_provider: ^2.1.5      # File system paths
  fl_chart: ^0.69.2          # Beautiful charts
  table_calendar: ^3.1.2     # Calendar widget
  google_fonts: ^6.2.1       # Custom fonts
  intl: ^0.19.0             # Internationalization
  path: ^1.9.0              # Path manipulation
```

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── transaction.dart         # Transaction model
│   ├── budget.dart             # Budget model
│   ├── goal.dart               # Goal model
│   └── profile.dart            # User profile model
├── screens/                     # App screens
│   ├── home_screen.dart        # Main dashboard
│   ├── add_transaction.dart    # Add/edit transactions
│   ├── transaction_list.dart   # Transaction history
│   ├── report_screen.dart      # Analytics & reports
│   ├── settings_screen.dart    # App settings
│   ├── profile_screen.dart     # User profile
│   └── splash_screen.dart      # Launch screen
├── services/                    # Business logic
│   ├── database_service.dart   # SQLite operations
│   ├── chart_service.dart      # Chart data processing
│   ├── insight_service.dart    # AI tips & analytics
│   └── backup_service.dart     # Data backup/restore
├── widgets/                     # Reusable widgets
│   ├── chart_widget.dart       # Animated charts
│   ├── transaction_card.dart   # Transaction list item
│   ├── app_nav_bar.dart        # Bottom navigation
│   └── summary_tile.dart       # Summary cards
└── utils/                       # Utilities
    ├── constants.dart          # App constants
    ├── helpers.dart            # Helper functions
    └── category_visuals.dart   # Category icons/colors
```

## 🎯 Key Features Implementation

### AI Tip of the Day
The app analyzes your spending behavior and provides personalized tips:
- **Behavioral Tips**: Based on income/expense ratio
- **Category Tips**: When a category exceeds 40% of expenses
- **Rotating Tips**: Daily rotation of 10+ financial wisdom tips

### Animated Charts
All charts feature smooth entry animations:
- **Pie Chart**: Grows from center with radius animation (1.2s)
- **Bar Chart**: Bars rise from bottom (1.0s)
- **Line Chart**: Draws progressively from left to right (1.5s)

### Budget Alerts
Smart budget monitoring system:
- Alerts appear instantly when adding expense transactions
- Shows all exceeded budget categories
- Only triggers for expense-type transactions

## 🛠️ Development

### Run Tests
```bash
flutter test
```

### Build for Production

**Android APK**
```bash
flutter build apk --release
```

**iOS IPA**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

## 📱 Supported Platforms

- ✅ iOS (11.0+)
- ✅ Android (5.0+)
- ✅ Web (Chrome, Safari, Firefox)
- ✅ macOS (10.14+)
- ✅ Windows (10+)
- ✅ Linux

## 🎨 Design Principles

- **Minimalist**: Clean, uncluttered interface
- **Intuitive**: Natural gestures and interactions
- **Consistent**: Unified design language throughout
- **Responsive**: Adapts to different screen sizes
- **Accessible**: High contrast, readable fonts

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Szewen Lee**
- GitHub: [@szewen77](https://github.com/szewen77)

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [FL Chart](https://pub.dev/packages/fl_chart) - Chart library
- [Google Fonts](https://fonts.google.com/) - Typography
- [Table Calendar](https://pub.dev/packages/table_calendar) - Calendar widget

## 📸 Screenshots

_Coming soon! Add screenshots of your app here._

## 🗺️ Roadmap

- [ ] Cloud sync with Firebase
- [ ] Receipt scanning with OCR
- [ ] Recurring transactions automation
- [ ] Multi-currency support
- [ ] Export to PDF reports
- [ ] Widget for home screen
- [ ] Biometric authentication
- [ ] Investment tracking
- [ ] Split transactions with friends

## 💬 Support

If you have any questions or issues, please open an issue on GitHub.

---

Made with ❤️ using Flutter
