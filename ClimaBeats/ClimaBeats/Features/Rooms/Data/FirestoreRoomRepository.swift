import Foundation
import FirebaseFirestore

private final class FirestoreListenerToken: RoomObservationToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration?) {
        self.registration = registration
    }

    func cancel() {
        registration?.remove()
        registration = nil
    }
}

final class FirestoreRoomRepository: RoomRepositoryProtocol {
    private let db: Firestore
    private let roomTTL: TimeInterval
    private let maxCodeGenerationAttempts = 8

    init(db: Firestore = Firestore.firestore(), roomTTL: TimeInterval = 4 * 60 * 60) {
        self.db = db
        self.roomTTL = roomTTL
    }

    func createRoom(
        hostUID: String,
        hostDisplayName: String,
        weatherSourceMode: RoomWeatherSourceMode,
        selectedCity: String?,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) {
        createRoom(
            hostUID: hostUID,
            hostDisplayName: hostDisplayName,
            weatherSourceMode: weatherSourceMode,
            selectedCity: selectedCity,
            attempt: 1,
            completion: completion
        )
    }

    func joinRoom(
        code: String,
        uid: String,
        displayName: String,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) {
        let normalizedCode = normalize(code)
        guard !normalizedCode.isEmpty else {
            dispatchResult(.failure(.invalidRoomCode), completion: completion)
            return
        }

        db.collection("rooms")
            .whereField("code", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: completion)
                    return
                }

                guard let roomDoc = snapshot?.documents.first,
                      var room = self.parseRoom(document: roomDoc) else {
                    self.dispatchResult(.failure(.roomNotFound), completion: completion)
                    return
                }

                guard room.status == .active else {
                    self.dispatchResult(.failure(.roomUnavailable), completion: completion)
                    return
                }

                if let expiry = room.expiresAt, expiry <= Date() {
                    room = Room(
                        id: room.id,
                        code: room.code,
                        hostUID: room.hostUID,
                        status: .expired,
                        weatherSourceMode: room.weatherSourceMode,
                        selectedCity: room.selectedCity,
                        weatherSnapshot: room.weatherSnapshot,
                        playbackState: room.playbackState,
                        createdAt: room.createdAt,
                        lastActivityAt: room.lastActivityAt,
                        expiresAt: room.expiresAt
                    )
                    self.dispatchResult(.failure(.roomUnavailable), completion: completion)
                    return
                }

                let memberData: [String: Any] = [
                    "displayName": displayName,
                    "role": RoomRole.member.rawValue,
                    "joinedAt": FieldValue.serverTimestamp(),
                    "lastSeenAt": FieldValue.serverTimestamp(),
                    "isOnline": true
                ]

                let batch = self.db.batch()
                let roomRef = roomDoc.reference
                let memberRef = roomRef.collection("members").document(uid)

                batch.setData(memberData, forDocument: memberRef, merge: true)
                batch.updateData([
                    "lastActivityAt": FieldValue.serverTimestamp()
                ], forDocument: roomRef)

