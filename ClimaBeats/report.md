\documentclass[12pt,a4paper]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{geometry}
\usepackage{setspace}
\usepackage{longtable}
\usepackage{array}
\usepackage{booktabs}
\usepackage{hyperref}
\usepackage{enumitem}
\usepackage{graphicx}
\usepackage{float}
\usepackage{xcolor}

\geometry{margin=1in}
\onehalfspacing
\hypersetup{
  colorlinks=true,
  linkcolor=blue,
  urlcolor=blue,
  pdftitle={ClimaBeats Project Report},
  pdfauthor={Team ClimaBeats}
}

% Screenshot border style for white-background images
\setlength{\fboxsep}{0pt}
\setlength{\fboxrule}{0.3pt}
\newcommand{\shot}[2][]{\fbox{\includegraphics[#1]{#2}}}



\begin{document}

\tableofcontents
\newpage

\section{Objectives}
The primary objectives of the ClimaBeats project are:
\begin{itemize}[leftmargin=1.5em]
    \item To build an iOS application that combines live weather context with mood-based music recommendation.
    \item To apply Swift and UIKit fundamentals in a complete end-to-end project.
    \item To use SwiftUI components and property wrappers for modern, reactive interfaces.
    \item To perform JSON parsing from an external weather API and map responses into Swift models.
    \item To integrate Firebase Authentication and Firestore for secure user and feature data management.
    \item To implement collaborative social room functionality with real-time membership and song queue updates.
\end{itemize}

\section{Introduction}
ClimaBeats is a weather-aware music application for iOS where users authenticate, view current weather, and receive playlists aligned with weather-driven mood categories. The system extends beyond single-user playback by adding profile, favorites, local library import, and collaborative social rooms. In social rooms, users can create/join sessions, suggest songs from their current playlist, and play queue items in a shared environment.

The project demonstrates practical integration of mobile UI design, asynchronous data flows, cloud backend services, local persistence, and modular architecture.

\section{Tools and Technology Used}
\begin{longtable}{p{0.28\textwidth} p{0.66\textwidth}}
\toprule
\textbf{Tool/Technology} & \textbf{Usage in Project} \\
\midrule
\endfirsthead
\toprule
\textbf{Tool/Technology} & \textbf{Usage in Project} \\
\midrule
\endhead
Swift & Core programming language for app logic and data models. \\
UIKit & Main storyboard-based flow and multiple view controllers (Landing, Login, Signup, Weather, Home, Player). \\
SwiftUI & Feature host views and modern reactive UI sections (Favorites, Profile, Rooms). \\
Xcode & Development environment, storyboard design, build and run workflow. \\
Firebase Authentication & User sign-up, login, and session handling. \\
Cloud Firestore & Persistent storage for users, favorites, playlists, room metadata, room members, queue, and suggestions. \\
Firestore Security Rules & Role/membership-based authorization for room and subcollection access. \\
Firestore Indexes & Query optimization for room code/status, host/status, queue ordering, and suggestion ordering. \\
WeatherAPI & Real-time weather data source consumed by app networking layer. \\
CoreLocation + CLGeocoder & Location retrieval and region-aware weather query resolution. \\
URLSession + Codable & API request execution and JSON decoding into strongly typed models. \\
AVFoundation (AVAudioPlayer) & Audio playback engine for local and bundled tracks. \\
UserDefaults & Lightweight caching of local library and current playlist snapshots. \\
\bottomrule
\end{longtable}

\section{Implemented Features}
\subsection{Authentication and Onboarding}
\begin{itemize}[leftmargin=1.5em]
    \item User registration with input validation and Firebase account creation.
    \item User login and persistent auto-login redirection from landing screen.
    \item Secure sign-out and transition back to landing screen.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.31\textwidth]{Screenshots/landing.png}
    \hfill
    \shot[width=0.31\textwidth]{Screenshots/login.png}
    \hfill
    \shot[width=0.31\textwidth]{Screenshots/signup.png}
    \caption{Authentication flow screens: Landing, Login, and Sign Up.}
\end{figure}

\subsection{Weather Acquisition and Weather Screen}
\begin{itemize}[leftmargin=1.5em]
    \item Location permission handling and current-location weather fetch.
    \item Bangladesh fallback weather query when permission is denied/unavailable.
    \item Weather details display: condition, temperature, humidity, wind, region, country, updated time.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.42\textwidth]{Screenshots/weather_screen.png}
    \caption{Weather screen with live weather data and action buttons.}
\end{figure}

\subsection{Weather-to-Mood Playlist Generation}
\begin{itemize}[leftmargin=1.5em]
    \item Condition-to-mode mapping (Energetic, Chill, Melancholic, Intense, Cozy, Mysterious).
    \item Dynamic playlist loading based on current weather mode.
    \item Mode playlist persistence to Firestore and reset-to-default option.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.42\textwidth]{Screenshots/home_playlist.png}
    \caption{Home playlist generated from weather-derived mood mode.}
