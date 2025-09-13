//
//  SimpleNoteApp.swift
//  SimpleNote
//
//  Created by Amir on 9/13/25.
//

import SwiftUI

@main
struct SimpleNoteApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
