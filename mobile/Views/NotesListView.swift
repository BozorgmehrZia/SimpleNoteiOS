import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var networkManager = NetworkManager.shared
    @State private var notes: [Note] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Binding var showingCreateNote: Bool
    @Binding var refreshTrigger: Bool
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var selectedNote: Note? = nil
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("My Notes")
                    .font(AppTheme.titleLarge)
                    .foregroundColor(AppTheme.onSurface)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Search Bar
            SearchBar(text: $searchText, onSearchButtonClicked: searchNotes)
            
            // Content
            if isLoading && notes.isEmpty {
                Spacer()
                ProgressView("Loading notes...")
                Spacer()
            } else if notes.isEmpty && !isLoading {
                EmptyNotesView(message: searchText.isEmpty ? "Create your first note!" : "nothing found")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(notes) { note in
                            Button(action: {
                                selectedNote = note
                            }) {
                                NoteCardView(note: note)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    // Pagination Controls
                    if !notes.isEmpty {
                        HStack(spacing: 12) {
                            // Previous Page Button
                            Button(action: {
                                if currentPage > 1 {
                                    currentPage -= 1
                                    loadPage(currentPage)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(AppTheme.bodyMedium)
                                .foregroundColor(currentPage > 1 ? AppTheme.purple : AppTheme.onSurfaceVariant)
                            }
                            .disabled(currentPage <= 1)
                            
                            Spacer()
                            
                            // Page Info
                            Text("Page \(currentPage) of \(totalPages)")
                                .font(AppTheme.bodyMedium)
                                .foregroundColor(AppTheme.onSurfaceVariant)
                            
                            Spacer()
                            
                            // Next Page Button
                            Button(action: {
                                if currentPage < totalPages {
                                    currentPage += 1
                                    loadPage(currentPage)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(AppTheme.bodyMedium)
                                .foregroundColor(currentPage < totalPages ? AppTheme.purple : AppTheme.onSurfaceVariant)
                            }
                            .disabled(currentPage >= totalPages)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.surfaceVariant)
                        .cornerRadius(8)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                .refreshable {
                    await refreshNotes()
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundLight)
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note) {
                // Force refresh the notes list
                DispatchQueue.main.async {
                    loadNotes()
                }
            }
        }
        .onAppear {
            loadNotes()
        }
        .onChange(of: searchText) {
            if searchText.isEmpty {
                loadNotes()
            }
        }
        .onChange(of: refreshTrigger) {
            loadNotes()
        }
    }
    
    private func loadNotes() {
        isLoading = true
        errorMessage = ""
        currentPage = 1
        
        networkManager.getNotes(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    // Force UI update by replacing the entire array
                    notes = response.results
                    totalPages = response.totalPages
                    print("Notes loaded: \(notes.count) notes, Page \(currentPage) of \(totalPages)")
                }
            )
            .store(in: &networkManager.cancellables)
    }
    
    private func loadPage(_ page: Int) {
        isLoading = true
        errorMessage = ""
        
        if searchText.isEmpty {
            networkManager.getNotes(page: page)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = error.localizedDescription
                        }
                    },
                    receiveValue: { response in
                        notes = response.results
                        totalPages = response.totalPages
                        currentPage = page
                    }
                )
                .store(in: &networkManager.cancellables)
        } else {
            networkManager.searchNotes(query: searchText, page: page)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            errorMessage = error.localizedDescription
                        }
                    },
                    receiveValue: { response in
                        notes = response.results
                        totalPages = response.totalPages
                        currentPage = page
                    }
                )
                .store(in: &networkManager.cancellables)
        }
    }
    
    
    private func searchNotes() {
        guard !searchText.isEmpty else {
            loadNotes()
            return
        }
        
        isLoading = true
        errorMessage = ""
        currentPage = 1
        
        networkManager.searchNotes(query: searchText, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                        receiveValue: { response in
                            notes = response.results
                            totalPages = response.totalPages
                        }
            )
            .store(in: &networkManager.cancellables)
    }
    
    @MainActor
    private func refreshNotes() async {
        loadNotes()
    }
}

struct NoteCardView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(AppTheme.titleMedium)
                .fontWeight(.bold)
                .lineLimit(2)
                .foregroundColor(AppTheme.onSurface)
            
            Text(note.description)
                .font(AppTheme.bodyLarge)
                .lineLimit(6)
                .foregroundColor(AppTheme.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text(note.formattedCreatedDate)
                .font(AppTheme.bodyMedium)
                .foregroundColor(AppTheme.onSurfaceVariant)
        }
        .padding(20)
        .frame(height: 200)
        .background(AppTheme.surfaceVariant)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct EmptyNotesView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 200))
                .foregroundColor(AppTheme.onSurfaceVariant)
            
            Text(message)
                .font(AppTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search notes...", text: $text)
                .font(AppTheme.bodyLarge)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onSubmit {
                    onSearchButtonClicked()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    NotesListView(showingCreateNote: .constant(false), refreshTrigger: .constant(false))
        .environmentObject(AuthManager.shared)
}