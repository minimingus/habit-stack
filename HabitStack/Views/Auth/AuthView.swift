import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var isDevLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("HabitStack")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color("Teal"))
                    Text("Build better habits, one day at a time.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                }

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await signIn() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showSignUp = true
                    } label: {
                        Text("Create an Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundStyle(Color("Teal"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Teal"), lineWidth: 1.5))
                    }

                    Button {
                        Task { await devLogin() }
                    } label: {
                        Group {
                            if isDevLoading {
                                ProgressView().tint(Color("Stone500"))
                            } else {
                                Label("Dev Login", systemImage: "bolt.fill")
                                    .font(.subheadline.bold())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color("Stone500"))
                    }
                    .disabled(isDevLoading)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private func devLogin() async {
        isDevLoading = true
        errorMessage = nil
        let id = UUID().uuidString.prefix(8).lowercased()
        let fakeEmail = "dev+\(id)@habitstack.test"
        let fakePassword = "devpass123"
        do {
            let result = try await supabase.auth.signUp(email: fakeEmail, password: fakePassword)
            if result.session == nil {
                // Auto-confirm not enabled — fall back to sign-in attempt
                try await supabase.auth.signIn(email: fakeEmail, password: fakePassword)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isDevLoading = false
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
