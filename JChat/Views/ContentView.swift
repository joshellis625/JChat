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
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]

    var body: some View {
        NavigationSplitView {
            ChatListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            if needsDefaultModel {
                ContentUnavailableView {
                    Label("Set a Global Default Model", systemImage: "gearshape")
                } description: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open Settings and choose a Default Model to start chatting.")
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("A Global Default Model is required to use the app.")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.red)
                    }
                } actions: {
                    Button("Open Settings") { showingSettings = true }
                }
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
            }
        }
        .onChange(of: needsDefaultModel) { _, needsDefault in
            if needsDefault {
                showingSettings = true
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
            if needsDefaultModel {
                showingSettings = true
            }
            await modelManager.refreshIfStale(context: modelContext)
        }
    }

    private func loadTextSize() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        textSizeMultiplier = settings.textSizeMultiplier
    }

    private var needsDefaultModel: Bool {
        guard let defaultModelID = appSettings.first?.defaultModelID else { return true }
        return defaultModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 900, minHeight: 700)
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
