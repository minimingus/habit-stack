import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false

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
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
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
