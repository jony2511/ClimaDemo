//
//  Song.swift
//  ClimaBeats
//
//

import Foundation

struct Song {
    let name: String
    let albumName: String
    let artistName: String
    let imageName: String
    let trackName: String
    let localFileName: String?

    var isLocalFile: Bool {
        return localFileName != nil
    }

    init(name: String, albumName: String, artistName: String, imageName: String, trackName: String, localFileName: String? = nil) {
        self.name = name
        self.albumName = albumName
        self.artistName = artistName
        self.imageName = imageName
        self.trackName = trackName
        self.localFileName = localFileName
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "albumName": albumName,
            "artistName": artistName,
            "imageName": imageName,
            "trackName": trackName,
            "localFileName": localFileName as Any
        ]
    }
    
    // Create from Firestore dictionary
    static func fromDictionary(_ dict: [String: Any]) -> Song? {
        guard let name = dict["name"] as? String,
              let albumName = dict["albumName"] as? String,
              let artistName = dict["artistName"] as? String,
              let imageName = dict["imageName"] as? String,
              let trackName = dict["trackName"] as? String else {
            return nil
        }
        let localFileName = dict["localFileName"] as? String
        return Song(name: name, albumName: albumName, artistName: artistName, imageName: imageName, trackName: trackName, localFileName: localFileName)
    }
}
