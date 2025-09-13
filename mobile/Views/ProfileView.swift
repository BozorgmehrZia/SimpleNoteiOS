import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingChangePassword = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Profile")
                    .font(AppTheme.titleLarge)
                    .foregroundColor(AppTheme.onSurface)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.purple)
                        
                        if let user = authManager.currentUser {
                            Text(user.displayName)
                                .font(AppTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.onSurface)
                            
                            Text("@\(user.username)")
                                .font(AppTheme.bodyMedium)
                                .foregroundColor(AppTheme.onSurfaceVariant)
                            
                            if !user.email.isEmpty {
                                Text(user.email)
                                    .font(AppTheme.bodyMedium)
                                    .foregroundColor(AppTheme.onSurfaceVariant)
                            }
                        } else {
                            Text("Loading...")
                                .font(AppTheme.titleMedium)
                                .foregroundColor(AppTheme.onSurfaceVariant)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Actions
                    VStack(spacing: 16) {
                        Button(action: { showingChangePassword = true }) {
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(AppTheme.purple)
                                Text("Change Password")
                                    .font(AppTheme.bodyLarge)
                                    .foregroundColor(AppTheme.onSurface)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.onSurfaceVariant)
                            }
                            .padding()
                            .background(AppTheme.surfaceVariant)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Logout")
                                    .font(AppTheme.bodyLarge)
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.onSurfaceVariant)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 50)
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("SimpleNote")
                            .font(AppTheme.titleMedium)
                            .foregroundColor(AppTheme.onSurface)
                        Text("Version 1.0.0")
                            .font(AppTheme.bodyMedium)
                            .foregroundColor(AppTheme.onSurfaceVariant)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundLight)
        .onAppear {
            // Refresh user info when view appears
            if authManager.isAuthenticated {
                authManager.getUserInfo()
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in }
                    )
                    .store(in: &authManager.cancellables)
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.onSurface)
                }
                Spacer()
                Text("Change Password")
                    .font(AppTheme.titleMedium)
                    .foregroundColor(AppTheme.onSurface)
                Spacer()
                Button(action: changePassword) {
                    Text("Save")
                        .font(AppTheme.bodyLarge)
                        .foregroundColor(AppTheme.purple)
                }
                .disabled(isLoading || !isFormValid)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.backgroundLight)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(AppTheme.bodyMedium)
                            .foregroundColor(AppTheme.onSurface)
                        SecureField("Enter current password", text: $oldPassword)
                            .font(AppTheme.bodyLarge)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(AppTheme.bodyMedium)
                            .foregroundColor(AppTheme.onSurface)
                        SecureField("Enter new password", text: $newPassword)
                            .font(AppTheme.bodyLarge)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(AppTheme.bodyMedium)
                            .foregroundColor(AppTheme.onSurface)
                        SecureField("Confirm new password", text: $confirmPassword)
                            .font(AppTheme.bodyLarge)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(AppTheme.bodyMedium)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(AppTheme.bodyMedium)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if isLoading {
                        ProgressView("Changing password...")
                            .font(AppTheme.bodyMedium)
                            .foregroundColor(AppTheme.onSurfaceVariant)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .background(AppTheme.backgroundLight)
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private var isFormValid: Bool {
        !oldPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }
    
    private func changePassword() {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        let changePasswordRequest = ChangePasswordRequest(
            oldPassword: oldPassword,
            newPassword: newPassword
        )
        
        authManager.changePassword(changePasswordRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    successMessage = "Password changed successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            )
            .store(in: &authManager.cancellables)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}