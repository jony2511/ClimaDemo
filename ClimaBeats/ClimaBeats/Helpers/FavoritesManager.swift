//
//  FavoritesManager.swift
//  ClimaBeats
//
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FavoritesManager {
    
    static let shared = FavoritesManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Get current user's UID
    private var currentUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Add to Favorites
    func addFavorite(song: Song, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUID else {
            completion(false)
            return
        }
        
        let docID = "\(song.name)_\(song.trackName)" // Unique identifier
        db.collection("users").document(uid).collection("favorites").document(docID).setData(song.toDictionary()) { error in
            if let error = error {
                print("Error adding favorite: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Remove from Favorites
    func removeFavorite(song: Song, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUID else {
            completion(false)
            return
        }
        
        let docID = "\(song.name)_\(song.trackName)"
        db.collection("users").document(uid).collection("favorites").document(docID).delete { error in
            if let error = error {
                print("Error removing favorite: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Check if Favorited
    func isFavorite(song: Song, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUID else {
            completion(false)
            return
        }
        
        let docID = "\(song.name)_\(song.trackName)"
        db.collection("users").document(uid).collection("favorites").document(docID).getDocument { document, error in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Fetch All Favorites
    func fetchFavorites(completion: @escaping ([Song]) -> Void) {
        guard let uid = currentUID else {
            completion([])
            return
        }
        
        db.collection("users").document(uid).collection("favorites").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching favorites: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var songs: [Song] = []
            for document in snapshot?.documents ?? [] {
                if let song = Song.fromDictionary(document.data()) {
                    songs.append(song)
                }
            }
            completion(songs)
        }
    }
}
