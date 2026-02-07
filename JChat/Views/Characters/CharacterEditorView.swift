//
//  CharacterEditorView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct CharacterEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var modelManager: ModelManager
    @Query private var appSettings: [AppSettings]

    let character: Character?

    @State private var name: String = ""
    @State private var systemPrompt: String = ""
    @State private var preferredModelID: String? = nil
    @State private var isDefault: Bool = false
    @State private var showingSettings = false

    private var isEditing: Bool { character != nil }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Identity
                Section {
                    TextField("Name", text: $name)
                }

                // MARK: - System Prompt
                Section {
                    TextEditor(text: $systemPrompt)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, idealHeight: 120)
                        .padding(4)
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                } header: {
                    Text("System Prompt")
                }

                // MARK: - Preferred Model
                Section("Preferred Model") {
                    HStack {
                        InlineModelPicker(selectedModelID: $preferredModelID, modelManager: modelManager)
                        Spacer()
                        Button("Clear") { preferredModelID = nil }
                            .foregroundStyle(preferredModelID == nil ? Color.secondary : Color.red)
                            .disabled(preferredModelID == nil)
                    }

                    if preferredModelID == nil {
                        Text(globalDefaultDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        if !isGlobalDefaultSet {
                            Button("Open Settings") { showingSettings = true }
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }

                // MARK: - Options
                Section("Options") {
                    Toggle("Set as Default Character", isOn: $isDefault)

                    if isEditing, let character {
                        Text("Created: \(character.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Character" : "New Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let character {
                    name = character.name
                    systemPrompt = character.systemPrompt
                    preferredModelID = character.preferredModelID
                    isDefault = character.isDefault
                }
            }
        }
        .frame(minWidth: 450, minHeight: 380)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // If setting as default, clear isDefault on all others
        if isDefault {
            let descriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.isDefault == true })
            if let existing = try? modelContext.fetch(descriptor) {
                for char in existing {
                    char.isDefault = false
                }
            }
        }

        let cleanedPreferredModelID: String?
        if let preferredModelID {
            let trimmed = preferredModelID.trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedPreferredModelID = trimmed.isEmpty ? nil : trimmed
        } else {
            cleanedPreferredModelID = nil
        }

        var finalPreferredModelID = cleanedPreferredModelID
        if let cleanedPreferredModelID {
            let descriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == cleanedPreferredModelID })
            let cachedCount = (try? modelContext.fetchCount(FetchDescriptor<CachedModel>())) ?? 0
            if cachedCount > 0, (try? modelContext.fetch(descriptor).first) == nil {
                finalPreferredModelID = nil
            }
        }

        if let character {
            // Update existing
            character.name = trimmedName
            character.systemPrompt = systemPrompt
            character.preferredModelID = finalPreferredModelID
            character.isDefault = isDefault
        } else {
            // Create new
            let newCharacter = Character(
                name: trimmedName,
                systemPrompt: systemPrompt,
                preferredModelID: finalPreferredModelID,
                isDefault: isDefault
            )
            modelContext.insert(newCharacter)
        }

        try? modelContext.save()
        dismiss()
    }

    // MARK: - Helpers

    private var globalDefaultDescription: String {
        guard let defaultModelID = appSettings.first?.defaultModelID,
              !defaultModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Using Global Default Model (not set)"
        }
        let displayName = modelDisplayName(for: defaultModelID)
        return "Using Global Default Model: \(displayName)"
    }

    private var isGlobalDefaultSet: Bool {
        guard let defaultModelID = appSettings.first?.defaultModelID else { return false }
        return !defaultModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func modelDisplayName(for id: String) -> String {
        if let model = modelManager.filteredModels.first(where: { $0.id == id }) ??
            modelManager.favoriteModels.first(where: { $0.id == id }) {
            return model.displayName
        }
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }

}

#Preview("New Character") {
    CharacterEditorView(
        modelManager: ModelManager(),
        character: nil
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}

#Preview("Edit Character") {
    CharacterEditorView(
        modelManager: ModelManager(),
        character: Character(
            name: "Code Assistant",
            systemPrompt: "You are a helpful coding assistant. You write clean, well-documented code.",
            preferredModelID: "anthropic/claude-sonnet-4",
            isDefault: true
        )
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
