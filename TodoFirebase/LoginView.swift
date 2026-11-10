import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("Firebase Todo")
                .font(.largeTitle).bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Password (min 6 characters)", text: $password)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Login") {
                    auth.signIn(email: email, password: password)
                }
                .keyboardShortcut(.defaultAction)

                Button("Sign Up") {
                    auth.signUp(email: email, password: password)
                }
            }

            if !auth.errorMessage.isEmpty {
                Text(auth.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}
