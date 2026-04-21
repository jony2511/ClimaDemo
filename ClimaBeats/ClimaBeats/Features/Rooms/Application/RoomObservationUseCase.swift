import Foundation

final class RoomObservationUseCase {
    private let repository: RoomRepositoryProtocol
    private var observationTokens: [RoomObservationToken] = []

    init(repository: RoomRepositoryProtocol) {
        self.repository = repository
    }

    func observeRoom(
        roomID: String,
        onRoomChange: @escaping (Result<Room, RoomFeatureError>) -> Void,
        onMembersChange: @escaping (Result<[RoomMember], RoomFeatureError>) -> Void,
        onQueueChange: @escaping (Result<[RoomQueueItem], RoomFeatureError>) -> Void,
        onSuggestionsChange: @escaping (Result<[SongSuggestion], RoomFeatureError>) -> Void
    ) {
        stopObservingRoom()

        observationTokens = [
            repository.observeRoom(roomID: roomID, onChange: onRoomChange),
            repository.observeMembers(roomID: roomID, onChange: onMembersChange),
            repository.observeQueue(roomID: roomID, onChange: onQueueChange),
            repository.observeSuggestions(roomID: roomID, onChange: onSuggestionsChange)
        ]
    }

    func stopObservingRoom() {
        observationTokens.forEach { $0.cancel() }
        observationTokens.removeAll()
    }

    deinit {
        stopObservingRoom()
    }
}
