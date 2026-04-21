import Foundation
import FirebaseAuth

final class RoomAccessViewModel: ObservableObject {
    enum Mode: String, CaseIterable {
        case create = "Create"
        case join = "Join"
    }

    @Published var mode: Mode = .create
    @Published var roomCodeInput = ""
    @Published var displayNameInput = ""
    @Published var selectedWeatherMode: RoomWeatherSourceMode = .hostLocation
    @Published var selectedCity = ""

    @Published private(set) var isLoading = false
    @Published private(set) var currentRoom: Room?
    @Published private(set) var myHostedRoom: Room?
    @Published private(set) var errorMessage: String?

    private let lifecycleUseCase: RoomLifecycleUseCase
    private var currentUID: String?
    private let lastActiveRoomIDKey = "rooms.lastActiveRoomID"

    init(lifecycleUseCase: RoomLifecycleUseCase) {
        self.lifecycleUseCase = lifecycleUseCase
        self.displayNameInput = Auth.auth().currentUser?.displayName ?? ""
        loadMyHostedRoom()
    }

    func submit() {
        errorMessage = nil

        switch mode {
        case .create:
            createRoom()
        case .join:
            joinRoom()
        }
    }

    func leaveRoom() {
        guard let room = currentRoom, let uid = currentUID else { return }

        isLoading = true
        lifecycleUseCase.leaveRoom(roomID: room.id, uid: uid) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success:
                self.lifecycleUseCase.stopPresenceHeartbeat(roomID: room.id, uid: uid)
                self.currentRoom = nil
                self.currentUID = nil
                self.clearLastActiveRoomIDIfNeeded(roomID: room.id)
                self.loadMyHostedRoom()
            case .failure(let error):
                self.errorMessage = error.errorDescription
            }
        }
    }

    func openMyHostedRoom() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = RoomFeatureError.unauthenticated.errorDescription
            return
        }

        guard let room = myHostedRoom else {
            errorMessage = RoomFeatureError.roomNotFound.errorDescription
            return
        }

        currentUID = uid
        currentRoom = room
        lifecycleUseCase.startPresenceHeartbeat(roomID: room.id, uid: uid)
    }

    func loadMyHostedRoom() {
        guard let uid = Auth.auth().currentUser?.uid else {
            myHostedRoom = nil
            return
        }

        if let cachedRoomID = UserDefaults.standard.string(forKey: lastActiveRoomIDKey), !cachedRoomID.isEmpty {
            lifecycleUseCase.fetchAccessibleRoom(roomID: cachedRoomID, uid: uid) { [weak self] result in
                switch result {
                case .success(let room):
                    if let room {
                        self?.myHostedRoom = room
                    } else {
                        UserDefaults.standard.removeObject(forKey: self?.lastActiveRoomIDKey ?? "")
                        self?.loadHostedRoom(for: uid)
                    }
                case .failure(let error):
                    self?.errorMessage = error.errorDescription
                }
            }
            return
        }

        loadHostedRoom(for: uid)
    }

    private func loadHostedRoom(for uid: String) {
        lifecycleUseCase.fetchHostedActiveRoom(hostUID: uid) { [weak self] result in
            switch result {
            case .success(let room):
                self?.myHostedRoom = room
                if let room {
                    self?.setLastActiveRoomID(room.id)
                }
            case .failure(let error):
                self?.errorMessage = error.errorDescription
            }
        }
    }

    private func createRoom() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = RoomFeatureError.unauthenticated.errorDescription
            return
        }

        let displayName = resolvedDisplayName()
        isLoading = true

        let city: String?
        if selectedWeatherMode == .selectedCity {
            let trimmedCity = selectedCity.trimmingCharacters(in: .whitespacesAndNewlines)
            city = trimmedCity.isEmpty ? nil : trimmedCity
        } else {
            city = nil
        }

        lifecycleUseCase.createRoom(
            hostUID: uid,
            hostDisplayName: displayName,
            weatherSourceMode: selectedWeatherMode,
            selectedCity: city
        ) { [weak self] result in
            self?.handleRoomResult(result: result, uid: uid)
        }
    }

    private func joinRoom() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = RoomFeatureError.unauthenticated.errorDescription
            return
        }

        let displayName = resolvedDisplayName()
        let code = roomCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true

        lifecycleUseCase.joinRoom(code: code, uid: uid, displayName: displayName) { [weak self] result in
            self?.handleRoomResult(result: result, uid: uid)
        }
    }

    private func handleRoomResult(result: Result<Room, RoomFeatureError>, uid: String) {
        isLoading = false

        switch result {
        case .success(let room):
            currentUID = uid
            currentRoom = room
            myHostedRoom = room
            setLastActiveRoomID(room.id)
            lifecycleUseCase.startPresenceHeartbeat(roomID: room.id, uid: uid)
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    private func setLastActiveRoomID(_ roomID: String) {
        UserDefaults.standard.set(roomID, forKey: lastActiveRoomIDKey)
    }

    private func clearLastActiveRoomIDIfNeeded(roomID: String) {
        let currentValue = UserDefaults.standard.string(forKey: lastActiveRoomIDKey)
        if currentValue == roomID {
            UserDefaults.standard.removeObject(forKey: lastActiveRoomIDKey)
        }
    }

    private func resolvedDisplayName() -> String {
        let trimmed = displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        if let currentUserName = Auth.auth().currentUser?.displayName,
           !currentUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return currentUserName
        }

        return "Guest"
    }
}
