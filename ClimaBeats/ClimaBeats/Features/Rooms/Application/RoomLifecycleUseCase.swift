import Foundation

final class RoomLifecycleUseCase {
    private let repository: RoomRepositoryProtocol
    private let realtimeSync: RoomRealtimeSyncProtocol

    init(repository: RoomRepositoryProtocol, realtimeSync: RoomRealtimeSyncProtocol) {
        self.repository = repository
        self.realtimeSync = realtimeSync
    }

    func createRoom(
        hostUID: String,
        hostDisplayName: String,
        weatherSourceMode: RoomWeatherSourceMode,
        selectedCity: String?,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) {
        repository.createRoom(
            hostUID: hostUID,
            hostDisplayName: hostDisplayName,
            weatherSourceMode: weatherSourceMode,
            selectedCity: selectedCity,
            completion: completion
        )
    }

    func joinRoom(
        code: String,
        uid: String,
        displayName: String,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) {
        repository.joinRoom(code: code, uid: uid, displayName: displayName, completion: completion)
    }

    func fetchHostedActiveRoom(
        hostUID: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    ) {
        repository.fetchHostedActiveRoom(hostUID: hostUID, completion: completion)
    }

    func fetchAccessibleRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    ) {
        repository.fetchAccessibleRoom(roomID: roomID, uid: uid, completion: completion)
    }

    func leaveRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        repository.leaveRoom(roomID: roomID, uid: uid) { [weak self] result in
            if case .success = result {
                self?.realtimeSync.stopPresenceHeartbeat(roomID: roomID, uid: uid)
            }
            completion(result)
        }
    }

    func startPresenceHeartbeat(roomID: String, uid: String) {
        realtimeSync.startPresenceHeartbeat(roomID: roomID, uid: uid)
    }

    func stopPresenceHeartbeat(roomID: String, uid: String) {
        realtimeSync.stopPresenceHeartbeat(roomID: roomID, uid: uid)
    }
}
