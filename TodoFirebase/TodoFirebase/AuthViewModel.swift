import Foundation

// Firebase Authentication (Email/Password) using the REST API
class AuthViewModel: ObservableObject {
    @Published var userId: String?
    @Published var email: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    private var idToken = ""
    private var refreshToken = ""
    private var tokenExpiry = Date.distantPast

    private let authURL = "https://identitytoolkit.googleapis.com/v1/accounts"

    init() {
        // Stay logged in after the app restarts
        let saved = UserDefaults.standard
        if let uid = saved.string(forKey: "userId"),
           let token = saved.string(forKey: "refreshToken") {
            refreshToken = token
            email = saved.string(forKey: "email") ?? ""
            userId = uid
        }
    }

    @MainActor func signUp(email: String, password: String) {
        Task { await authenticate(endpoint: "signUp", email: email, password: password) }
    }

    @MainActor func signIn(email: String, password: String) {
        Task { await authenticate(endpoint: "signInWithPassword", email: email, password: password) }
    }

    @MainActor func signOut() {
        idToken = ""
        refreshToken = ""
        tokenExpiry = .distantPast
        email = ""
        userId = nil
        for key in ["userId", "refreshToken", "email"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @MainActor private func authenticate(endpoint: String, email: String, password: String) async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await FirebaseREST.send(
                "\(authURL):\(endpoint)?key=\(FirebaseConfig.apiKey)",
                method: "POST",
                json: [
                    "email": email.trimmingCharacters(in: .whitespaces),
                    "password": password,
                    "returnSecureToken": true
                ])

            idToken = result["idToken"] as? String ?? ""
            refreshToken = result["refreshToken"] as? String ?? ""
            let seconds = Double(result["expiresIn"] as? String ?? "3600") ?? 3600
            tokenExpiry = Date().addingTimeInterval(seconds - 60)

            let uid = result["localId"] as? String ?? ""
            self.email = result["email"] as? String ?? email

            UserDefaults.standard.set(uid, forKey: "userId")
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
            UserDefaults.standard.set(self.email, forKey: "email")

            userId = uid // switches the screen to the task list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Returns a valid ID token (Firebase tokens expire after 1 hour, so refresh when needed)
    @MainActor func validIdToken() async throws -> String {
        if !idToken.isEmpty && Date() < tokenExpiry {
            return idToken
        }
        let result = try await FirebaseREST.send(
            "https://securetoken.googleapis.com/v1/token?key=\(FirebaseConfig.apiKey)",
            method: "POST",
            form: "grant_type=refresh_token&refresh_token=\(FirebaseREST.encode(refreshToken))")

        idToken = result["id_token"] as? String ?? ""
        if let newRefresh = result["refresh_token"] as? String {
            refreshToken = newRefresh
            UserDefaults.standard.set(newRefresh, forKey: "refreshToken")
        }
        let seconds = Double(result["expires_in"] as? String ?? "3600") ?? 3600
        tokenExpiry = Date().addingTimeInterval(seconds - 60)
        return idToken
    }
}
