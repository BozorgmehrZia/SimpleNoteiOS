//
//  Theme.swift
//  SimpleNote
//
//  Created by Amir on 9/13/25.
//

import SwiftUI

struct AppTheme {
    // Colors matching Android app
    static let purple = Color(red: 0x50/255, green: 0x4E/255, blue: 0xC3/255) // #504EC3
    static let purple80 = Color(red: 0xD0/255, green: 0xBC/255, blue: 0xFF/255) // #D0BCFF
    static let purpleGrey80 = Color(red: 0xCC/255, green: 0xC2/255, blue: 0xDC/255) // #CCC2DC
    static let pink80 = Color(red: 0xEF/255, green: 0xB8/255, blue: 0xC8/255) // #EFB8C8
    
    static let purple40 = Color(red: 0x66/255, green: 0x50/255, blue: 0xA4/255) // #6650a4
    static let purpleGrey40 = Color(red: 0x62/255, green: 0x5B/255, blue: 0x71/255) // #625b71
    static let pink40 = Color(red: 0x7D/255, green: 0x52/255, blue: 0x60/255) // #7D5260
    
    // Background colors
    static let backgroundLight = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF9/255) // #F9F9F9
    static let surfaceVariant = Color(red: 0xF3/255, green: 0xF3/255, blue: 0xF3/255) // Light surface
    
    // Text colors
    static let onSurface = Color.black
    static let onSurfaceVariant = Color.gray
    static let onPrimary = Color.white
    
    // Typography
    static let titleLarge = Font.system(size: 28, weight: .bold)
    static let titleMedium = Font.system(size: 20, weight: .semibold)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let labelMedium = Font.system(size: 12, weight: .medium)
}

// Custom button style matching Android
struct ForwardButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppTheme.purple
    var foregroundColor: Color = AppTheme.onPrimary
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                    .scaleEffect(0.8)
            }
            configuration.label
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Custom text field style matching Android
struct LabeledTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(PlainTextFieldStyle())
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func labeledTextFieldStyle() -> some View {
        self.modifier(LabeledTextFieldStyle())
    }
}
