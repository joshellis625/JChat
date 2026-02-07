//
//  SettingsView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var isValidatingKey = false
    @State private var keyValidationMessage: String?
    @State private var creditsBalance: String?

    private let service = OpenRouterService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenRouter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Your API key is stored securely in the local keychain.")
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
        .frame(minWidth: 400, minHeight: 300)
        .task {
            loadSettings()
        }
    }

    private func loadSettings() {
        apiKey = loadAPIKeyFromKeychain()
    }

    private func loadAPIKeyFromKeychain() -> String {
        do {
            return try KeychainManager.shared.loadAPIKey()
        } catch KeychainError.itemNotFound {
            return ""
        } catch {
            return ""
        }
    }

    private func validateKey() async {
        isValidatingKey = true
        keyValidationMessage = nil
        creditsBalance = nil
        do {
            let _ = try await service.validateAPIKey(apiKey: apiKey)
            let credits = try await service.fetchCredits(apiKey: apiKey)
            let total = credits.data.total_credits ?? 0
            let used = credits.data.total_usage ?? 0
            creditsBalance = String(format: "$%.4f remaining", total - used)
            keyValidationMessage = "Valid API key"
        } catch {
            keyValidationMessage = "Invalid API key"
        }
        isValidatingKey = false
    }

    private func saveSettings() {
        do {
            if apiKey.isEmpty {
                try KeychainManager.shared.deleteAPIKey()
            } else {
                try KeychainManager.shared.saveAPIKey(apiKey)
            }
        } catch {
            // Silently handle keychain errors for now
        }
        let _ = AppSettings.fetchOrCreate(in: modelContext)
        try? modelContext.save()
    }
}
