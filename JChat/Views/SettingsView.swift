//
//  SettingsView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var settings: APISettings?
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 4096
    @State private var availableModels: [String] = []
    
    private let service = OpenRouterService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenRouter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    Text("Your API key is stored securely in the local keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("API Configuration")
                }
                
                Section {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                } header: {
                    Text("Default Model")
                }
                
                Section {
                    Slider(value: $temperature, in: 0...2, step: 0.1) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("2")
                    }
                    Text("Current: \(temperature, format: .number.precision(.fractionLength(2)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 256...8192, step: 256)
                } header: {
                    Text("Default Parameters")
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
            await loadAvailableModels()
        }
    }
    
    private func loadSettings() {
        settings = APISettings.fetchOrCreate(in: modelContext)
        apiKey = loadAPIKeyFromKeychain()
        selectedModel = settings?.selectedModel ?? "anthropic/claude-3.5-sonnet"
        temperature = settings?.temperature ?? 0.7
        maxTokens = settings?.maxTokens ?? 4096
    }
    
    private func loadAPIKeyFromKeychain() -> String {
        do {
            return try KeychainManager.shared.loadAPIKey()
        } catch KeychainError.itemNotFound {
            return ""
        } catch {
            print("Error loading API key from Keychain: \(error)")
            return ""
        }
    }
    
    private func loadAvailableModels() async {
        availableModels = await service.availableModels()
    }
    
    private func saveSettings() {
        let s = APISettings.fetchOrCreate(in: modelContext)
        do {
            if apiKey.isEmpty {
                try KeychainManager.shared.deleteAPIKey()
            } else {
                try KeychainManager.shared.saveAPIKey(apiKey)
            }
        } catch {
            print("Error saving API key to Keychain: \(error)")
        }
        s.selectedModel = selectedModel
        s.temperature = temperature
        s.maxTokens = maxTokens
        try? modelContext.save()
    }
}
