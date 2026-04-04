import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color("Stone100"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .textContentType(.newPassword)
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Color("Stone500"))
                    }
                }
                .padding()
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                    }
                    .textContentType(.newPassword)
                    Button { showConfirmPassword.toggle() } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Color("Stone500"))
                    }
                }
                .padding()
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Toggle(isOn: $agreedToTerms) {
                    Text("I agree to the Terms of Service")
                        .font(.subheadline)
                }
                .tint(Color("Teal"))

                if let success = successMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(Color("Teal"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color("Teal") : Color("Stone500"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit || isLoading)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword && agreedToTerms
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let result = try await supabase.auth.signUp(email: email, password: password)
            if result.session == nil {
                successMessage = "Check your email to confirm your account, then sign in."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
