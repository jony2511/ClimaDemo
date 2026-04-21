import Foundation

enum RoomRole: String, Codable {
    case host
    case member
}

enum RoomStatus: String, Codable {
    case active
    case ended
    case expired
}

enum RoomWeatherSourceMode: String, Codable {
    case hostLocation
    case selectedCity
}

enum RoomQueueSource: String, Codable {
    case weatherEngine
    case suggestion
}

struct RoomPlaybackState: Codable, Equatable {
    let trackIdentifier: String?
    let isPlaying: Bool
    let startedAt: Date?
    let offsetSeconds: TimeInterval
    let updatedByUID: String?
    let updatedAt: Date
}

struct RoomWeatherSnapshot: Codable, Equatable {
    let conditionText: String
    let temperatureCelsius: Double
    let locationLabel: String
    let fetchedAt: Date
}

struct Room: Codable, Equatable, Identifiable {
    let id: String
    let code: String
    let hostUID: String
    let status: RoomStatus
    let weatherSourceMode: RoomWeatherSourceMode
    let selectedCity: String?
    let weatherSnapshot: RoomWeatherSnapshot?
    let playbackState: RoomPlaybackState
    let createdAt: Date
    let lastActivityAt: Date
    let expiresAt: Date?
}

struct RoomMember: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let role: RoomRole
    let joinedAt: Date
    let lastSeenAt: Date
    let isOnline: Bool
}

struct RoomQueueItem: Identifiable {
    let id: String
    let song: Song
    let addedByUID: String
    let source: RoomQueueSource
    let votes: Int
    let addedAt: Date
}

struct SongSuggestion: Identifiable {
    let id: String
    let song: Song
    let suggestedByUID: String
    let createdAt: Date
    let isApproved: Bool
}
