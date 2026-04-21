import Foundation

final class DefaultRoomPlaybackSync: RoomPlaybackSyncProtocol {
    func canonicalOffset(at now: Date, for state: RoomPlaybackState) -> TimeInterval {
        guard state.isPlaying, let startedAt = state.startedAt else {
            return max(state.offsetSeconds, 0)
        }

        let elapsed = now.timeIntervalSince(startedAt)
        return max(state.offsetSeconds + elapsed, 0)
    }

    func shouldReconcile(localOffset: TimeInterval, canonicalOffset: TimeInterval, threshold: TimeInterval) -> Bool {
        return abs(localOffset - canonicalOffset) > threshold
    }
}
