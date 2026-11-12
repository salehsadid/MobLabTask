import SwiftUI

// Shows Login screen if not logged in, otherwise the task list
struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if let uid = auth.userId {
            TaskListView(authModel: auth, uid: uid)
                .id(uid) // fresh task list for each user
        } else {
            LoginView()
        }
    }
}
