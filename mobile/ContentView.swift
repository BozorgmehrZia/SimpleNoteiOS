//
//  ContentView.swift
//  SimpleNote
//
//  Created by Amir on 9/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreateNote = false
    @State private var refreshNotes = false
    
    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $selectedTab) {
                NotesListView(showingCreateNote: $showingCreateNote, refreshTrigger: $refreshNotes)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Setting")
                    }
                    .tag(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .accentColor(AppTheme.purple)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Centered Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingCreateNote = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.purple)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .offset(y: -20) // Move closer to bottom
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingCreateNote) {
            CreateNoteView { newNote in
                // Note created successfully, refresh the notes list
                refreshNotes.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
