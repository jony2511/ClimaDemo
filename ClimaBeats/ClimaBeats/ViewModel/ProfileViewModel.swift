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

    func resetPassword(completion: @escaping (Result<String, Error>) -> Void) {
        guard let email = Auth.auth().currentUser?.email else {
            completion(.failure(NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: "No logged in user email found"])))
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(email))
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