\end{figure}

\subsection{Audio Player and Playback Controls}
\begin{itemize}[leftmargin=1.5em]
    \item Song playback with previous/next, pause/play, volume, and seek slider.
    \item Shuffle and repeat modes with UI feedback.
    \item Compatibility with bundled songs and imported local songs.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.42\textwidth]{Screenshots/player_screen.png}
    \caption{Player screen with playback controls, seek bar, volume, and favorite toggle.}
\end{figure}

\subsection{Favorites and Local Library}
\begin{itemize}[leftmargin=1.5em]
    \item Favorite toggle from player and Firestore-backed favorites list.
    \item Favorites listing with deletion support.
    \item Local library import from Files app and playback of imported tracks.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.31\textwidth]{Screenshots/favourite.png}
    \hfill
    \shot[width=0.31\textwidth]{Screenshots/library.png}
    \caption{Favorites and local Library screens.}
\end{figure}

\subsection{Profile Management}
\begin{itemize}[leftmargin=1.5em]
    \item User profile display (name, email, favorite count).
    \item Name update workflow synced with Firebase user profile and Firestore user document.
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.42\textwidth]{Screenshots/profile.png}
    \caption{Profile screen with update actions and quick navigation buttons.}
\end{figure}

\subsection{Social Rooms (Collaborative Feature)}
\begin{itemize}[leftmargin=1.5em]
    \item Create room and join room by code.
    \item My Room quick access for host and joined users through active-room retrieval.
    \item Real-time member and queue observation.
    \item Song suggestion from the current playlist and queue insertion persisted in Firestore.
    \item Queue item tap launches the player with room queue context.
    \item Presence heartbeat and room lifecycle handling (active/ended/expired states).
\end{itemize}
\begin{figure}[H]
    \centering
    \shot[width=0.31\textwidth]{Screenshots/room_access.png}
    \hfill
    \shot[width=0.31\textwidth]{Screenshots/room_session.png}
    \caption{Social Rooms: Room Access and active Room Session views.}
\end{figure}

\section{Lab Topic to Project Mapping}
\subsection{Introduction to Swift}
	extbf{Where used:}
\begin{itemize}[leftmargin=1.5em]
    \item App models (song, weather, room entities).
    \item View models for login, signup, weather, home playlist, profile, and rooms.
    \item Repository and use-case layers in the Rooms module.
\end{itemize}

	extbf{How applied:}
\begin{itemize}[leftmargin=1.5em]
    \item Used structs, enums, classes, and protocols to keep code modular.
    \item Used optionals and safe unwrapping for runtime safety.
    \item Used callback-based async handling for API and Firestore operations.
\end{itemize}

\subsection{SwiftUI Elements}
	extbf{Where used:}
\begin{itemize}[leftmargin=1.5em]
    \item Favorites, Profile, and Rooms screens.
    \item Hybrid navigation where UIKit opens SwiftUI feature screens.
\end{itemize}

	extbf{How applied:}
\begin{itemize}[leftmargin=1.5em]
    \item Built layouts using \texttt{NavigationView}, \texttt{List}, \texttt{Picker}, \texttt{Button}, and sheet/full-screen presentation.
    \item Connected UI state directly with view models for reactive updates.
\end{itemize}

\subsection{JSON Parsing}
	extbf{Where used:}
\begin{itemize}[leftmargin=1.5em]
    \item Weather API response decoding for location and current weather data.
    \item Data transfer from weather screen to playlist recommendation flow.
\end{itemize}

	extbf{How applied:}
\begin{itemize}[leftmargin=1.5em]
    \item Defined weather models with \texttt{Codable}.
    \item Used \texttt{URLSession} + \texttt{JSONDecoder} to fetch and decode API responses.
    \item Mapped decoded fields to UI labels and playlist mode selection.
\end{itemize}

\subsection{Firebase and Firestore}
	extbf{Where used:}
\begin{itemize}[leftmargin=1.5em]
    \item User authentication (login/signup).
    \item Favorites, profile updates, custom mode playlists.
    \item Social Rooms (room metadata, members, queue, suggestions, playback state).
    \item Backend policy and query optimization through rules and indexes.
\end{itemize}

	extbf{How applied:}
\begin{itemize}[leftmargin=1.5em]
    \item Integrated Firebase Auth for account lifecycle and session checks.
    \item Used Firestore collections/subcollections for feature-specific storage.
    \item Enforced permissions with role/membership-based access rules.
    \item Added indexes for room code/status and ordered queue/suggestion queries.
\end{itemize}

\subsection{SwiftUI Property Wrappers}
	extbf{Where used:}
\begin{itemize}[leftmargin=1.5em]
    \item SwiftUI screens for Favorites, Profile, Room Access, and Room Session.
\end{itemize}

	extbf{How applied:}
