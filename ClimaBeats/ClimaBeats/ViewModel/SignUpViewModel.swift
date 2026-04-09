import FirebaseAuth
import FirebaseFirestore

final class SignUpViewModel {
    func validateFields(firstName: String, lastName: String, email: String, password: String) -> String? {
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please fill in all fields"
        }

        let cleanedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        if Utilities.isPasswordValid(cleanedPassword) == false {
            return "Please make sure your password is atleast 8 characters, contains a special character and a digit"
        }

        return nil
    }

    func signUp(firstName: String, lastName: String, email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, err in
            if err != nil {
                completion("Error creating user")
                return
            }

            let db = Firestore.firestore()
            db.collection("users").addDocument(data: ["firstname": firstName, "lastname": lastName, "uid": result!.user.uid]) { error in
                if error != nil {
                    completion("Error saving user data")
                } else {
                    completion(nil)
                }
            }
        }
    }
}
