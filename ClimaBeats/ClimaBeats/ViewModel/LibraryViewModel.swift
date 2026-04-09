import Foundation

final class LibraryViewModel {
    func fetchSongs() -> [Song] {
        return LibraryManager.shared.fetchSongs()
    }

    func importSong(from sourceURL: URL, completion: @escaping (Result<Song, Error>) -> Void) {
        LibraryManager.shared.importSong(from: sourceURL, completion: completion)
    }

    @discardableResult
    func deleteSong(_ song: Song) -> Bool {
        return LibraryManager.shared.deleteSong(song)
    }
}
