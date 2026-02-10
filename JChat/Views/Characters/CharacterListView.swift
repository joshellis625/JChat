//
//  CharacterListView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct CharacterListView: View {
    @Query(sort: \Character.createdAt, order: .reverse) private var characters: [Character]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var modelManager: ModelManager

    @State private var showingEditor = false
    @State private var editingCharacter: Character?

    var body: some View {
        // TODO - Make these context options into clean, good looking UI buttons instead of mysteriously being hidden in the right-click context menu.
        NavigationStack {
            List {
                ForEach(characters) { character in
                    characterRow(character)
                        .contextMenu {
                            Button("Edit") {
                                editingCharacter = character
                                showingEditor = true
                            }
                            Button("Duplicate") {
                                duplicateCharacter(character)
                            }
                            if !character.isDefault {
                                Button("Set as Default") {
                                    setAsDefault(character)
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteCharacter(character)
                            }
                        }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingCharacter = nil
                        showingEditor = true
                    } label: {
                        Label("New Character", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                CharacterEditorView(
                    modelManager: modelManager,
                    character: editingCharacter
                )
            }
            .overlay {
                if characters.isEmpty {
                    ContentUnavailableView {
                        Label("No Characters", systemImage: "person.crop.circle")
                    } description: {
                        Text("Create a character to define a system prompt and preferred model.")
                    } actions: {
                        Button("Create Character") {
                            editingCharacter = nil
                            showingEditor = true
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Row

    private func characterRow(_ character: Character) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(character.name)
                        .font(.body.weight(.semibold))

                    if character.isDefault {
                        BadgeCapsule(text: "DEFAULT", color: .blue)
                    }
                }

                if !character.systemPrompt.isEmpty {
                    Text(character.systemPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let modelID = character.preferredModelID {
                Text(shortModelName(modelID))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func duplicateCharacter(_ character: Character) {
        let copy = Character(
            name: "\(character.name) (Copy)",
            systemPrompt: character.systemPrompt,
            preferredModelID: character.preferredModelID,
            isDefault: false
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }

    private func setAsDefault(_ character: Character) {
        // Clear all defaults
        for char in characters {
            char.isDefault = false
        }
        character.isDefault = true
        try? modelContext.save()
    }

    private func deleteCharacter(_ character: Character) {
        modelContext.delete(character)
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func shortModelName(_ modelID: String) -> String {
        if let slashIndex = modelID.lastIndex(of: "/") {
            return String(modelID[modelID.index(after: slashIndex)...])
        }
        return modelID
    }
}

#Preview {
    CharacterListView(modelManager: ModelManager())
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
