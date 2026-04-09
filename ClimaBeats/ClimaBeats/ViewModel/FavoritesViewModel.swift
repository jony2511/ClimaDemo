import Foundation

final class FavoritesViewModel {
    func fetchFavorites(completion: @escaping ([Song]) -> Void) {
        FavoritesManager.shared.fetchFavorites(completion: completion)
    }

    func removeFavorite(song: Song, completion: @escaping (Bool) -> Void) {
        FavoritesManager.shared.removeFavorite(song: song, completion: completion)
    }
}
