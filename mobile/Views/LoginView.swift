import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var passwordVisible = false
    @State private var showingRegister = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's Login")
                        .font(AppTheme.titleLarge)
                        .foregroundColor(AppTheme.onSurface)
                    
                    Text("And notes your idea")
                        .font(AppTheme.bodyMedium)
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Form Fields
                VStack(spacing: 16) {
                    LabeledTextField(
                        value: $username,
                        label: "Username",
                        placeholder: "Example: @HamifarTaha"
                    )
                    
                    LabeledTextField(
                        value: $password,
                        label: "Password",
                        placeholder: "********",
                        isSecure: !passwordVisible,
                        trailingIcon: {
                            Button(action: { passwordVisible.toggle() }) {
                                Text(passwordVisible ? "👁‍🗨" : "👁")
                                    .font(.system(size: 20))
                            }
                        }
                    )
                }
                
                // Login Button
                Button(action: login) {
                    Text("Login")
                }
                .buttonStyle(ForwardButtonStyle(isLoading: isLoading))
                .disabled(isLoading)
                
                // Divider with OR
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("  Or  ")
                        .font(AppTheme.labelMedium)
                        .foregroundColor(AppTheme.onSurfaceVariant)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                
                // Register Link
                Button(action: { showingRegister = true }) {
                    Text("Don't have any account? Register here")
                        .font(AppTheme.bodyLarge)
                        .foregroundColor(AppTheme.purple)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
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
        .sheet(isPresented: $showingRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        authManager.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    // Login successful, handled by AuthManager
                }
            )
            .store(in: &authManager.cancellables)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}