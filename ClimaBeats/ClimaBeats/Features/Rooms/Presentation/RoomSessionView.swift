import SwiftUI
import UIKit

struct RoomSessionHostView: View {
    @StateObject private var viewModel: RoomSessionViewModel
    private let onLeave: () -> Void

    init(room: Room, onLeave: @escaping () -> Void) {
        let repository = FirestoreRoomRepository()
        let observationUseCase = RoomObservationUseCase(repository: repository)
        let interactionUseCase = RoomInteractionUseCase(repository: repository)
        let playbackSync = DefaultRoomPlaybackSync()

        _viewModel = StateObject(
            wrappedValue: RoomSessionViewModel(
                room: room,
                observationUseCase: observationUseCase,
                interactionUseCase: interactionUseCase,
                playbackSync: playbackSync
            )
        )
        self.onLeave = onLeave
    }

    var body: some View {
        RoomSessionView(viewModel: viewModel, onLeave: onLeave)
            .onAppear { viewModel.startObserving() }
            .onDisappear { viewModel.stopObserving() }
    }
}

struct RoomSessionView: View {
    @ObservedObject var viewModel: RoomSessionViewModel
    let onLeave: () -> Void
    @State private var showEndRoomConfirmation = false
    @State private var roomCodeCopied = false

    private var queuePlayerBinding: Binding<RoomSessionViewModel.QueuePlaybackRequest?> {
        Binding(
            get: { viewModel.queuePlaybackRequest },
            set: { value in
                if value == nil {
                    viewModel.consumeQueuePlaybackRequest()
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Room Code: \(viewModel.room.code)")
                .font(.headline)

            Button(roomCodeCopied ? "Code Copied" : "Copy Room Code") {
                UIPasteboard.general.string = viewModel.room.code
                roomCodeCopied = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    roomCodeCopied = false
                }
            }
            .buttonStyle(.bordered)
            .tint(roomCodeCopied ? .green : .blue)

            Text(viewModel.roomStatusText)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(viewModel.isRoomActive ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .cornerRadius(8)

            HStack(spacing: 10) {
                Button(viewModel.isHost && viewModel.isRoomActive ? "End Room" : "Leave Room") {
                    if viewModel.isHost && viewModel.isRoomActive {
                        showEndRoomConfirmation = true
                    } else {
                        onLeave()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Suggest from My Playlist")
                    .font(.subheadline)
                    .bold()

                if viewModel.playlistSongs.isEmpty {
                    Text("Current playlist is empty. Open Home once to load your playlist.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Picker("My Songs", selection: $viewModel.selectedPlaylistTrackName) {
                        ForEach(viewModel.playlistSongs, id: \.trackName) { song in
                            Text("\(song.name) • \(song.artistName)")
                                .tag(song.trackName)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Button("Send Suggestion") {
                    viewModel.sendSuggestion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    viewModel.playlistSongs.isEmpty ||
                    !viewModel.isRoomActive
                )
            }

            List {
                Section("Members") {
                    ForEach(viewModel.members) { member in
                        HStack {
                            Text(member.displayName)
                            Spacer()
                            Text(member.role == .host ? "Host" : "Member")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Circle()
                                .fill(member.isOnline ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Section("Queue") {
                    if viewModel.queueItems.isEmpty {
                        Text("No songs in queue yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.queueItems) { item in
                            Button {
                                viewModel.playQueueItem(item)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.song.name)
                                            .foregroundColor(.primary)
                                        Text(item.song.artistName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)

            if let roomStatusMessage = viewModel.roomStatusMessage {
                Text(roomStatusMessage)
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onChange(of: viewModel.shouldAutoLeave) { shouldAutoLeave in
            guard shouldAutoLeave else { return }
            viewModel.consumeAutoLeaveTrigger()
            onLeave()
        }
        .onAppear {
            viewModel.refreshPlaylistSongs()
        }
        .fullScreenCover(item: queuePlayerBinding) { request in
            RoomQueuePlayerView(songs: request.songs, startPosition: request.startPosition)
                .ignoresSafeArea()
        }
        .alert("End Room?", isPresented: $showEndRoomConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Room", role: .destructive) {
                onLeave()
            }
        } message: {
            Text("Ending the room will remove all members from this session.")
        }
    }
}

private struct RoomQueuePlayerView: UIViewControllerRepresentable {
    let songs: [Song]
    let startPosition: Int

    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let player = storyboard.instantiateViewController(withIdentifier: "player") as? PlayerViewController else {
            return UIViewController()
        }

        player.songs = songs
        player.position = startPosition
        return player
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op.
    }
}
