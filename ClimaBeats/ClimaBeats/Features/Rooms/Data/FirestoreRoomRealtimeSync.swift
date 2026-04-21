import Foundation
import FirebaseFirestore

final class FirestoreRoomRealtimeSync: RoomRealtimeSyncProtocol {
    private let db: Firestore
    private let syncQueue = DispatchQueue(label: "com.climabeats.rooms.presence")
    private var timers: [String: DispatchSourceTimer] = [:]

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func startPresenceHeartbeat(roomID: String, uid: String) {
        let key = timerKey(roomID: roomID, uid: uid)

        syncQueue.async { [weak self] in
            guard let self else { return }

            self.timers[key]?.cancel()

            let timer = DispatchSource.makeTimerSource(queue: self.syncQueue)
            timer.schedule(deadline: .now(), repeating: .seconds(30))
            timer.setEventHandler { [weak self] in
                self?.pushHeartbeat(roomID: roomID, uid: uid)
            }
            timer.resume()

            self.timers[key] = timer
        }
    }

    func stopPresenceHeartbeat(roomID: String, uid: String) {
        let key = timerKey(roomID: roomID, uid: uid)

        syncQueue.async { [weak self] in
            guard let self else { return }

            self.timers[key]?.cancel()
            self.timers.removeValue(forKey: key)
            self.setMemberOffline(roomID: roomID, uid: uid)
        }
    }

    private func timerKey(roomID: String, uid: String) -> String {
        return "\(roomID)::\(uid)"
    }

    private func pushHeartbeat(roomID: String, uid: String) {
        let memberRef = db.collection("rooms").document(roomID).collection("members").document(uid)
        memberRef.setData([
            "lastSeenAt": FieldValue.serverTimestamp(),
            "isOnline": true
        ], merge: true)
    }

    private func setMemberOffline(roomID: String, uid: String) {
        let memberRef = db.collection("rooms").document(roomID).collection("members").document(uid)
        memberRef.setData([
            "lastSeenAt": FieldValue.serverTimestamp(),
            "isOnline": false
        ], merge: true)
    }
}
