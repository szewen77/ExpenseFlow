# 💰 ExpenseFlow – Personal Finance Tracker

![Flutter](https://img.shields.io/badge/Flutter-3.19-blue)
![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-green)
![Status](https://img.shields.io/badge/Status-Live-success)
![Build](https://img.shields.io/badge/Build-Stable-brightgreen)

---

## 🌟 Overview

**ExpenseFlow** is a **cross-platform personal finance tracker** built with **Flutter and Dart**, designed to help users manage spending, set savings goals, and visualize financial habits through smart analytics.

It combines **AI-powered insights**, **animated charts**, and a **modern pixel-style UI** to make budgeting intuitive and engaging — perfect for showcasing full-stack mobile and web development capability.

---

## 🌐 Live Demo

👉 [Try ExpenseFlow Web App](https://expenseflow.vercel.app)

Responsive and optimized for mobile & desktop browsers.

---


## 🚀 Core Features

| Feature                          | Description                                                                      |
| -------------------------------- | -------------------------------------------------------------------------------- |
| 💵 **Smart Spending Insights**   | Predicts next month’s expenses and compares with your current spending.          |
| 📈 **Animated Financial Charts** | Interactive pie, line, and bar charts with smooth transitions.                   |
| ⚠️ **Budget Alerts**             | Detects when a user exceeds category budgets and shows instant notifications.    |
| 🤖 **AI-Category Recognition**   | Automatically tags transactions by analyzing keywords (e.g., “Grab”, “Netflix”). |
| 🎯 **Goal Tracking**             | Visual progress between achieved and failed goals using a tug-of-war animation.  |
| 💬 **AI Tip of the Day**         | Context-aware daily financial tips, dynamically selected based on user habits.   |
| 🌎 **Multi-language Ready**      | Supports localization and user-selectable language options.                      |

---

## 🧱 Architecture

* **Flutter (Dart)** — Unified codebase for all platforms
* **SQLite (sqflite)** — Local database for transactions, goals, and budgets
* **Provider** — Lightweight state management
* **MVC pattern** — Clear separation of logic, models, and UI
* **FL Chart** — Smooth, dynamic data visualization

---

## 🗂️ Project Structure

```
lib/
├── main.dart                    # Entry point
├── models/                      # Data models (Transaction, Budget, Goal)
├── screens/                     # Pages (Home, Reports, Settings, etc.)
├── services/                    # Business logic (DB, Insights, Backup)
├── widgets/                     # Reusable UI components
└── utils/                       # Constants, helpers, visuals
```



## 🧩 Tech Stack

| Layer     | Tools                                         |
| --------- | --------------------------------------------- |
| Frontend  | Flutter, Dart, Google Fonts                   |
| Database  | SQLite (sqflite)                              |
| Analytics | fl_chart, intl                                |
| Storage   | path_provider                                 |
| UI/UX     | Material 3, custom themes, pixel-style design |

---



## 🧪 Build & Deployment

### Local Setup

```bash
git clone https://github.com/szewen77/ExpenseFlow.git
cd ExpenseFlow
flutter pub get
flutter run
```

### Web Deployment

```bash
flutter build web --release
vercel --prod
```

---

## 👨‍💻 Developer

**Lee Sze Wen**
Software Engineer & Mobile App Developer
📍 Malaysia

* 🌐 [Portfolio](https://github.com/szewen77)
* 💼 Focus: Flutter • Dart • SQLite • UI/UX • AI Integration

---

## 🧾 License

This project is **open for educational and portfolio use only.**
Not licensed for commercial redistribution.

---

## 🏷️ Tags

`#flutter` `#dart` `#ai` `#finance` `#mobileapp` `#webapp` `#portfolio` `#charts` `#visualization`

---

