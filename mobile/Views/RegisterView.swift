import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Back Button
                BackButton(text: "Back to Login") {
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Register")
                        .font(AppTheme.titleLarge)
                        .foregroundColor(AppTheme.onSurface)
                    
                    Text("And start taking notes")
                        .font(AppTheme.bodyMedium)
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Registration Form
                VStack(spacing: 16) {
                    LabeledTextField(
                        value: $firstName,
                        label: "First Name",
                        placeholder: "Example: Taha"
                    )
                    
                    LabeledTextField(
                        value: $lastName,
                        label: "Last Name",
                        placeholder: "Example: Hamifar"
                    )
                    
                    LabeledTextField(
                        value: $username,
                        label: "Username",
                        placeholder: "Example: @HamifarTaha"
                    )
                    
                    LabeledTextField(
                        value: $email,
                        label: "Email Address",
                        placeholder: "Example: hamifar.taha@gmail.com"
                    )
                    
                    LabeledTextField(
                        value: $password,
                        label: "Password",
                        placeholder: "********",
                        isSecure: true
                    )
                    
                    LabeledTextField(
                        value: $confirmPassword,
                        label: "Retype Password",
                        placeholder: "********",
                        isSecure: true
                    )
                }
                
                // Register Button
                ForwardButton(
                    text: "Register",
                    action: register,
                    isLoading: isLoading,
                    enabled: isFormValid
                )
                
                // Login Link
                Button(action: { dismiss() }) {
                    Text("Already have an account? Login here")
                        .font(AppTheme.bodyLarge)
                        .foregroundColor(AppTheme.purple)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundLight)
        .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
            Button("OK") {
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: .constant(!successMessage.isEmpty)) {
            Button("OK") {
                successMessage = ""
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
    
    private func register() {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        let registerRequest = RegisterRequest(
            username: username,
            password: password,
            email: email,
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName
        )
        
        authManager.register(registerRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    successMessage = "Account created successfully! Please login."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            )
            .store(in: &authManager.cancellables)
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager.shared)
}