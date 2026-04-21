import Foundation

final class RoomInteractionUseCase {
    private let repository: RoomRepositoryProtocol

    init(repository: RoomRepositoryProtocol) {
        self.repository = repository
    }

    func suggestSong(
        roomID: String,
        uid: String,
        song: Song,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        repository.suggestSong(roomID: roomID, uid: uid, song: song, completion: completion)
    }

    func approveSuggestion(
        roomID: String,
        suggestionID: String,
        actorUID: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        repository.approveSuggestion(
            roomID: roomID,
            suggestionID: suggestionID,
            actorUID: actorUID,
            completion: completion
        )
    }

    func voteToSkip(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        repository.voteToSkip(roomID: roomID, uid: uid, completion: completion)
    }

    func setPlaybackState(
        roomID: String,
        actorUID: String,
        state: RoomPlaybackState,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        repository.setPlaybackState(roomID: roomID, actorUID: actorUID, state: state, completion: completion)
    }
}
