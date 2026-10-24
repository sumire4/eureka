# Eureka

**Eureka** is an iOS/Android Flutter application built for Formula 1 and motorsport enthusiasts. It provides real-time F1 news, live championship standings, driver and constructor statistics, and an AI-powered assistant dedicated to motorsport insights.

## About Eureka

Eureka brings together everything an F1 fan needs in one clean, iOS-style Cupertino UI:

- 📰 **Latest F1 News**: Aggregates up-to-date Formula 1 news from top motorsport RSS feeds.
- 🏆 **Driver & Constructor Standings**: Up-to-date championship standings, driver profiles, constructor breakdowns, and car specifications.
- 🤖 **Eureka AI Assistant**: Powered by Google Gemini AI to answer F1 technical questions, historical queries, race predictions, and motorsport analysis.
- 📱 **Cupertino UI**: Designed with a sleek, native iOS look and feel.

---

## Features

- **News View**: Browse and read trending F1 news stories with in-app browser support.
- **Standings View**: Explore current season driver standings, constructor points, detailed driver statistics, and technical car specs.
- **Eureka AI Chat**: Interactive AI assistant customized for F1 queries and analysis.
- **Profile & Customization**: User preferences and account management.

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **UI Design**: Cupertino (iOS Design System)
- **AI**: Google Generative AI (Gemini SDK)
- **Data & Feeds**: RSS XML Parsing, Http, Firebase Cloud Firestore
- **Environment**: `flutter_dotenv` for secure API key configuration

---

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/eureka.git
   cd eureka
   ```

2. **Configure Environment Variables:**
   Create a `.env` file in the root directory and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

3. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

