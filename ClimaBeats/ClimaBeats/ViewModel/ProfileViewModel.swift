import Foundation
import FirebaseAuth
import FirebaseFirestore

struct ProfileData {
    let fullName: String
    let email: String
}

final class ProfileViewModel {
    private let db = Firestore.firestore()

    func loadProfile(completion: @escaping (ProfileData) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(ProfileData(fullName: "User", email: ""))
            return
        }

        db.collection("users").whereField("uid", isEqualTo: user.uid).getDocuments { snapshot, _ in
            if let document = snapshot?.documents.first {
                let firstName = document.data()["firstname"] as? String ?? ""
                let lastName = document.data()["lastname"] as? String ?? ""
                completion(ProfileData(fullName: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces), email: user.email ?? ""))
            } else {
                completion(ProfileData(fullName: "User", email: user.email ?? ""))
            }
        }
    }

    func loadFavoritesCount(completion: @escaping (Int) -> Void) {
        FavoritesManager.shared.fetchFavorites { songs in
            completion(songs.count)
        }
    }

    func updateFullName(_ fullName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            completion(.failure(NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty"])))
            return
        }

        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No logged in user found"])))
            return
        }

        let nameParts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        let firstName = nameParts.first.map(String.init) ?? trimmed
        let lastName = nameParts.dropFirst().joined(separator: " ")

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = trimmed

        changeRequest.commitChanges { [weak self] error in
            if let error {
                completion(.failure(error))
            } else {
                self?.updateFirestoreName(
                    uid: user.uid,
                    email: user.email ?? "",
                    firstName: firstName,
                    lastName: lastName,
                    completion: completion
                )
            }
        }
    }

    private func updateFirestoreName(
        uid: String,
        email: String,
        firstName: String,
        lastName: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments { [weak self] snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            let data: [String: Any] = [
                "firstname": firstName,
                "lastname": lastName,
                "uid": uid,
                "email": email
            ]

            if let document = snapshot?.documents.first {
                document.reference.updateData(data) { updateError in
                    if let updateError {
                        completion(.failure(updateError))
                    } else {
                        completion(.success("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)))
                    }
                }
            } else {
                self?.db.collection("users").addDocument(data: data) { createError in
                    if let createError {
                        completion(.failure(createError))
                    } else {
                        completion(.success("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)))
                    }
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
