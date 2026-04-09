//
//  LibraryManager.swift
//  ClimaBeats
//

import Foundation

final class LibraryManager {

    static let shared = LibraryManager()

    private let storageFolderName = "ImportedSongs"
    private let userDefaultsKey = "local_library_songs"

    private init() {}

    func fetchSongs() -> [Song] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            let records = try JSONDecoder().decode([LocalSongRecord].self, from: data)
            return records.map {
                Song(
                    name: $0.name,
                    albumName: $0.albumName,
                    artistName: $0.artistName,
                    imageName: $0.imageName,
                    trackName: $0.trackName,
                    localFileName: $0.localFileName
                )
            }
        } catch {
            print("Error reading local library: \(error.localizedDescription)")
            return []
        }
    }

    func importSong(from sourceURL: URL, completion: @escaping (Result<Song, Error>) -> Void) {
        do {
            let destinationFolder = try ensureStorageFolderExists()
            let extensionName = sourceURL.pathExtension.lowercased()
            let fileName = "\(UUID().uuidString).\(extensionName)"
            let destinationURL = destinationFolder.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let songName = sourceURL.deletingPathExtension().lastPathComponent
            let song = Song(
                name: songName,
                albumName: "Imported",
                artistName: "Local File",
                imageName: "song_cover",
                trackName: destinationURL.deletingPathExtension().lastPathComponent,
                localFileName: destinationURL.lastPathComponent
            )

            var songs = fetchSongs()
            songs.append(song)
            saveSongs(songs)
            completion(.success(song))
        } catch {
            completion(.failure(error))
        }
    }

    @discardableResult
    func deleteSong(_ song: Song) -> Bool {
        var fileDeletedSuccessfully = true

        if let localFileName = song.localFileName,
           let url = localFileURL(fileName: localFileName),
           FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Error deleting local song file: \(error.localizedDescription)")
                fileDeletedSuccessfully = false
            }
        }

        var songs = fetchSongs()
        let initialCount = songs.count

        if let localFileName = song.localFileName {
            songs.removeAll { $0.localFileName == localFileName }
        } else {
            songs.removeAll {
                $0.trackName == song.trackName &&
                $0.name == song.name &&
                $0.artistName == song.artistName
            }
        }

        let metadataRemoved = songs.count < initialCount
        saveSongs(songs)

        return fileDeletedSuccessfully && metadataRemoved
    }

    func localFileURL(fileName: String) -> URL? {
        do {
            let folderURL = try ensureStorageFolderExists()
            return folderURL.appendingPathComponent(fileName)
        } catch {
            return nil
        }
    }

    private func saveSongs(_ songs: [Song]) {
        let records = songs.map {
            LocalSongRecord(
                name: $0.name,
                albumName: $0.albumName,
                artistName: $0.artistName,
                imageName: $0.imageName,
                trackName: $0.trackName,
                localFileName: $0.localFileName
            )
        }

        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving local library: \(error.localizedDescription)")
        }
    }

    private func ensureStorageFolderExists() throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsURL.appendingPathComponent(storageFolderName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        return folderURL
    }
}

private struct LocalSongRecord: Codable {
    let name: String
    let albumName: String
    let artistName: String
    let imageName: String
    let trackName: String
    let localFileName: String?
}
