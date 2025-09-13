//
//  Components.swift
//  SimpleNote
//
//  Created by Amir on 9/13/25.
//

import SwiftUI

struct LabeledTextField: View {
    @Binding var value: String
    let label: String
    let placeholder: String
    var isSecure: Bool = false
    var trailingIcon: (() -> AnyView)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTheme.bodyMedium)
                .foregroundColor(AppTheme.onSurface)
            
            HStack {
                if isSecure {
                    SecureField(placeholder, text: $value)
                        .font(AppTheme.bodyLarge)
                } else {
                    TextField(placeholder, text: $value)
                        .font(AppTheme.bodyLarge)
                }
                
                if let trailingIcon = trailingIcon {
                    trailingIcon()
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct BackButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.left")
                Text(text)
            }
            .font(AppTheme.bodyLarge)
            .foregroundColor(AppTheme.purple)
        }
    }
}

struct ForwardButton: View {
    let text: String
    let action: () -> Void
    var backgroundColor: Color = AppTheme.purple
    var foregroundColor: Color = AppTheme.onPrimary
    var isLoading: Bool = false
    var enabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                }
                Text(text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .disabled(!enabled || isLoading)
        .opacity(enabled ? 1.0 : 0.6)
    }
}

struct ConfirmationDialog: View {
    let title: String
    let text: String
    let onDismiss: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(AppTheme.titleMedium)
                .foregroundColor(AppTheme.onSurface)
            
            Text(text)
                .font(AppTheme.bodyLarge)
                .foregroundColor(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    onDismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(AppTheme.onSurface)
                .cornerRadius(8)
                
                Button("Confirm") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.purple)
                .foregroundColor(AppTheme.onPrimary)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// Extension to make trailingIcon work with AnyView
extension LabeledTextField {
    init<Content: View>(
        value: Binding<String>,
        label: String,
        placeholder: String,
        isSecure: Bool = false,
        @ViewBuilder trailingIcon: @escaping () -> Content
    ) {
        self._value = value
        self.label = label
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.trailingIcon = { AnyView(trailingIcon()) }
    }
}
