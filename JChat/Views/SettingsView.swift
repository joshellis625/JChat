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

                    HStack(alignment: .center, spacing: 10) {
                        if keyValidationMessage != nil || lastRequestInfo != nil {
                            KeyValidationStatusView(
                                message: keyValidationMessage,
                                details: keyValidationDetails,
                                credits: creditsBalance,
                                requestInfo: lastRequestInfo
                            )
                            .transition(
                                .opacity.combined(with: .move(edge: .leading))
                            )
                        }

                        Spacer()

                        if isValidatingKey {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button("Validate") {
                                Task { await validateKey() }
                            }
                            .buttonStyle(.glass)
                            .disabled(apiKey.isEmpty)
                        }
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your API key is stored securely in the system keychain and never leaves your device.")
                        .appFont(.caption2)
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
            .animation(.easeOut(duration: 0.2), value: keyValidationMessage)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
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

// MARK: - Validation status card

private struct KeyValidationStatusView: View {
    let message: String?
    let details: String?
    let credits: String?
    let requestInfo: RequestInfo?

    private var isValid: Bool {
        message?.contains("Valid") == true
    }

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isValid ? Color.green : Color.red)

            VStack(alignment: .leading, spacing: 4) {
                // Primary status line
                HStack(spacing: 8) {
                    Text(isValid ? "Valid API Key" : (message ?? "Validation Failed"))
                        .appFont(.subheadline, weight: .semibold)
                        .foregroundStyle(isValid ? Color.green : Color.red)

                    // Inline chips for model count and credits on success
                    if isValid {
                        if let details, details.contains("Models available:") {
                            let count = details.replacingOccurrences(of: "Models available: ", with: "")
                            StatChip(label: "\(count) models", color: .secondary)
                        }
                        if let credits {
                            StatChip(label: credits, color: .green)
                                .transition(.opacity)
                                .animation(.easeOut(duration: 0.15), value: credits)
                        }
                    }
                }

                // Failure detail: show error message and debug info
                if !isValid {
                    if let details, !details.isEmpty {
                        Text(details)
                            .appFont(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let info = requestInfo {
                        HStack(spacing: 4) {
                            Text(info.endpoint)
                                .appFont(.caption2, design: .monospaced)
                                .foregroundStyle(.tertiary)
                            Text("·")
                                .appFont(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(info.statusText)
                                .appFont(.caption2, design: .monospaced)
                                .foregroundStyle(info.statusCode == 200 ? .green : .red)
                        }
                        if let errorBody = info.errorBody, !errorBody.isEmpty {
                            Text(errorBody)
                                .appFont(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct StatChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .appFont(.caption, weight: .semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview (traits: PreviewTrait(.fixedLayout(width: 450, height: 500))) {
    SettingsView()
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
