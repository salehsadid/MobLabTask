import Foundation
import FirebaseAuth

// Handles Firebase Email/Password authentication
class AuthViewModel: ObservableObject {
    @Published var userId: String?
    @Published var email: String = ""
    @Published var errorMessage: String = ""

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        // Called on app start and whenever the user logs in / out
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userId = user?.uid
            self?.email = user?.email ?? ""
        }
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            self?.errorMessage = error?.localizedDescription ?? ""
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.errorMessage = error?.localizedDescription ?? ""
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