                batch.commit { commitError in
                    if let commitError {
                        self.dispatchResult(.failure(self.map(error: commitError)), completion: completion)
                    } else {
                        self.dispatchResult(.success(room), completion: completion)
                    }
                }
            }
    }

    func fetchHostedActiveRoom(
        hostUID: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    ) {
        db.collection("rooms")
            .whereField("hostUID", isEqualTo: hostUID)
            .whereField("status", isEqualTo: RoomStatus.active.rawValue)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: completion)
                    return
                }

                guard let roomDoc = snapshot?.documents.first,
                      let room = self.parseRoom(document: roomDoc) else {
                    self.dispatchResult(.success(nil), completion: completion)
                    return
                }

                if let expiry = room.expiresAt, expiry <= Date() {
                    self.dispatchResult(.success(nil), completion: completion)
                    return
                }

                self.dispatchResult(.success(room), completion: completion)
            }
    }

    func fetchAccessibleRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Room?, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)

        roomRef.getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
                return
            }

            guard let snapshot, snapshot.exists,
                  let room = self.parseRoom(document: snapshot),
                  room.status == .active,
                  room.expiresAt.map({ $0 > Date() }) ?? true else {
                self.dispatchResult(.success(nil), completion: completion)
                return
            }

            let memberRef = roomRef.collection("members").document(uid)
            memberRef.getDocument { memberSnapshot, memberError in
                if let memberError {
                    self.dispatchResult(.failure(self.map(error: memberError)), completion: completion)
                    return
                }

                if memberSnapshot?.exists == true {
                    self.dispatchResult(.success(room), completion: completion)
                } else {
                    self.dispatchResult(.success(nil), completion: completion)
                }
            }
        }
    }

    func leaveRoom(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)
        roomRef.getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
                return
            }

            guard let snapshot, snapshot.exists,
                  let room = self.parseRoom(document: snapshot) else {
                self.dispatchResult(.failure(.roomNotFound), completion: completion)
                return
            }

            let batch = self.db.batch()
            let memberRef = roomRef.collection("members").document(uid)
            batch.deleteDocument(memberRef)

            var roomUpdates: [String: Any] = [
                "lastActivityAt": FieldValue.serverTimestamp()
            ]

            if room.hostUID == uid {
                roomUpdates["status"] = RoomStatus.ended.rawValue
            }

            batch.updateData(roomUpdates, forDocument: roomRef)

            batch.commit { commitError in
                if let commitError {
                    self.dispatchResult(.failure(self.map(error: commitError)), completion: completion)
                } else {
                    self.dispatchResult(.success(()), completion: completion)
                }
            }
        }
    }

    @discardableResult
    func observeRoom(
        roomID: String,
        onChange: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) -> RoomObservationToken {
        let registration = db.collection("rooms").document(roomID).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: onChange)
                return
            }

            guard let snapshot, snapshot.exists,
                  let room = self.parseRoom(document: snapshot) else {
                self.dispatchResult(.failure(.roomNotFound), completion: onChange)
                return
            }

            self.dispatchResult(.success(room), completion: onChange)
        }

        return FirestoreListenerToken(registration: registration)
    }

    @discardableResult
    func observeMembers(
        roomID: String,
        onChange: @escaping (Result<[RoomMember], RoomFeatureError>) -> Void
    ) -> RoomObservationToken {
        let registration = db.collection("rooms")
            .document(roomID)
            .collection("members")
            .order(by: "joinedAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: onChange)
                    return
                }

                let members = (snapshot?.documents ?? []).compactMap { self.parseMember(document: $0) }
                self.dispatchResult(.success(members), completion: onChange)
            }

        return FirestoreListenerToken(registration: registration)
    }

    @discardableResult
    func observeQueue(
        roomID: String,
        onChange: @escaping (Result<[RoomQueueItem], RoomFeatureError>) -> Void
    ) -> RoomObservationToken {
        let registration = db.collection("rooms")
            .document(roomID)
            .collection("queue")
            .order(by: "addedAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: onChange)
                    return
                }

                let queue = (snapshot?.documents ?? []).compactMap { self.parseQueueItem(document: $0) }
                self.dispatchResult(.success(queue), completion: onChange)
            }

        return FirestoreListenerToken(registration: registration)
    }

    @discardableResult
    func observeSuggestions(
        roomID: String,
        onChange: @escaping (Result<[SongSuggestion], RoomFeatureError>) -> Void
    ) -> RoomObservationToken {
        let registration = db.collection("rooms")
            .document(roomID)
            .collection("suggestions")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: onChange)
                    return
                }

                let suggestions = (snapshot?.documents ?? []).compactMap { self.parseSuggestion(document: $0) }
                self.dispatchResult(.success(suggestions), completion: onChange)
            }

        return FirestoreListenerToken(registration: registration)
    }

    func suggestSong(
        roomID: String,
        uid: String,
        song: Song,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)
        let suggestionRef = roomRef.collection("suggestions").document()
        let queueRef = roomRef.collection("queue").document()

        var payload = song.toDictionary()
        payload["suggestedByUID"] = uid
        payload["createdAt"] = FieldValue.serverTimestamp()
        payload["isApproved"] = true
        payload["approvedByUID"] = uid
        payload["approvedAt"] = FieldValue.serverTimestamp()

        var queuePayload = song.toDictionary()
        queuePayload["addedByUID"] = uid
        queuePayload["source"] = RoomQueueSource.suggestion.rawValue
        queuePayload["votes"] = 0
        queuePayload["addedAt"] = FieldValue.serverTimestamp()

        let batch = db.batch()
        batch.setData(payload, forDocument: suggestionRef)
        batch.setData(queuePayload, forDocument: queueRef)
        batch.updateData(["lastActivityAt": FieldValue.serverTimestamp()], forDocument: roomRef)

        batch.commit { [weak self] error in
            guard let self else { return }
            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
            } else {
                self.dispatchResult(.success(()), completion: completion)
            }
        }
    }

    func approveSuggestion(
        roomID: String,
        suggestionID: String,
        actorUID: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)
        let memberRef = roomRef.collection("members").document(actorUID)
        let suggestionRef = roomRef.collection("suggestions").document(suggestionID)
        let queueRef = roomRef.collection("queue").document()

        db.runTransaction({ [weak self] transaction, errorPointer in
            guard let self else { return nil }

            do {
                let memberSnapshot = try transaction.getDocument(memberRef)
                let role = (memberSnapshot.data()?["role"] as? String).flatMap(RoomRole.init(rawValue:))
                guard role == .host else {
                    errorPointer?.pointee = self.makeNSError(.permissionDenied)
                    return nil
                }

                let suggestionSnapshot = try transaction.getDocument(suggestionRef)
                guard suggestionSnapshot.exists,
                      let suggestion = self.parseSuggestion(document: suggestionSnapshot) else {
                    errorPointer?.pointee = self.makeNSError(.roomNotFound)
                    return nil
                }

                if suggestion.isApproved {
                    return nil
                }

                var queuePayload = suggestion.song.toDictionary()
                queuePayload["addedByUID"] = suggestion.suggestedByUID
                queuePayload["source"] = RoomQueueSource.suggestion.rawValue
                queuePayload["votes"] = 0
                queuePayload["addedAt"] = FieldValue.serverTimestamp()

                transaction.setData(queuePayload, forDocument: queueRef)
                transaction.updateData([
                    "isApproved": true,
                    "approvedByUID": actorUID,
                    "approvedAt": FieldValue.serverTimestamp()
                ], forDocument: suggestionRef)
                transaction.updateData(["lastActivityAt": FieldValue.serverTimestamp()], forDocument: roomRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
            } else {
                self.dispatchResult(.success(()), completion: completion)
            }
        }
    }

    func voteToSkip(
        roomID: String,
        uid: String,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)
        let voteRef = roomRef.collection("skipVotes").document(uid)

        db.runTransaction({ transaction, errorPointer in
            do {
                let existingVote = try transaction.getDocument(voteRef)
                if existingVote.exists {
                    return nil
                }

                transaction.setData([
                    "uid": uid,
                    "votedAt": FieldValue.serverTimestamp()
                ], forDocument: voteRef)

                transaction.updateData([
                    "lastActivityAt": FieldValue.serverTimestamp()
                ], forDocument: roomRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
            } else {
                self.dispatchResult(.success(()), completion: completion)
            }
        }
    }

    func setPlaybackState(
        roomID: String,
        actorUID: String,
        state: RoomPlaybackState,
        completion: @escaping (Result<Void, RoomFeatureError>) -> Void
    ) {
        let roomRef = db.collection("rooms").document(roomID)
        let memberRef = roomRef.collection("members").document(actorUID)

        db.runTransaction({ [weak self] transaction, errorPointer in
            guard let self else { return nil }

            do {
                let memberSnapshot = try transaction.getDocument(memberRef)
                guard memberSnapshot.exists else {
                    errorPointer?.pointee = self.makeNSError(.permissionDenied)
                    return nil
                }

                transaction.updateData([
                    "playbackState": self.playbackDictionary(from: state),
                    "lastActivityAt": FieldValue.serverTimestamp()
                ], forDocument: roomRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.dispatchResult(.failure(self.map(error: error)), completion: completion)
            } else {
                self.dispatchResult(.success(()), completion: completion)
            }
        }
    }

    private func createRoom(
        hostUID: String,
        hostDisplayName: String,
        weatherSourceMode: RoomWeatherSourceMode,
        selectedCity: String?,
        attempt: Int,
        completion: @escaping (Result<Room, RoomFeatureError>) -> Void
    ) {
        guard attempt <= maxCodeGenerationAttempts else {
            dispatchResult(.failure(.invalidState("Unable to generate a unique room code.")), completion: completion)
            return
        }

        let code = generateRoomCode()
        db.collection("rooms")
            .whereField("code", isEqualTo: code)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.dispatchResult(.failure(self.map(error: error)), completion: completion)
                    return
                }

                if (snapshot?.documents.isEmpty == false) {
                    self.createRoom(
                        hostUID: hostUID,
                        hostDisplayName: hostDisplayName,
                        weatherSourceMode: weatherSourceMode,
                        selectedCity: selectedCity,
                        attempt: attempt + 1,
                        completion: completion
                    )
                    return
                }

                let roomRef = self.db.collection("rooms").document()
                let now = Date()
                let expiresAt = now.addingTimeInterval(self.roomTTL)
                let defaultPlayback = RoomPlaybackState(
                    trackIdentifier: nil,
                    isPlaying: false,
                    startedAt: nil,
                    offsetSeconds: 0,
                    updatedByUID: hostUID,
                    updatedAt: now
                )

                let roomPayload: [String: Any] = [
                    "code": code,
                    "hostUID": hostUID,
                    "status": RoomStatus.active.rawValue,
                    "weatherSourceMode": weatherSourceMode.rawValue,
                    "selectedCity": selectedCity as Any,
                    "playbackState": self.playbackDictionary(from: defaultPlayback),
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastActivityAt": FieldValue.serverTimestamp(),
                    "expiresAt": Timestamp(date: expiresAt)
                ]

                let hostMemberPayload: [String: Any] = [
                    "displayName": hostDisplayName,
                    "role": RoomRole.host.rawValue,
                    "joinedAt": FieldValue.serverTimestamp(),
                    "lastSeenAt": FieldValue.serverTimestamp(),
                    "isOnline": true
                ]

                let batch = self.db.batch()
                batch.setData(roomPayload, forDocument: roomRef)
                batch.setData(hostMemberPayload, forDocument: roomRef.collection("members").document(hostUID), merge: true)

                batch.commit { commitError in
                    if let commitError {
                        self.dispatchResult(.failure(self.map(error: commitError)), completion: completion)
                        return
                    }

                    roomRef.getDocument { createdSnapshot, fetchError in
                        if let fetchError {
                            self.dispatchResult(.failure(self.map(error: fetchError)), completion: completion)
                            return
                        }

                        guard let createdSnapshot,
                              let room = self.parseRoom(document: createdSnapshot) else {
                            self.dispatchResult(.failure(.invalidState("Failed to parse created room.")), completion: completion)
                            return
                        }

                        self.dispatchResult(.success(room), completion: completion)
                    }
                }
            }
    }

    private func generateRoomCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in alphabet.randomElement() ?? "A" })
    }

    private func normalize(_ code: String) -> String {
        return code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func parseRoom(document: DocumentSnapshot) -> Room? {
        guard let data = document.data(),
              let code = data["code"] as? String,
              let hostUID = data["hostUID"] as? String,
              let statusRaw = data["status"] as? String,
              let status = RoomStatus(rawValue: statusRaw),
              let weatherModeRaw = data["weatherSourceMode"] as? String,
              let weatherSourceMode = RoomWeatherSourceMode(rawValue: weatherModeRaw),
              let playbackMap = data["playbackState"] as? [String: Any],
              let playbackState = parsePlaybackState(map: playbackMap)
        else {
            return nil
        }

        let weatherSnapshot: RoomWeatherSnapshot?
        if let weatherMap = data["weatherSnapshot"] as? [String: Any] {
            weatherSnapshot = parseWeatherSnapshot(map: weatherMap)
        } else {
            weatherSnapshot = nil
        }

        let createdAt = date(from: data["createdAt"]) ?? Date()
        let lastActivityAt = date(from: data["lastActivityAt"]) ?? createdAt
        let expiresAt = date(from: data["expiresAt"])

        return Room(
            id: document.documentID,
            code: code,
            hostUID: hostUID,
            status: status,
            weatherSourceMode: weatherSourceMode,
            selectedCity: data["selectedCity"] as? String,
            weatherSnapshot: weatherSnapshot,
            playbackState: playbackState,
            createdAt: createdAt,
            lastActivityAt: lastActivityAt,
            expiresAt: expiresAt
        )
    }

    private func parseMember(document: QueryDocumentSnapshot) -> RoomMember? {
        let data = document.data()
        guard let displayName = data["displayName"] as? String,
              let roleRaw = data["role"] as? String,
              let role = RoomRole(rawValue: roleRaw)
        else {
            return nil
        }

        return RoomMember(
            id: document.documentID,
            displayName: displayName,
            role: role,
            joinedAt: date(from: data["joinedAt"]) ?? Date(),
            lastSeenAt: date(from: data["lastSeenAt"]) ?? Date(),
            isOnline: data["isOnline"] as? Bool ?? false
        )
    }

    private func parseSuggestion(document: DocumentSnapshot) -> SongSuggestion? {
        guard let data = document.data(),
              let song = Song.fromDictionary(data),
              let suggestedByUID = data["suggestedByUID"] as? String
        else {
            return nil
        }

        return SongSuggestion(
            id: document.documentID,
            song: song,
            suggestedByUID: suggestedByUID,
            createdAt: date(from: data["createdAt"]) ?? Date(),
            isApproved: data["isApproved"] as? Bool ?? false
        )
    }

    private func parseQueueItem(document: QueryDocumentSnapshot) -> RoomQueueItem? {
        let data = document.data()
        guard let song = Song.fromDictionary(data),
              let addedByUID = data["addedByUID"] as? String,
              let sourceRaw = data["source"] as? String,
              let source = RoomQueueSource(rawValue: sourceRaw)
        else {
            return nil
        }

        return RoomQueueItem(
            id: document.documentID,
            song: song,
            addedByUID: addedByUID,
            source: source,
            votes: data["votes"] as? Int ?? 0,
            addedAt: date(from: data["addedAt"]) ?? Date()
        )
    }

    private func parsePlaybackState(map: [String: Any]) -> RoomPlaybackState? {
        guard let isPlaying = map["isPlaying"] as? Bool,
              let offsetSeconds = map["offsetSeconds"] as? Double else {
            return nil
        }

        return RoomPlaybackState(
            trackIdentifier: map["trackIdentifier"] as? String,
            isPlaying: isPlaying,
            startedAt: date(from: map["startedAt"]),
            offsetSeconds: offsetSeconds,
            updatedByUID: map["updatedByUID"] as? String,
            updatedAt: date(from: map["updatedAt"]) ?? Date()
        )
    }

    private func parseWeatherSnapshot(map: [String: Any]) -> RoomWeatherSnapshot? {
        guard let conditionText = map["conditionText"] as? String,
              let temperatureCelsius = map["temperatureCelsius"] as? Double,
              let locationLabel = map["locationLabel"] as? String else {
            return nil
        }

        return RoomWeatherSnapshot(
            conditionText: conditionText,
            temperatureCelsius: temperatureCelsius,
            locationLabel: locationLabel,
            fetchedAt: date(from: map["fetchedAt"]) ?? Date()
        )
    }

    private func playbackDictionary(from state: RoomPlaybackState) -> [String: Any] {
        return [
            "trackIdentifier": state.trackIdentifier as Any,
            "isPlaying": state.isPlaying,
            "startedAt": state.startedAt.map(Timestamp.init(date:)) as Any,
            "offsetSeconds": state.offsetSeconds,
            "updatedByUID": state.updatedByUID as Any,
            "updatedAt": Timestamp(date: state.updatedAt)
        ]
    }

    private func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = value as? Date {
            return date
        }

        return nil
    }

    private func dispatchResult<T>(
        _ result: Result<T, RoomFeatureError>,
        completion: @escaping (Result<T, RoomFeatureError>) -> Void
    ) {
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func map(error: Error) -> RoomFeatureError {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           let code = FirestoreErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .permissionDenied:
                return .permissionDenied
            case .notFound:
                return .roomNotFound
            case .unavailable, .deadlineExceeded:
                return .networkUnavailable
            default:
                return .unknown(nsError.localizedDescription)
            }
        }

        return .unknown(nsError.localizedDescription)
    }

    private func makeNSError(_ error: RoomFeatureError) -> NSError {
        return NSError(
            domain: "RoomFeatureError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown room error"]
        )
    }
}
