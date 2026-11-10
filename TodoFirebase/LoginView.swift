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
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            SecureField("Password (min 6 characters)", text: $password)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 20) {
                Button("Login") {
                    auth.signIn(email: email, password: password)
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Up") {
                    auth.signUp(email: email, password: password)
                }
                .buttonStyle(.bordered)
            }

            if !auth.errorMessage.isEmpty {
                Text(auth.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
    }
}
