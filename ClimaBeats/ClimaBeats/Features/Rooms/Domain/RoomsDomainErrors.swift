import Foundation

enum RoomFeatureError: LocalizedError {
    case unauthenticated
    case permissionDenied
    case invalidRoomCode
    case roomNotFound
    case roomUnavailable
    case duplicateMembership
    case networkUnavailable
    case invalidState(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Please sign in to continue."
        case .permissionDenied:
            return "You do not have permission for this action."
        case .invalidRoomCode:
            return "The room code is invalid."
        case .roomNotFound:
            return "The room could not be found."
        case .roomUnavailable:
            return "This room is no longer available."
        case .duplicateMembership:
            return "You are already a member of this room."
        case .networkUnavailable:
            return "Network connection is unavailable."
        case .invalidState(let details):
            return details
        case .unknown(let message):
            return message
        }
    }
}