\begin{itemize}[leftmargin=1.5em]
    \item \texttt{@StateObject} and \texttt{@ObservedObject} to bind view models with views.
    \item \texttt{@Published} to push live updates from view model to UI.
    \item \texttt{@State} for local interaction state (alerts, selected item, sheet control).
    \item \texttt{@Environment(\textbackslash.dismiss)} for screen dismissal in host views.
\end{itemize}

\section{Team Contribution Summary}
\subsection{Feature Summary: Niloy Chowdhury}
\begin{itemize}[leftmargin=1.5em]
    \item \textbf{Sign In and Sign Up with Firebase:} built user account creation and login with validation and error messages.
    \item \textbf{Firestore rules/index coordination and backend validation:} prepared permission logic and index support so cloud queries and writes stay secure and fast.
    \item \textbf{Home mood-playlist workflow:} handled playlist load, add, reset, and save behavior based on current weather mood.
    \item \textbf{Player enhancement (seek/shuffle/repeat):} added better playback controls for seeking and repeat/shuffle behavior.
    \item \textbf{Profile and Library UI flows:} implemented user profile update flow and local library management screens.
\end{itemize}

\subsection{Feature Summary: Md. Tariful Islam Jony}
\begin{itemize}[leftmargin=1.5em]
    \item \textbf{Initial project setup and UI design:} prepared initial app structure, main navigation setup, and base screen design.
    \item \textbf{Rooms feature engineering (Create/Join):} implemented room creation, room code sharing, and room join flow.
    \item \textbf{Rooms feature engineering (Members/Queue):} implemented member observation, queue update flow, and room session interaction behavior.
    \item \textbf{Navigation polish across screens:} refined movement between screens for smoother user flow.
\end{itemize}

\subsection{Feature Summary: Siyam Khan}
\begin{itemize}[leftmargin=1.5em]
    \item \textbf{Weather-related implementation:} completed location-based weather fetch, fallback handling, and weather screen output.
    \item \textbf{Weather-to-playlist mapping logic:} implemented condition-based mood mapping to generate suitable playlist context.
    \item \textbf{Favorites integration:} completed favorite add/remove/check/list behavior and connected it with the UI.
    \item \textbf{Reusable UI/UX refinements:} improved shared UI behavior and visual consistency across feature screens.
\end{itemize}

\section{Results and Learning Outcomes}
\begin{itemize}[leftmargin=1.5em]
    \item Successfully built and integrated a multi-module iOS application with both UIKit and SwiftUI.
    \item Achieved functional Firebase authentication and cloud persistence for key user data.
    \item Implemented robust JSON parsing and weather-driven business logic.
    \item Learned practical state management patterns in SwiftUI through property wrappers.
    \item Gained experience with Firestore data modeling, indexes, and security rule design.
    \item Improved understanding of collaborative feature design using room lifecycle and real-time listeners.
\end{itemize}

\section{Activity Diagrams}
Because the complete activity flow is large, it is divided into two parts for readability.

\begin{figure}[H]
    \centering
    \shot[width=0.95\textwidth]{Screenshots/activity1.png}
    \caption{Activity Diagram - Part 1 (activity1).}
\end{figure}

\begin{figure}[H]
    \centering
    \shot[width=0.85\textwidth]{Screenshots/activity2.png}
    \caption{Activity Diagram - Part 2 (activity2).}
\end{figure}

\section{Discussion}
The project demonstrates how contextual data (weather) can personalize media recommendations and how social interaction can increase engagement. A notable design decision was using Firestore subcollections for room members, queue, and suggestions, which simplified listener-based updates and authorization checks. Another valuable outcome was combining UIKit legacy flows with SwiftUI feature modules, showing an incremental migration path.

Limitations remain in areas such as richer recommendation logic, broader analytics, and stronger automated test coverage. However, the current architecture already supports incremental extension.

\section{Conclusion}
ClimaBeats met the intended academic and technical goals by integrating mobile UI development, API consumption, cloud backend services, and collaborative interaction in one cohesive application. The system validates core lab competencies while delivering a practical, user-facing app experience. With future enhancements, ClimaBeats can evolve from a course project into a production-ready personalized music platform.

\section{References}
\begin{enumerate}[leftmargin=1.5em]
    \item Apple Swift Documentation: \url{https://docs.swift.org/swift-book/documentation/the-swift-programming-language/}
    \item SwiftUI Documentation: \url{https://developer.apple.com/documentation/swiftui}
    \item UIKit Documentation: \url{https://developer.apple.com/documentation/uikit}
    \item Firebase iOS Setup: \url{https://firebase.google.com/docs/ios/setup}
    \item Firebase Authentication: \url{https://firebase.google.com/docs/auth/ios/start}
    \item Cloud Firestore Documentation: \url{https://firebase.google.com/docs/firestore}
    \item Firestore Security Rules: \url{https://firebase.google.com/docs/firestore/security/get-started}
    \item WeatherAPI Documentation: \url{https://www.weatherapi.com/docs/}
    \item AVFoundation Overview: \url{https://developer.apple.com/documentation/avfoundation}
\end{enumerate}

\end{document}
