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
    @State private var keyValidationDetails: String?
    @State private var lastRequestInfo: RequestInfo?
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
                        Text("Stored securely in your keychain.")
                        Spacer()
                        if isValidatingKey {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Button("Validate") {
                                Task { await validateKey() }
                            }
                            .appFont(.caption)
                            .disabled(apiKey.isEmpty)
                        }
                    }

                    // TODO: - Make keyValidationMessage and creditsBalance look prettier and have a cleaner presentation, be creative.
                    if let message = keyValidationMessage {
                        Text(message)
                            .bold()
                            .foregroundStyle(message.contains("Valid") ? .green : .red)
                    }

                    if let details = keyValidationDetails {
                        Text(details)
                    }

                    if let credits = creditsBalance {
                        Text("Credits: \(credits)")
                            .appFont(.footnote)
                            .bold()
                            .foregroundStyle(.green)
                    }

                    if let requestInfo = lastRequestInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("Endpoint: ")
                                    .appFont(.footnote)
                                    .bold()
                                Text(requestInfo.endpoint)
                                    .appFont(.footnote, design: .monospaced)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("Status: ")
                                    .appFont(.footnote)
                                    .bold()
                                if case requestInfo.statusCode = 200 {
                                    Text(requestInfo.statusText)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        if let errorBody = requestInfo.errorBody, !errorBody.isEmpty {
                            Text("Error: \(errorBody)")
                                .appFont(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
            header: {
                    Text("API Configuration")
                        .bold()
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
                            .appFont(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("Applied when creating new chats without an explicit character or model.")
                        .appFont(.caption2)
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

    private func normalizeKey(_ key: String) -> String {
        var normalized = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.lowercased().hasPrefix("bearer ") {
            normalized = String(normalized.dropFirst(7))
        }
        if normalized.hasPrefix("\"") && normalized.hasSuffix("\"") && normalized.count >= 2 {
            normalized = String(normalized.dropFirst().dropLast())
        }
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateKey() async {
        isValidatingKey = true
        keyValidationMessage = nil
        keyValidationDetails = nil
        lastRequestInfo = nil
        creditsBalance = nil

        let normalizedKey = normalizeKey(apiKey)
        apiKey = normalizedKey

        guard !normalizedKey.isEmpty else {
            keyValidationMessage = JChatError.apiKeyNotConfigured.errorDescription
            isValidatingKey = false
            return
        }

        // Step 1: Validate the key via /api/v1/models
        let diagnostics = await service.validateAPIKeyWithDiagnostics(apiKey: normalizedKey)
        lastRequestInfo = RequestInfo(
            endpoint: diagnostics.endpoint,
            statusCode: diagnostics.statusCode,
            errorBody: diagnostics.errorBody
        )

        if diagnostics.isValid {
            keyValidationMessage = "Valid API key"
            if let modelsCount = diagnostics.modelsCount {
                keyValidationDetails = "Models available: \(modelsCount)"
            }
        } else {
            if diagnostics.statusCode > 0 {
                keyValidationMessage = "Validation failed (status \(diagnostics.statusCode))"
                if let errorBody = diagnostics.errorBody, !errorBody.isEmpty {
                    keyValidationDetails = errorBody
                }
            } else {
                keyValidationMessage = "Validation failed"
                if let errorBody = diagnostics.errorBody, !errorBody.isEmpty {
                    keyValidationDetails = errorBody
                }
            }
        }

        // Step 2: Try to fetch credits (requires management key — may fail, that's OK)
        if keyValidationMessage == "Valid API key" {
            do {
                let credits = try await service.fetchCredits(apiKey: normalizedKey)
                let total = credits.data.total_credits ?? 0
                let used = credits.data.total_usage ?? 0
                creditsBalance = String(format: "$%.2f", total - used)
            } catch {
                // Credits endpoint requires management key — not an error for regular keys
            }
        }

        isValidatingKey = false
    }

    private func saveSettings() {
        // Save API key
        let normalizedKey = normalizeKey(apiKey)
        apiKey = normalizedKey
        do {
            if normalizedKey.isEmpty {
                try KeychainManager.shared.deleteAPIKey()
            } else {
                try KeychainManager.shared.saveAPIKey(normalizedKey)
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

private struct RequestInfo: Sendable {
    let endpoint: String
    let statusCode: Int
    let errorBody: String?

    var statusText: String {
        statusCode > 0 ? "\(statusCode)" : "No response"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
