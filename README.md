# 💚 Pulse — Health & Fitness App

A modern health and fitness tracking app built with Flutter for Android.
Tracks steps, workouts, sleep, hydration and more — all 100% free.

---

## 📱 Screenshots

<!-- Add your screenshots here -->
| Home | Fitness | Me | Sleep |
|------|---------|-----|-------|
| ![Home](screenshots/home.png) | ![Fitness](screenshots/fitness.png) | ![Me](screenshots/me.png) | ![Sleep](screenshots/sleep.png) |

---

## ✨ Features

- 👟 **Real step counting** — live pedometer sensor
- 🏃 **Live workout tracking** — timer, steps, distance, calories
- 🌙 **Sleep score** — accelerometer analysis overnight
- 💧 **Hydration tracker** — quick-add + daily log
- 🔥 **Calorie tracking** — custom daily goal
- 📊 **Stats detail pages** — steps, active time, calories
- 💪 **12 Achievements** — unlock based on real activity
- 🌙 **Full dark mode** — toggle in Me tab
- 📅 **Workout history** — save and view past workouts
- 👤 **Profile + photo** — pick from gallery

---

## 🛠️ Built With

| Tool | Purpose |
|------|---------|
| Flutter | Framework |
| Dart | Language |
| fl_chart | Charts |
| pedometer | Step counting |
| shared_preferences | Local storage |
| sensors_plus | Accelerometer |
| image_picker | Profile photo |
| permission_handler | Permissions |
| google_fonts | Typography |
| wakelock_plus | Sleep tracking |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code
- Android device or emulator

### Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/pulse_health.git

# Go into the folder
cd pulse_health

# Install packages
flutter pub get

# Run the app
flutter run
```

### Android Permissions Required
- Physical Activity — step counting
- Body Sensors — sensor access
- Wake Lock — sleep tracking
- Read Media Images — profile photo

---

## 📁 Project Structure
<img width="377" height="454" alt="image" src="https://github.com/user-attachments/assets/33c869ce-40bd-4ff1-9f4f-f00eab217f91" />
pulse_health/
├── README.md          ← this file
├── screenshots/       ← folder with app screenshots
│   ├── home.png
│   ├── fitness.png
│   ├── me.png
│   └── sleep.png
├── lib/
├── android/
└── pubspec.yaml
