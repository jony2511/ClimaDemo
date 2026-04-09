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
                self?.songs = songs
                self?.isLoading = false
            }
        }
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

struct FavoritesSwiftUIView: View {
    @ObservedObject var viewModel: FavoritesSwiftUIViewModel
    let showBackButton: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showAlbumName = true
    @State private var selectedIndex: Int?
    @State private var showPlayer = false

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
                            selectedIndex = index
                            showPlayer = true
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
                                        Text("\(song.artistName) • \(song.albumName)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(song.artistName)
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
        .fullScreenCover(isPresented: $showPlayer) {
            if let selectedIndex, viewModel.songs.indices.contains(selectedIndex) {
                PlayerViewControllerRepresentable(songs: viewModel.songs, position: selectedIndex)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Profile (SwiftUI)

final class ProfileSwiftUIViewModel: ObservableObject {
    @Published var fullName = "Loading..."
    @Published var email = ""
    @Published var favoriteCount = 0

    private let profileViewModel = ProfileViewModel()

    func load() {
        profileViewModel.loadProfile { [weak self] profile in
            DispatchQueue.main.async {
                self?.fullName = profile.fullName.isEmpty ? "User" : profile.fullName
                self?.email = profile.email
            }
        }

        profileViewModel.loadFavoritesCount { [weak self] count in
            DispatchQueue.main.async {
                self?.favoriteCount = count
            }
        }
    }

    func resetPassword(completion: @escaping (String, String) -> Void) {
        profileViewModel.resetPassword { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let email):
                    completion("Success", "Password reset email sent to \(email)")
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

    let onResetPassword: () -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onResetPassword) {
                Text("Reset Password")
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
                        onResetPassword: resetPassword,
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

    private func resetPassword() {
        profileViewModel.resetPassword { title, message in
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
            return UIViewController()
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
