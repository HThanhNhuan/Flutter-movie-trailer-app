# Movie Trailer Mobile App

A feature-rich **Flutter mobile application** for discovering movies, exploring detailed film information, watching trailers, saving favorites, and receiving personalized movie notifications. The app integrates with **TMDb API** to deliver a modern, visually engaging movie-browsing experience with local persistence and polished mobile UX.

> This project focuses on turning raw movie data into a user-friendly mobile product through API integration, state management, local storage, notification workflows, and cinematic UI design.

**Tags:** `flutter`, `dart`, `mobile-app`, `tmdb-api`, `sqlite`, `provider`, `gorouter`, `movie-app`, `state-management`, `rest-api`

---

## 1. Project Overview

The application was built as a mobile movie discovery platform where users can:

- browse **Now Playing**, **Popular**, **Top Rated**, and **Upcoming** movies
- search movies by title in real time
- open rich movie detail pages with **overview, genres, cast, production companies, images, trailers, recommendations, and similar titles**
- watch trailers directly inside the app
- save favorite movies locally for quick access
- receive local notifications about **upcoming, trending, and recommended movies**
- switch between light and dark themes for a better viewing experience

This project demonstrates both **technical implementation** and **product thinking**, combining external API consumption with mobile UI/UX, local database handling, persistent preferences, and notification-based engagement.

---

## 2. Why This Project Stands Out

This is more than a simple movie listing app. Its core value comes from combining several mobile engineering concerns into one cohesive product:

- **Real API-driven content** using TMDb
- **Multi-screen navigation architecture** with nested routing
- **Local persistence** for favorites and in-app notifications
- **Notification-based engagement flow** for new and relevant movie content
- **Dynamic, cinematic UI** using palette extraction, shimmer loading, hero animation, and custom visual effects
- **Personalized experience** through favorite-based recommendations and unread notification tracking

For a CV or portfolio, this project highlights the ability to build a complete mobile application around a realistic entertainment use case rather than only demonstrating isolated screens.

---

## 3. Core Features

### Movie Discovery

- Browse movies by category:
  - Now Playing
  - Popular
  - Top Rated
  - Upcoming
- Infinite loading / incremental loading for selected sections
- Pull-to-refresh on the home screen

### Movie Search

- Search movies by title through TMDb API
- Display results in a responsive grid layout
- Open any result directly into the detail screen

### Detailed Movie Information

- Full movie details fetched from TMDb
- Genres, rating, overview, and production companies
- Cast list and actor detail pages
- Backdrop gallery and visual assets
- Recommended movies and similar movies
- Embedded trailer/video playback

### Favorites System

- Save favorite movies locally using SQLite
- Remove favorites instantly
- Persist favorite list between sessions

### Notification System

- Local notifications for selected upcoming movies
- Scheduled reminders for future notifications
- In-app notification center with categorized items:
  - Recommendation
  - Trending
  - Upcoming
- Badge count and unread notification management
- Deep-link navigation from notification to movie detail page

### UI / UX Enhancements

- Light mode and dark mode support
- Animated neon background
- Hero transitions and cinematic detail page animation
- Shimmer placeholders during loading
- Dynamic color palette generation from movie posters
- Clean bottom navigation with shell routing

---

## 4. Technology Stack

| Category         | Technology                                                                  |
| ---------------- | --------------------------------------------------------------------------- |
| Framework        | Flutter                                                                     |
| Language         | Dart                                                                        |
| State Management | Provider, Riverpod                                                          |
| Navigation       | GoRouter                                                                    |
| API Source       | The Movie Database (TMDb) API                                               |
| HTTP Client      | `http`                                                                      |
| Local Database   | SQLite via `sqflite`                                                        |
| Local Storage    | `shared_preferences`                                                        |
| Notifications    | `flutter_local_notifications`                                               |
| Badge Support    | `flutter_app_badger`                                                        |
| Media            | `youtube_player_flutter`                                                    |
| Image Handling   | `cached_network_image`                                                      |
| UI Effects       | `shimmer`, `palette_generator`, `carousel_slider`, custom animation widgets |

---

## 5. Architecture Highlights

The project is organized into modular layers for maintainability and scalability:

- `api/` handles API constants and network calls
- `models/` defines movie, cast, actor, genre, image, and video entities
- `providers/` manages UI state, theme state, favorites, notifications, and movie loading
- `services/` handles external logic such as TMDb helper flows and local notification setup
- `data/` contains SQLite database logic for favorites and app notifications
- `screens/` contains feature screens and navigation targets
- `widgets/` contains reusable UI components and custom effects
- `router/` centralizes route configuration using GoRouter

This structure helps separate concerns between **data fetching**, **business logic**, **local persistence**, and **presentation**.

---

## 6. Project Structure

```text
lib/
├── api/
├── data/
├── models/
├── providers/
├── router/
├── screens/
├── services/
├── theme/
└── widgets/
```

---

## 7. Key Screens

- **Home Screen**: movie categories, slider, refresh, badge notification access
- **Search Screen**: title-based movie search
- **Movie Detail Screen**: complete information, cast, images, trailers, recommendations, favorites
- **Favorites Screen**: locally stored favorite movies
- **Notifications Screen**: categorized in-app notifications with unread tracking
- **Actor Detail Screen**: actor profile and associated movies
- **Genre Movies Screen**: browse movies by selected genre
- **Settings Screen**: theme switching and app information

---

## 8. Setup and Run

### Prerequisites

- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

### Installation

```bash
flutter pub get
flutter run
```

### API Configuration

The app uses TMDb API. Update the API key in:

```dart
lib/api/api_constants.dart
```

Replace the current key with your own TMDb API key before publishing or sharing the project publicly.

---

## 9. What I Implemented Technically

This project demonstrates hands-on experience in:

- integrating third-party REST APIs into a mobile app
- designing multi-screen Flutter navigation with route management
- implementing local persistence with SQLite
- managing application state across multiple features
- building a notification workflow with badge handling and deep linking
- creating polished and responsive mobile UI components
- improving perceived performance with loading states and cached images
- organizing code into reusable, scalable layers

---

## 10. CV / Portfolio Value

This project is suitable for showcasing the following strengths in a CV:

- **Mobile app development with Flutter**
- **API integration and data-driven UI**
- **Local database and persistence handling**
- **State management and navigation architecture**
- **Notification system implementation**
- **UI/UX refinement for production-style applications**

### Suggested one-line CV description

**Built a Flutter-based movie trailer mobile app integrated with TMDb API, featuring movie discovery, trailer playback, favorites persistence, personalized notifications, and a polished cinematic UI.**

### Suggested stronger CV version

**Developed a feature-rich Flutter mobile movie discovery app with TMDb integration, trailer playback, local favorites storage, categorized notification flows, deep-link navigation, and dynamic UI effects to enhance user engagement and mobile UX.**

---

## 11. Future Improvements

- user authentication and cloud sync for favorites
- watchlist and reminder customization
- recommendation engine based on user interaction history
- offline caching for movie details and images
- analytics dashboard for user behavior insights
- cleaner environment-based API key management for production deployment

---

## 12. Developed By

- **Trần Thị Kim Phụng**
- **Huỳnh Thanh Nhuận**

---

## 13. Credits

Movie data is provided by **The Movie Database (TMDb)**.

This project was developed as a mobile application focused on movie trailer exploration, personalized movie browsing, and interactive entertainment UI design.
