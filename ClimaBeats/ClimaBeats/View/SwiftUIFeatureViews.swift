import SwiftUI
import UIKit

// MARK: - Favorites (SwiftUI)

final class FavoritesSwiftUIViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false

    func fetchFavorites() {
        isLoading = true
        FavoritesManager.shared.fetchFavorites { [weak self] songs in
            DispatchQueue.main.async {
                self?.songs = songs.map { self?.normalizedSong($0) ?? $0 }
                self?.isLoading = false
            }
        }
    }

    private func normalizedSong(_ song: Song) -> Song {
        let trimmedAlbum = song.albumName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackAlbum = fallbackAlbumName(for: song.trackName)
        let resolvedAlbum = trimmedAlbum.isEmpty ? fallbackAlbum : trimmedAlbum

        return Song(
            name: song.name,
            albumName: resolvedAlbum,
            artistName: song.artistName,
            imageName: song.imageName,
            trackName: song.trackName,
            localFileName: song.localFileName
        )
    }

    private func fallbackAlbumName(for trackName: String) -> String {
        let key = trackName.lowercased()

        if let numericPart = Int(key.replacingOccurrences(of: "song", with: "")) {
            if (1...8).contains(numericPart) { return "Album 1" }
            if (9...12).contains(numericPart) { return "Album 2" }
        }

        return "Unknown Album"
    }

    func removeFavorite(at offsets: IndexSet) {
        guard let index = offsets.first, songs.indices.contains(index) else { return }
        let song = songs[index]

        FavoritesManager.shared.removeFavorite(song: song) { [weak self] success in
            guard success else { return }
            DispatchQueue.main.async {
                self?.songs.remove(at: index)
            }
        }
    }
}

struct FavoritesHostView: View {
    @StateObject private var viewModel = FavoritesSwiftUIViewModel()

    var body: some View {
        FavoritesSwiftUIView(viewModel: viewModel, showBackButton: true)
    }
}

struct FavoritesDisplayOptionsView: View {
    @Binding var showAlbumName: Bool

    var body: some View {
        Toggle("Show Album Name", isOn: $showAlbumName)
            .tint(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0))
            .padding(.horizontal)
    }
}

private struct FavoritePlayerSelection: Identifiable {
    let id: String
    let index: Int
}

struct FavoritesSwiftUIView: View {
    @ObservedObject var viewModel: FavoritesSwiftUIViewModel
    let showBackButton: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showAlbumName = true
    @State private var playerSelection: FavoritePlayerSelection?

