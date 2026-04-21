# ClimaBeats

ClimaBeats is an iOS app that blends real-time weather with mood-based music playback. It starts from weather context, maps conditions to listening modes, and supports social room sessions where users can collaborate on a shared queue.

## Features

- Weather-driven playlists (Energetic, Chill, Melancholic, Intense, Cozy, Mysterious)
- Firebase Authentication (Sign Up, Login, Auto-login, Logout)
- Weather fetch with location handling and Bangladesh fallback
- Full music player (play/pause, next/back, seek, volume, shuffle, repeat)
- Favorites synced with Cloud Firestore
- Local library import from Files app
- Social Rooms: create/join by code, member presence, suggestions, queue playback

## Tech Stack

- Swift, UIKit, SwiftUI
- Firebase Auth + Cloud Firestore
- CoreLocation + CLGeocoder
- URLSession + Codable
- AVFoundation (AVAudioPlayer)
- UserDefaults for local caching

## Screenshots

### Authentication

<p align="center">
  <img src="../Screenshots/landing.png" alt="Landing" width="230" />
  <img src="../Screenshots/login.png" alt="Login" width="230" />
  <img src="../Screenshots/signup.png" alt="Sign Up" width="230" />
</p>

### Weather and Playlist

<p align="center">
  <img src="../Screenshots/weather_screen.png" alt="Weather Screen" width="230" />
  <img src="../Screenshots/home_playlist.png" alt="Home Playlist" width="230" />
</p>

### Player, Favorites, and Library

<p align="center">
  <img src="../Screenshots/player_screen.png" alt="Player" width="230" />
  <img src="../Screenshots/favourite.png" alt="Favorites" width="230" />
  <img src="../Screenshots/library.png" alt="Library" width="230" />
</p>

### Profile and Social Rooms

<p align="center">
  <img src="../Screenshots/profile.png" alt="Profile" width="230" />
  <img src="../Screenshots/room_access.png" alt="Room Access" width="230" />
  <img src="../Screenshots/room_session.png" alt="Room Session" width="230" />
</p>

### Activity Diagram (Split)

<p align="center">
  <img src="../Screenshots/activity1.png" alt="Activity Diagram Part 1" width="700" />
</p>

<p align="center">
  <img src="../Screenshots/activity2.png" alt="Activity Diagram Part 2" width="700" />
</p>

## Project Structure

```text
ClimaBeats/
  ClimaBeats/
    Features/Rooms/
    Helpers/
    Model/
    View/
    ViewModel/
  ClimaBeats.xcodeproj/
  report.md
```

## Getting Started

1. Open `ClimaBeats/ClimaBeats.xcodeproj` in Xcode.
2. Ensure `GoogleService-Info.plist` is present in the app target.
3. Select the `ClimaBeats` scheme.
4. Build and run on an iOS simulator or device.

## Firebase Notes

- Auth is used for account lifecycle and session checks.
- Firestore stores users, favorites, mode playlists, and social room data.
- Security behavior is controlled via `firestore.rules`.

## Team

- Niloy Chowdhury
- Md. Tariful Islam Jony
- Siyam Khan

## License

This project is for academic and learning purposes.
