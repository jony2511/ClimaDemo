import Foundation
import FirebaseAuth
import FirebaseFirestore

final class HomePlaylistViewModel {
    private let db = Firestore.firestore()
    private(set) var currentModeKey: String = "chill"

    func updateMode(from conditionText: String) {
        currentModeKey = modeKey(for: conditionText)
    }

    func modeKey(for conditionText: String) -> String {
        let condition = conditionText.lowercased()
        if condition.contains("sunny") || condition.contains("clear") {
            return "energetic"
        } else if condition.contains("partly cloudy") || condition.contains("cloudy") || condition.contains("overcast") {
            return "chill"
        } else if condition.contains("thunder") || condition.contains("heavy rain") {
            return "intense"
        } else if condition.contains("rain") || condition.contains("drizzle") || condition.contains("sleet") {
            return "melancholic"
        } else if condition.contains("snow") || condition.contains("blizzard") || condition.contains("ice") || condition.contains("freezing") {
            return "cozy"
        } else if condition.contains("fog") || condition.contains("mist") || condition.contains("haze") {
            return "mysterious"
        }
        return "chill"
    }

    func defaultSongs(for modeKey: String) -> [Song] {
        var defaults: [Song] = []

        switch modeKey {
        case "energetic":
            defaults.append(Song(name: "Ninth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Fourth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Fifth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Sixth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Seventh Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Eighth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song8"))
        case "intense":
            defaults.append(Song(name: "Sixth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Seventh Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Tenth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Fifth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Fifth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song5"))
            defaults.append(Song(name: "Fourth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song4"))
        case "melancholic":
            defaults.append(Song(name: "Ninth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song12"))
            defaults.append(Song(name: "Second Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song2"))
            defaults.append(Song(name: "Fourth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Fifth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song5"))
        case "cozy":
            defaults.append(Song(name: "First Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song1"))
            defaults.append(Song(name: "Third Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song3"))
            defaults.append(Song(name: "Eighth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song8"))
            defaults.append(Song(name: "Seventh Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Eleventh Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song12"))
        case "mysterious":
            defaults.append(Song(name: "Eighth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song8"))
            defaults.append(Song(name: "Seventh Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song7"))
            defaults.append(Song(name: "Sixth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song6"))
            defaults.append(Song(name: "Second Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song2"))
            defaults.append(Song(name: "Ninth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song10"))
        default:
            defaults.append(Song(name: "Fourth Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song4"))
            defaults.append(Song(name: "Ninth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song9"))
            defaults.append(Song(name: "Tenth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song10"))
            defaults.append(Song(name: "Eleventh Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song11"))
            defaults.append(Song(name: "Twelfth Song", albumName:"Album 2", artistName: "", imageName: "song_cover", trackName: "song12"))
            defaults.append(Song(name: "First Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song1"))
            defaults.append(Song(name: "Third Song", albumName:"Album 1", artistName: "", imageName: "song_cover", trackName: "song3"))
        }

        return defaults
    }

    func isDuplicate(_ newSong: Song, in songs: [Song]) -> Bool {
        return songs.contains(where: {
            if let lhs = $0.localFileName, let rhs = newSong.localFileName {
                return lhs == rhs
            }
            return $0.trackName == newSong.trackName
        })
    }

    func loadPlaylist(completion: @escaping ([Song]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(defaultSongs(for: currentModeKey))
            return
        }

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .getDocument { [weak self] document, error in
                guard let self else { return }

                if let error = error {
                    print("Error loading mode playlist: \(error.localizedDescription)")
                    completion(self.defaultSongs(for: self.currentModeKey))
                    return
                }

                if let data = document?.data(),
                   let songDicts = data["songs"] as? [[String: Any]] {
                    let parsedSongs = songDicts.compactMap { Song.fromDictionary($0) }
                    completion(parsedSongs.isEmpty ? self.defaultSongs(for: self.currentModeKey) : parsedSongs)
                } else {
                    completion(self.defaultSongs(for: self.currentModeKey))
                }
            }
    }

    func savePlaylist(_ songs: [Song]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let payload: [String: Any] = [
            "mode": currentModeKey,
            "songs": songs.map { $0.toDictionary() },
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .setData(payload, merge: true) { error in
                if let error = error {
                    print("Error saving mode playlist: \(error.localizedDescription)")
                }
            }
    }

    func resetPlaylist(completion: @escaping ([Song]) -> Void) {
        let defaults = defaultSongs(for: currentModeKey)
        completion(defaults)

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        db.collection("users")
            .document(uid)
            .collection("modePlaylists")
            .document(currentModeKey)
            .delete { [weak self] error in
                if let error = error {
                    print("Error deleting custom mode playlist: \(error.localizedDescription)")
                    self?.savePlaylist(defaults)
                }
            }
    }
}
