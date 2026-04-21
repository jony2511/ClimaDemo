import Foundation
import FirebaseAuth

final class RoomSessionViewModel: ObservableObject {
    struct QueuePlaybackRequest: Identifiable {
        let id = UUID()
        let songs: [Song]
        let startPosition: Int
    }

    @Published private(set) var room: Room
    @Published private(set) var members: [RoomMember] = []
    @Published private(set) var queueItems: [RoomQueueItem] = []
    @Published private(set) var suggestions: [SongSuggestion] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var shouldAutoLeave = false
    @Published private(set) var playlistSongs: [Song] = []
    @Published private(set) var queuePlaybackRequest: QueuePlaybackRequest?
    @Published var selectedPlaylistTrackName = ""

    private let observationUseCase: RoomObservationUseCase
    private let interactionUseCase: RoomInteractionUseCase
    private let playbackSync: RoomPlaybackSyncProtocol
    private let homePlaylistViewModel = HomePlaylistViewModel()
    private let currentUID: String

    init(
        room: Room,
        observationUseCase: RoomObservationUseCase,
        interactionUseCase: RoomInteractionUseCase,
        playbackSync: RoomPlaybackSyncProtocol,
        currentUID: String = Auth.auth().currentUser?.uid ?? ""
    ) {
        self.room = room
        self.observationUseCase = observationUseCase
        self.interactionUseCase = interactionUseCase
        self.playbackSync = playbackSync
        self.currentUID = currentUID
        self.playlistSongs = homePlaylistViewModel.fetchCachedCurrentPlaylist()
        self.selectedPlaylistTrackName = self.playlistSongs.first?.trackName ?? ""
    }

    var isHost: Bool {
        return room.hostUID == currentUID
    }

    var isRoomActive: Bool {
        return room.status == .active
    }

    var roomStatusText: String {
        switch room.status {
        case .active:
            return "Active"
        case .ended:
            return "Ended"
        case .expired:
            return "Expired"
        }
    }

    var roomStatusMessage: String? {
        switch room.status {
        case .active:
            return nil
        case .ended:
            return "This room has ended. You can leave this session."
        case .expired:
            return "This room has expired. You can leave this session."
        }
    }

    var playbackOffsetText: String {
        let canonicalOffset = playbackSync.canonicalOffset(at: Date(), for: room.playbackState)
        return String(format: "%.1fs", canonicalOffset)
    }

    func startObserving() {
        guard !room.id.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        observationUseCase.observeRoom(
            roomID: room.id,
            onRoomChange: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let room):
                    self.room = room
                    self.shouldAutoLeave = !self.isHost && !self.isRoomActive
                    if let statusMessage = self.roomStatusMessage {
                        self.errorMessage = statusMessage
                    }
                    self.isLoading = false
                case .failure(let error):
                    self.errorMessage = error.errorDescription
                    self.isLoading = false
                }
            },
            onMembersChange: { [weak self] result in
                switch result {
                case .success(let members):
                    self?.members = members
                case .failure(let error):
                    self?.errorMessage = error.errorDescription
                }
            },
            onQueueChange: { [weak self] result in
                switch result {
                case .success(let queue):
                    self?.queueItems = queue
                case .failure(let error):
                    self?.errorMessage = error.errorDescription
                }
            },
            onSuggestionsChange: { [weak self] result in
                switch result {
                case .success(let suggestions):
                    self?.suggestions = suggestions
                case .failure(let error):
                    self?.errorMessage = error.errorDescription
                }
            }
        )
    }

    func stopObserving() {
        observationUseCase.stopObservingRoom()
    }

    func consumeAutoLeaveTrigger() {
        shouldAutoLeave = false
    }

    func sendSuggestion() {
        guard isRoomActive else { return }

        guard !currentUID.isEmpty else {
            errorMessage = RoomFeatureError.unauthenticated.errorDescription
            return
        }

        guard let song = selectedPlaylistSong else {
            errorMessage = "Select a song from your playlist first."
            return
        }

        interactionUseCase.suggestSong(roomID: room.id, uid: currentUID, song: song) { [weak self] result in
            switch result {
            case .success:
                self?.errorMessage = nil
            case .failure(let error):
                self?.errorMessage = error.errorDescription
            }
        }
    }

    func refreshPlaylistSongs() {
        let songs = homePlaylistViewModel.fetchCachedCurrentPlaylist()
        playlistSongs = songs

        if songs.contains(where: { $0.trackName == selectedPlaylistTrackName }) {
            return
        }

        selectedPlaylistTrackName = songs.first?.trackName ?? ""
    }

    func playQueueItem(_ item: RoomQueueItem) {
        guard isRoomActive else { return }

        guard let selectedIndex = queueItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        queuePlaybackRequest = QueuePlaybackRequest(
            songs: queueItems.map { $0.song },
            startPosition: selectedIndex
        )

        let now = Date()
        let newState = RoomPlaybackState(
            trackIdentifier: item.song.trackName,
            isPlaying: true,
            startedAt: now,
            offsetSeconds: 0,
            updatedByUID: currentUID,
            updatedAt: now
        )

        interactionUseCase.setPlaybackState(
            roomID: room.id,
            actorUID: currentUID,
            state: newState
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = error.errorDescription
            }
        }
    }

    func consumeQueuePlaybackRequest() {
        queuePlaybackRequest = nil
    }

    func approveSuggestion(_ suggestion: SongSuggestion) {
        guard isRoomActive else { return }
        guard isHost else { return }

        interactionUseCase.approveSuggestion(
            roomID: room.id,
            suggestionID: suggestion.id,
            actorUID: currentUID
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = error.errorDescription
            }
        }
    }

    func voteToSkip() {
        guard isRoomActive else { return }

        guard !currentUID.isEmpty else {
            errorMessage = RoomFeatureError.unauthenticated.errorDescription
            return
        }

        interactionUseCase.voteToSkip(roomID: room.id, uid: currentUID) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = error.errorDescription
            }
        }
    }

    func togglePlayback() {
        guard isRoomActive else { return }
        guard isHost else { return }

        let now = Date()
        let canonicalOffset = playbackSync.canonicalOffset(at: now, for: room.playbackState)

        let newState = RoomPlaybackState(
            trackIdentifier: room.playbackState.trackIdentifier ?? queueItems.first?.song.trackName,
            isPlaying: !room.playbackState.isPlaying,
            startedAt: !room.playbackState.isPlaying ? now : nil,
            offsetSeconds: canonicalOffset,
            updatedByUID: currentUID,
            updatedAt: now
        )

        interactionUseCase.setPlaybackState(
            roomID: room.id,
            actorUID: currentUID,
            state: newState
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = error.errorDescription
            }
        }
    }

    var selectedPlaylistSong: Song? {
        return playlistSongs.first { $0.trackName == selectedPlaylistTrackName }
    }
}
