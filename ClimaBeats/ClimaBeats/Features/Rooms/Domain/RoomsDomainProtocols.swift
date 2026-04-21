import Foundation

protocol RoomObservationToken {
    func cancel()
}

protocol RoomRepositoryProtocol {
    func createRoom(
        hostUID: String,
        hostDisplayName: String,
        weatherSourceMode: RoomWeatherSourceMode,
        selectedCity: String?,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    )

    func joinRoom(
        code: String,
        uid: String,
        displayName: String,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    )

    func fetchHostedActiveRoom(
        hostUID: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    )

    func fetchAccessibleRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    )

    func leaveRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    )

    @discardableResult
    func observeRoom(
        roomID: String,
        onChange: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) -> RoomObservationToken

    @discardableResult
    func observeMembers(
        roomID: String,
        onChange: @escaping (Result<[RoomMember], RoomFeatureError>) -> Void
    ) -> RoomObservationToken

    @discardableResult
    func observeQueue(
        roomID: String,
        onChange: @escaping (Result<[RoomQueueItem], RoomFeatureError>) -> Void
    ) -> RoomObservationToken

    @discardableResult
    func observeSuggestions(
        roomID: String,
        onChange: @escaping (Result<[SongSuggestion], RoomFeatureError>) -> Void
    ) -> RoomObservationToken

    func suggestSong(
        roomID: String,
        uid: String,
        song: Song,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    )

    func approveSuggestion(
        roomID: String,
        suggestionID: String,
        actorUID: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    )

    func voteToSkip(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    )

    func setPlaybackState(
        roomID: String,
        actorUID: String,
        state: RoomPlaybackState,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    )
}

protocol RoomPlaybackSyncProtocol {
    func canonicalOffset(at now: Date, for state: RoomPlaybackState) -> TimeInterval
    func shouldReconcile(localOffset: TimeInterval, canonicalOffset: TimeInterval, threshold: TimeInterval) -> Bool
}

protocol RoomWeatherServiceProtocol {
    func fetchRoomWeather(
        mode: RoomWeatherSourceMode,
        selectedCity: String?,
        completion: @escaping (Result<RoomWeatherSnapshot, RoomFeatureError>) -> Void
    )
}

protocol RoomRealtimeSyncProtocol {
    func startPresenceHeartbeat(roomID: String, uid: String)
    func stopPresenceHeartbeat(roomID: String, uid: String)
}
