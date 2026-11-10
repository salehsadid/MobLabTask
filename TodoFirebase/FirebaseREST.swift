import Foundation

// Talks to Firebase directly over HTTPS (Firebase REST API).
// No Firebase SDK / Swift Package is needed.

// Reads API_KEY and PROJECT_ID from GoogleService-Info.plist (downloaded from Firebase Console)
enum FirebaseConfig {
    static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = plist as? [String: Any]
        else {
            fatalError("GoogleService-Info.plist not found. Add it to the TodoFirebase target.")
        }
        return dict
    }()

    static var apiKey: String { values["API_KEY"] as? String ?? "" }
    static var projectId: String { values["PROJECT_ID"] as? String ?? "" }

    // Firestore base URL: .../projects/<id>/databases/(default)/documents
    static var firestoreBase: String {
        "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents"
    }
}

struct FirebaseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum FirebaseREST {

    // Sends one HTTP request and returns the JSON response as a dictionary
    static func send(_ urlString: String,
                     method: String = "GET",
                     json: [String: Any]? = nil,
                     form: String? = nil,
                     token: String? = nil) async throws -> [String: Any] {

        guard let url = URL(string: urlString) else {
            throw FirebaseError(message: "Bad URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // The API key from the iOS app is restricted to this bundle ID
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        // Logged-in user's token (Firestore rules check this)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let json = json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        } else if let form = form {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = form.data(using: .utf8)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let result = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if !(200...299).contains(status) {
            let error = result["error"] as? [String: Any]
            let message = error?["message"] as? String ?? "HTTP error \(status)"
            throw FirebaseError(message: friendly(message))
        }
        return result
    }

    // Turns Firebase error codes into readable messages
    static func friendly(_ code: String) -> String {
        if code.hasPrefix("EMAIL_EXISTS") { return "This email is already registered. Tap Login." }
        if code.hasPrefix("EMAIL_NOT_FOUND") || code.hasPrefix("INVALID_PASSWORD")
            || code.hasPrefix("INVALID_LOGIN_CREDENTIALS") { return "Wrong email or password." }
        if code.hasPrefix("INVALID_EMAIL") { return "Invalid email address." }
        if code.hasPrefix("WEAK_PASSWORD") { return "Password must be at least 6 characters." }
        if code.hasPrefix("MISSING_PASSWORD") { return "Enter a password." }
        if code.hasPrefix("OPERATION_NOT_ALLOWED") { return "Email/Password sign-in is not enabled in Firebase Console." }
        return code
    }

    // Encodes a value for use inside a URL / form body
    static func encode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
