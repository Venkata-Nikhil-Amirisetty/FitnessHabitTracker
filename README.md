# 🧠 FitnessHabitTracker

**FitnessHabitTracker** is an all-in-one iOS app built using **SwiftUI**, designed to help users stay consistent with their fitness and wellness habits. It enables users to set and track goals, log habits and workouts, visualize progress, receive intelligent reminders, and stay motivated through a built-in gamification system.

---

## ✨ Key Features

### 🏋️ Habit & Workout Tracking
- Create custom habits and workout routines.
- Log completions, track frequency, and pause or snooze habits.
- View habit analytics and completion history with charts and visual feedback.

### 🎯 Goal Management
- Set weekly, monthly, or custom-duration goals for habits and workouts.
- Track progress automatically as users complete associated activities.
- Supports linking specific habits or workouts to each goal.

### ⏰ Smart Reminders & Notifications
- Schedule reminders for habits.
- Receive motivational push notifications based on time or completion status.

### 📈 Progress Visualization
- View habit completion rates and streaks.
- Visual charts powered by the **Charts** framework.
- Includes streak logic and heatmaps.

### 📍 Nearby Gym Discovery
- Uses **CoreLocation** and **MapKit** to find gyms near the user.
- Displays gyms in a dedicated Nearby Gyms Dashboard.

### 🧬 HealthKit Integration
- Sync workout and health data from Apple Health.
- Track health metrics relevant to goal achievements.

### 🧩 Gamification System
- Earn XP for completed habits and workouts.
- Level up over time and unlock streak badges.
- Participate in weekly/monthly challenges for extra rewards.

### 👤 User Authentication & Profile
- Secure login and signup with **Firebase Authentication**.
- User profile management and customizable profile pictures.
- Secure local caching of user data and preferences.

---

## 🛠️ Tech Stack

| Technology        | Purpose                                     |
|-------------------|---------------------------------------------|
| SwiftUI           | Declarative UI Framework                    |
| Firebase Auth     | User Authentication                         |
| Firebase Firestore| Cloud Storage and Data Sync (if needed)     |
| SwiftData         | Local persistent storage (SQLite)           |
| Charts Framework  | Visual Analytics & Habit Statistics         |
| CoreLocation      | Getting user's current location             |
| MapKit            | Displaying nearby gyms                      |
| HealthKit         | Syncing workouts and fitness metrics        |
| CryptoKit         | Secure caching & hashing (Profile/Image mgmt)|
| NotificationCenter| Local push notifications                    |

