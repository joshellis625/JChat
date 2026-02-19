//
//  SettingsView.swift
//  JChat
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var isValidatingKey = false
    @State private var keyValidationMessage: String?
    @State private var creditsBalance: String?

    // Defaults
    @Query(sort: \Character.createdAt, order: .reverse) private var characters: [Character]
    @Query(filter: #Predicate<CachedModel> { $0.isFavorite == true },
           sort: \CachedModel.name) private var favoriteModels: [CachedModel]

    @State private var selectedCharacterID: UUID?
    @State private var selectedModelID: String?

    private let service = OpenRouterService.shared

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - API Configuration

                Section {
                    SecureField("OpenRouter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        // TODO: - Can we change this to the iCloud Keychain? Or does that require paid Apple Dev status?
                        Text("Stored securely in your local keychain.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if isValidatingKey {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button("Validate") {
                                Task { await validateKey() }
                            }
                            .font(.caption)
                            .disabled(apiKey.isEmpty)
                        }
                    }

                    // TODO: - Make keyValidationMessage and creditsBalance look prettier and have a cleaner presentation, be creative.
                    if let message = keyValidationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("Valid") ? .green : .red)
                    }

                    if let credits = creditsBalance {
                        Text("Credits: \(credits)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("API Configuration")
                }

                // MARK: - Defaults

                Section {
                    // Default Character picker
                    Picker("Default Character", selection: $selectedCharacterID) {
                        Text("None").tag(UUID?.none)
                        ForEach(characters) { character in
                            Text(character.name).tag(Optional(character.id))
                        }
                    }

                    // Default Model picker (from favorites)
                    Picker("Default Model", selection: $selectedModelID) {
                        Text("None").tag(String?.none)
                        ForEach(favoriteModels, id: \.id) { model in
                            Text(model.uiDisplayName).tag(Optional(model.id))
                        }
                    }

                    if favoriteModels.isEmpty {
                        Text("Favorite some models in the Model Manager to see them here.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("Applied when creating new chats without an explicit character or model.")
                        .font(.caption2)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 450, minHeight: 350)
        .task {
            loadSettings()
        }
    }

    // MARK: - Load / Save

    private func loadSettings() {
        apiKey = loadAPIKeyFromKeychain()
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        selectedCharacterID = settings.defaultCharacterID
        selectedModelID = settings.defaultModelID
    }

    private func loadAPIKeyFromKeychain() -> String {
        do {
            return try KeychainManager.shared.loadAPIKey()
        } catch {
            return ""
        }
    }

    private func validateKey() async {
        isValidatingKey = true
        keyValidationMessage = nil
        creditsBalance = nil

        // Step 1: Validate the key via /api/v1/key
        do {
            let keyInfo = try await service.validateAPIKey(apiKey: apiKey)
            let usage = keyInfo.data.usage ?? 0
            let isFreeTier = keyInfo.data.is_free_tier ?? false

            if let limit = keyInfo.data.limit, let remaining = keyInfo.data.limit_remaining {
                creditsBalance = String(format: "$%.4f remaining of $%.2f limit", remaining, limit)
            } else if isFreeTier {
                creditsBalance = "Free tier (usage: $\(String(format: "%.4f", usage)))"
            } else {
                creditsBalance = String(format: "Usage: $%.4f", usage)
            }

            keyValidationMessage = "Valid API key"
        } catch let error as JChatError {
            keyValidationMessage = error.errorDescription
        } catch {
            keyValidationMessage = "Validation failed: \(error.localizedDescription)"
        }

        // Step 2: Try to fetch credits (requires management key — may fail, that's OK)
        if keyValidationMessage == "Valid API key" {
            do {
                let credits = try await service.fetchCredits(apiKey: apiKey)
                let total = credits.data.total_credits ?? 0
                let used = credits.data.total_usage ?? 0
                creditsBalance = String(format: "$%.4f remaining", total - used)
            } catch {
                // Credits endpoint requires management key — not an error for regular keys
            }
        }

        isValidatingKey = false
    }

    private func saveSettings() {
        // Save API key
        do {
            if apiKey.isEmpty {
                try KeychainManager.shared.deleteAPIKey()
            } else {
                try KeychainManager.shared.saveAPIKey(apiKey)
            }
        } catch {
            // Silently handle keychain errors for now
        }

        // Save defaults
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        settings.defaultCharacterID = selectedCharacterID
        settings.defaultModelID = selectedModelID
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
