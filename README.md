# Abyssinia E-Learning Mobile Application
**Practical Assignment Submission**  
**Company:** Abyssinia Software Technology PLC  
**Platform:** Flutter (Android)  
**Author:** Candidate Developer  

---

## 1. Project Overview & Objective
The **Abyssinia E-Learning Mobile Application** is a modern, high-performance educational platform engineered in Flutter & Dart. It allows learners to browse tech courses, explore chapter/lesson hierarchies, track learning progress, stream high-definition video lessons, and download authorized MP4 video files directly to local disk for seamless offline playback without network connectivity.

---

## 2. Architectural Design & Code Organization
The application adheres strictly to **Clean Layered MVVM (Model-View-ViewModel)** architecture:

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart        # Design tokens, gradients, surface palettes
│   └── theme/
│       └── app_theme.dart         # Material 3 light & dark theme configurations
├── data/
│   ├── models/
│   │   ├── user_model.dart        # User profile & authentication data model
│   │   ├── lesson_model.dart      # Lesson entity with title, duration, video URL
│   │   ├── chapter_model.dart     # Chapter entity containing ordered lesson list
│   │   ├── course_model.dart      # Full course entity with metadata & chapters
│   │   └── download_item.dart     # Offline download state, bytes, & file tracker
│   ├── repositories/
│   │   ├── auth_repository.dart   # Mock auth DB, registration, credential verification
│   │   └── course_repository.dart # Local JSON asset loader, search, and filter queries
│   └── services/
│       ├── storage_service.dart   # SharedPreferences wrapper for session & registry
│       └── download_service.dart  # Dio download engine, file I/O & progress callbacks
├── ui/
│   ├── core/
│   │   └── widgets/
│   │       ├── custom_button.dart    # Reusable gradient & outlined buttons
│   │       ├── custom_text_field.dart# Validated text fields with password toggle
│   │       ├── category_chip.dart    # Filter chips with animated selection
│   │       ├── course_card.dart      # Course card with thumbnail, badge, & progress
│   │       └── state_views.dart      # Loading, Empty, and Error state views
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart     # Sign-in screen with 1-tap demo credentials
│   │   │   └── signup_screen.dart    # Registration screen with validation
│   │   ├── courses/
│   │   │   ├── course_list_screen.dart   # Search, category chips, & course cards
│   │   │   └── course_detail_screen.dart # Syllabus accordion & download controls
│   │   ├── video/
│   │   │   └── video_player_screen.dart  # Dual online/offline player with custom controls
│   │   ├── downloads/
│   │   │   └── downloads_screen.dart     # Offline storage manager & playback launcher
│   │   ├── profile/
│   │   │   └── profile_screen.dart       # Learning stats, dark/light toggle, sign-out
│   │   └── main/
│   │       └── main_navigation_screen.dart # Bottom navigation bar with downloads badge
│   └── viewmodels/
│       ├── auth_viewmodel.dart       # Authentication state & session management
│       ├── course_viewmodel.dart     # Course data, search, category, & progress
│       ├── download_viewmodel.dart   # Download task orchestration & offline verification
│       └── theme_viewmodel.dart      # Theme persistence (Dark / Light / System)
└── main.dart                         # Dependency injection & MultiProvider app root
```

---

## 3. Core Features & Technical Highlights

### A. Authentication & Local Storage
- **Local Storage Engine:** Powered by `SharedPreferences` to persist user sessions, registered accounts, and login state across app reboots.
- **Registration & Validation:** Validates email format, password complexity (min 6 chars), and checks against duplicate registered accounts.
- **Demo Account:** Automatically pre-seeded for frictionless reviewer access (`student@abyssinia.com` / `password123`) or via a dedicated **"Fast Demo Login (1-Tap)"** button.
- **Session Lifecycle:** Supports persistent login, manual logout with confirmation dialog, and instant cache cleanup.

### B. Course List & Discovery
- **Local JSON Data:** Ingests rich course information directly from `assets/data/courses.json`. Includes 4 comprehensive courses:
  1. *Flutter & Dart Mobile Engineering*
  2. *Full-Stack Cloud & Microservices*
  3. *Mobile UI/UX Design Systems*
  4. *Data Structures & Algorithmic Thinking*
- **Real-Time Search:** Search courses by keyword across course titles, descriptions, categories, and instructor names.
- **Category Filter Chips:** Horizontal filter bar to instantly narrow courses by domain (*All*, *Mobile Development*, *Cloud & DevOps*, *Design & UX*, *Computer Science*).

### C. Chapters, Lessons & Syllabus
- **Hierarchical Structure:** Each course features multiple modules/chapters, and each chapter contains multiple structured lessons.
- **Metadata:** Each lesson specifies title, duration, video URL, description, and order.
- **Accordion Navigation:** Expandable chapter tiles allow intuitive browsing.

### D. Video Playback & Offline Download (Core Assignment Feature)
- **Authorized Downloadable Video Files:** Configured with direct, fast, byte-range compliant MP4 video streams that are fully downloadable and playable on mobile devices.
- **Dual Playback Modes:**
  - **Online Mode:** Streams directly via HTTP/HTTPS with buffering indicators.
  - **Offline Mode:** When a lesson has been downloaded, the player automatically detects the verified local file path (`File(path)`) and plays from local disk storage without requiring any internet connection.
- **Custom Player Controls:**
  - Play / Pause toggle with animated feedback
  - Interactive scrub bar / timeline with duration counter
  - 10-second skip forward & 10-second skip backward
  - Playback speed adjustment (0.75x, 1.0x, 1.25x, 1.5x, 2.0x)
  - Source badge: *"Playing Offline File"* vs *"Streaming Online"*
- **Download Management:**
  - Real-time download progress tracking (e.g. "45%")
  - Cancellation support
  - Dedicated **Offline Downloads** tab showing storage space used (in MB/GB) and one-tap offline playback
  - Delete download option to free up device storage

### E. Bonus Features
- **Lesson Progress Tracking:** Toggle lessons as completed; tracks course completion percentage with linear progress indicators.
- **Dark & Light Mode:** Sleek dark mode by default with option to switch to light mode in the Profile screen.
- **Interactive Badge Counter:** Dynamic notification badge on the bottom navigation bar showing the number of downloaded offline lessons.

---

## 4. Test Credentials
Use the following credentials to test authentication, or tap the **"Fast Demo Login (1-Tap)"** button on the Login screen:

- **Email:** `student@abyssinia.com`
- **Password:** `password123`

You can also register a new account on the **Sign Up** screen; all registered credentials persist in the local storage database.

---

## 5. Prerequisites & Setup Instructions

### Prerequisites
- **Flutter SDK:** 3.24.x or higher (tested on Flutter 3.47.6, Dart 3.13.5)
- **Android SDK:** API 21 or higher (Android 5.0+)
- **Java:** JDK 17 or higher

### Step-by-Step Execution
1. **Navigate to the project root:**
   ```bash
   cd elearning_app
   ```
2. **Fetch all dependencies:**
   ```bash
   flutter pub get
   ```
3. **Execute Unit & Widget Tests:**
   ```bash
   flutter test
   ```
4. **Run Static Analysis (Quality check):**
   ```bash
   flutter analyze
   ```
5. **Run the App on Connected Device / Emulator:**
   ```bash
   flutter run
   ```
6. **Build Release Android APK:**
   ```bash
   flutter build apk --release
   ```
   The generated APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 6. Implementation Notes & Technical Limitations
- **Authorized Video Formats:** Video URLs use standard, accessible MP4 video files. YouTube URLs cannot be directly downloaded as raw files without violating terms of service; therefore, open, direct MP4 streams are utilized for verified offline playback.
- **Local File Storage:** Downloaded files are stored in the application's isolated document directory via `path_provider`, ensuring files are secure and automatically managed by the operating system.
- **Mock Backend Extensibility:** The repository pattern cleanly isolates data access. To connect a live REST API or GraphQL backend in the future, only `AuthRepository` and `CourseRepository` need to swap their data source without touching any UI view models or screens.

---
*Developed for Abyssinia Software Technology PLC Practical Assessment.*
