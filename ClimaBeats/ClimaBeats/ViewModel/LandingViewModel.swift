import FirebaseAuth

final class LandingViewModel {
    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
}
