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

    let character: Character?

    @State private var name: String = ""
    @State private var systemPrompt: String = ""
    @State private var preferredModelID: String? = nil
    @State private var isDefault: Bool = false
    @State private var showingModelPicker = false

    private var isEditing: Bool { character != nil }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Identity
                Section("Identity") {
                    TextField("Name", text: $name)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Prompt / Instructions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $systemPrompt)
                            .font(.body)
                            .frame(minHeight: 150)
                    }
                }

                // MARK: - Preferred Model
                Section("Preferred Model") {
                    if let modelID = preferredModelID {
                        HStack {
                            Text(displayName(for: modelID))
                                .lineLimit(1)
                            Spacer()
                            Button("Clear") {
                                preferredModelID = nil
                            }
                            .foregroundStyle(.red)
                        }
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }

                    Button("Choose Model...") {
                        showingModelPicker = true
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
            .sheet(isPresented: $showingModelPicker) {
                NavigationStack {
                    ModelPickerSheet(
                        selectedModelID: $preferredModelID,
                        modelManager: modelManager
                    )
                }
                .frame(minWidth: 400, minHeight: 400)
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
        .frame(minWidth: 500, minHeight: 400)
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

        if let character {
            // Update existing
            character.name = trimmedName
            character.systemPrompt = systemPrompt
            character.preferredModelID = preferredModelID
            character.isDefault = isDefault
        } else {
            // Create new
            let newCharacter = Character(
                name: trimmedName,
                systemPrompt: systemPrompt,
                preferredModelID: preferredModelID,
                isDefault: isDefault
            )
            modelContext.insert(newCharacter)
        }

        try? modelContext.save()
        dismiss()
    }

    // MARK: - Helpers

    private func displayName(for modelID: String) -> String {
        if let model = modelManager.filteredModels.first(where: { $0.id == modelID }) ?? modelManager.favoriteModels.first(where: { $0.id == modelID }) {
            return model.displayName
        }
        if let slashIndex = modelID.lastIndex(of: "/") {
            return String(modelID[modelID.index(after: slashIndex)...])
        }
        return modelID
    }
}

// MARK: - Model Picker Sheet (simple list for selecting a model)

private struct ModelPickerSheet: View {
    @Binding var selectedModelID: String?
    @Bindable var modelManager: ModelManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if !modelManager.favoriteModels.isEmpty {
                Section("Favorites") {
                    ForEach(modelManager.favoriteModels, id: \.id) { model in
                        modelRow(model)
                    }
                }
            }

            Section("All Models") {
                ForEach(Array(modelManager.filteredModels.prefix(50)), id: \.id) { model in
                    modelRow(model)
                }
            }
        }
        .navigationTitle("Choose Model")
        .searchable(text: $modelManager.searchText, prompt: "Search models...")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func modelRow(_ model: CachedModel) -> some View {
        Button {
            selectedModelID = model.id
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.body)
                    Text(model.providerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.id == selectedModelID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
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
