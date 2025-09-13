import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkManager = NetworkManager.shared
    @State private var note: Note
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    let onNoteUpdated: (() -> Void)?
    
    init(note: Note, onNoteUpdated: (() -> Void)? = nil) {
        _note = State(initialValue: note)
        _editedTitle = State(initialValue: note.title)
        _editedDescription = State(initialValue: note.description)
        self.onNoteUpdated = onNoteUpdated
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.onSurface)
                }
                
                Spacer()
                
                Text(note.id == 0 ? "Add Note" : "Edit Note")
                    .font(AppTheme.titleMedium)
                    .foregroundColor(AppTheme.onSurface)
                
                Spacer()
                
                if note.id != 0 {
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.backgroundLight)
            
            // Content
            VStack(spacing: 16) {
                // Title Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(AppTheme.bodyMedium)
                        .foregroundColor(AppTheme.onSurface)
                    
                    TextField("Note title", text: $editedTitle)
                        .font(AppTheme.bodyLarge)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Content Field
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $editedDescription)
                        .font(AppTheme.bodyLarge)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 300)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(AppTheme.backgroundLight)
            
            // Bottom Bar with Last Updated
            VStack(spacing: 8) {
                Text("Last updated: \(note.formattedUpdatedDate)")
                    .font(AppTheme.labelMedium)
                    .foregroundColor(AppTheme.onSurfaceVariant)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.backgroundLight)
        }
        .background(AppTheme.backgroundLight)
        .onAppear {
            editedTitle = note.title
            editedDescription = note.description
        }
        .onDisappear {
            // Auto-save when leaving the view
            if editedTitle != note.title || editedDescription != note.description {
                saveNote()
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    private func startEditing() {
        isEditing = true
        editedTitle = note.title
        editedDescription = note.description
    }
    
    private func cancelEditing() {
        isEditing = false
        editedTitle = note.title
        editedDescription = note.description
        errorMessage = ""
    }
    
    private func saveNote() {
        isLoading = true
        errorMessage = ""
        
        let updateRequest = UpdateNoteRequest(
            title: editedTitle,
            description: editedDescription
        )
        
        networkManager.updateNote(id: note.id, updateRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { updatedNote in
                    note = updatedNote
                    isEditing = false
                    onNoteUpdated?()
                }
            )
            .store(in: &networkManager.cancellables)
    }
    
    private func deleteNote() {
        isLoading = true
        errorMessage = ""
        
        networkManager.deleteNote(id: note.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    // Note deleted successfully, refresh the list and navigate back
                    onNoteUpdated?()
                    // Small delay to ensure callback is processed before dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
            .store(in: &networkManager.cancellables)
    }
}

struct CreateNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var networkManager = NetworkManager.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let onNoteCreated: (Note) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.onSurface)
                }
                
                Spacer()
                
                Text("Add Note")
                    .font(AppTheme.titleMedium)
                    .foregroundColor(AppTheme.onSurface)
                
                Spacer()
                
                Button(action: createNote) {
                    Text("Save")
                        .font(AppTheme.bodyLarge)
                        .foregroundColor(AppTheme.purple)
                }
                .disabled(isLoading || title.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.backgroundLight)
            
            // Content
            VStack(spacing: 16) {
                // Title Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(AppTheme.bodyMedium)
                        .foregroundColor(AppTheme.onSurface)
                    
                    TextField("Note title", text: $title)
                        .font(AppTheme.bodyLarge)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Content Field
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $description)
                        .font(AppTheme.bodyLarge)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 300)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(AppTheme.backgroundLight)
        }
        .background(AppTheme.backgroundLight)
    }
    
    private func createNote() {
        isLoading = true
        errorMessage = ""
        
        let createRequest = CreateNoteRequest(
            title: title,
            description: description
        )
        
        networkManager.createNote(createRequest)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { newNote in
                    onNoteCreated(newNote)
                    dismiss()
                }
            )
            .store(in: &networkManager.cancellables)
    }
}

#Preview {
    NoteDetailView(note: Note(
        id: 1,
        title: "Sample Note",
        description: "This is a sample note description that shows how the note detail view looks.",
        createdAt: "2024-01-01T12:00:00.000000Z",
        updatedAt: "2024-01-01T12:00:00.000000Z",
        creatorName: "John Doe",
        creatorUsername: "johndoe"
    ))
    .environmentObject(AuthManager.shared)
}