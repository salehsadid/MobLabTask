import SwiftUI
import FirebaseCore

@main
struct TodoFirebaseApp: App {
    @StateObject private var auth = AuthViewModel()

    init() {
        // Reads GoogleService-Info.plist and connects the app to Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
}
