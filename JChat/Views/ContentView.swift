//
//  ContentView.swift
//  JChat
//

import SwiftUI
import SwiftData

// MARK: - Text Size Environment Key

private struct TextSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var textSizeMultiplier: Double {
        get { self[TextSizeMultiplierKey.self] }
        set { self[TextSizeMultiplierKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @State private var modelManager = ModelManager()
    @State private var showingSettings = false
    @State private var showingModelManager = false
    @State private var showingCharacters = false
    @State private var textSizeMultiplier: Double = 1.0
    @State private var hasAPIKey = false
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]

    var body: some View {
        NavigationSplitView {
            ChatListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            if needsSetup {
                setupRequiredView
            } else {
                ConversationView(viewModel: viewModel, modelManager: modelManager)
            }
        }
        .environment(\.textSizeMultiplier, textSizeMultiplier)
        .toolbar {
            ToolbarItem {
                Button {
                    showingCharacters = true
                } label: {
                    Label("Characters", systemImage: "person.2")
                }
            }
            ToolbarItem {
                Button {
                    showingModelManager = true
                } label: {
                    Label("Model Manager", systemImage: "server.rack")
                }
            }
            ToolbarItem {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: showingSettings) { _, isShowing in
            if !isShowing {
                loadTextSize()
                loadAPIKeyStatus()
            }
        }
        .sheet(isPresented: $showingModelManager) {
            ModelManagerView(modelManager: modelManager)
        }
        .sheet(isPresented: $showingCharacters) {
            CharacterListView(modelManager: modelManager)
        }
        .task {
            loadTextSize()
            loadAPIKeyStatus()
            await modelManager.refreshIfStale(context: modelContext)
        }
    }

    private func loadTextSize() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        textSizeMultiplier = settings.textSizeMultiplier
    }

    private func loadAPIKeyStatus() {
        do {
            let key = try KeychainManager.shared.loadAPIKey().trimmingCharacters(in: .whitespacesAndNewlines)
            hasAPIKey = !key.isEmpty
        } catch {
            hasAPIKey = false
        }
    }

    private var needsSetup: Bool {
        !hasAPIKey || needsDefaultModel
    }

    private var needsDefaultModel: Bool {
        guard let defaultModelID = appSettings.first?.defaultModelID else { return true }
        return defaultModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var setupRequiredView: some View {
        ContentUnavailableView {
            Label("Complete Setup to Start Chatting", systemImage: "checklist")
        } description: {
            VStack(alignment: .leading, spacing: 10) {
                setupItemRow(
                    title: "OpenRouter API Key",
                    isComplete: hasAPIKey,
                    detail: "Add your API key in Settings."
                )
                // TODO - Place this step AFTER prompting for model selections in Model Manager.
                setupItemRow(
                    title: "Global Default Model",
                    isComplete: !needsDefaultModel,
                    detail: "Choose a default model in Settings."
                )
            }
        } actions: {
            HStack(spacing: 10) {
                Button("Open Settings") {
                    showingSettings = true
                }
                Button("Open Model Manager") {
                    showingModelManager = true
                }
            }
        }
    }

    private func setupItemRow(title: String, isComplete: Bool, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isComplete ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 900, minHeight: 700)
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