    var body: some View {
        VStack(spacing: 0) {
            FavoritesDisplayOptionsView(showAlbumName: $showAlbumName)
                .padding(.top, 8)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading favorites...")
                Spacer()
            } else if viewModel.songs.isEmpty {
                Spacer()
                Text("No favorite songs yet!\nTap ❤️ in the player to add songs.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(Array(viewModel.songs.enumerated()), id: \.offset) { index, song in
                        Button {
                            playerSelection = FavoritePlayerSelection(
                                id: "\(song.name)_\(song.trackName)_\(index)",
                                index: index
                            )
                        } label: {
                            HStack(spacing: 12) {
                                Image(song.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(song.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if showAlbumName {
                                        Text(favoritesSubtitle(for: song))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(favoritesArtistText(for: song))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: viewModel.removeFavorite)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Group {
            if showBackButton {
                Button("Back") { dismiss() }
            }
        })
        .onAppear {
            viewModel.fetchFavorites()
        }
        .fullScreenCover(item: $playerSelection) { selection in
            if viewModel.songs.indices.contains(selection.index) {
                PlayerViewControllerRepresentable(songs: viewModel.songs, position: selection.index)
                    .ignoresSafeArea()
            } else {
                Text("Selected song is unavailable.")
                    .font(.headline)
                    .padding()
            }
        }
    }

    private func favoritesSubtitle(for song: Song) -> String {
        let artist = song.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let album = song.albumName.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = [artist, album].filter { !$0.isEmpty }

        if components.isEmpty {
            return "Unknown Artist • Unknown Album"
        }

        return components.joined(separator: " • ")
    }

    private func favoritesArtistText(for song: Song) -> String {
        let artist = song.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        return artist.isEmpty ? "Unknown Artist" : artist
    }
}

// MARK: - Profile (SwiftUI)

final class ProfileSwiftUIViewModel: ObservableObject {
    @Published var fullName = "Loading..."
    @Published var email = ""
    @Published var favoriteCount = 0
    @Published var editableName = ""

    private let profileViewModel = ProfileViewModel()

    func load() {
        profileViewModel.loadProfile { [weak self] profile in
            DispatchQueue.main.async {
                self?.fullName = profile.fullName.isEmpty ? "User" : profile.fullName
                self?.editableName = self?.fullName ?? ""
                self?.email = profile.email
            }
        }

        profileViewModel.loadFavoritesCount { [weak self] count in
            DispatchQueue.main.async {
                self?.favoriteCount = count
            }
        }
    }

    func updateName(completion: @escaping (String, String) -> Void) {
        profileViewModel.updateFullName(editableName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedName):
                    self?.fullName = updatedName
                    self?.editableName = updatedName
                    completion("Success", "Name updated to \(updatedName)")
                case .failure(let error):
                    completion("Error", error.localizedDescription)
                }
            }
        }
    }

    func signOut() throws {
        try profileViewModel.signOut()
    }
}

struct ProfileHostView: View {
    @StateObject private var profileViewModel = ProfileSwiftUIViewModel()
    @StateObject private var favoritesViewModel = FavoritesSwiftUIViewModel()

    var body: some View {
        ProfileSwiftUIView(profileViewModel: profileViewModel, favoritesViewModel: favoritesViewModel)
    }
}

struct ProfileActionButtonsView: View {
    @Binding var showLibrary: Bool

    let onUpdateName: () -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onUpdateName) {
                Text("Update Name")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(action: onLogout) {
                Text("Logout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1.5)
                    )
            }

            Button {
                showLibrary = true
            } label: {
                Text("Open Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0), lineWidth: 1.5)
                    )
            }
        }
    }
}

struct ProfileSwiftUIView: View {
    @ObservedObject var profileViewModel: ProfileSwiftUIViewModel
    @ObservedObject var favoritesViewModel: FavoritesSwiftUIViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showLibrary = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .foregroundColor(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0))
                        .padding(.top, 10)

                    Text(profileViewModel.fullName)
                        .font(.title2)
                        .fontWeight(.bold)

                    TextField("Update name", text: $profileViewModel.editableName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(profileViewModel.email)
                        .foregroundColor(.secondary)

                    Text("❤️ \(profileViewModel.favoriteCount) Favorite Song\(profileViewModel.favoriteCount == 1 ? "" : "s")")
                        .foregroundColor(.secondary)

                    Divider().padding(.vertical, 4)

                    NavigationLink {
                        FavoritesSwiftUIView(viewModel: favoritesViewModel, showBackButton: false)
                    } label: {
                        Text("Open Favorites")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                            .background(Color(red: 30.0 / 255.0, green: 10.0 / 255.0, blue: 87.0 / 255.0))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    ProfileActionButtonsView(
                        showLibrary: $showLibrary,
                        onUpdateName: updateName,
                        onLogout: logout
                    )
                }
                .padding(20)
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Back") { dismiss() })
            .onAppear {
                profileViewModel.load()
                favoritesViewModel.fetchFavorites()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .fullScreenCover(isPresented: $showLibrary) {
                LibraryViewControllerRepresentable()
                    .ignoresSafeArea()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func updateName() {
        profileViewModel.updateName { title, message in
            alertTitle = title
            alertMessage = message
            showAlert = true
        }
    }

    private func logout() {
        do {
            try profileViewModel.signOut()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.ViewController)
                window.rootViewController = vc
                window.makeKeyAndVisible()
            }
        } catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - UIKit Wrappers

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let songs: [Song]
    let position: Int

    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "player") as? PlayerViewController else {
            let fallback = UIViewController()
            fallback.view.backgroundColor = .systemBackground

            let label = UILabel()
            label.text = "Unable to open player."
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false

            fallback.view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: fallback.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: fallback.view.centerYAnchor)
            ])

            return fallback
        }

        vc.songs = songs
        vc.position = position
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct LibraryViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        LibraryViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
