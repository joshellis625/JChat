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
    @State private var conversationStore = ConversationStore()
    @State private var modelManager = ModelManager()
    @State private var showingSettings = false
    @State private var showingModelManager = false
    @State private var textSizeMultiplier: Double = 1.0
    @State private var hasAPIKey = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]

    var body: some View {
        NavigationSplitView {
            V2SidebarView(store: conversationStore)
                .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 360)
        } detail: {
            if needsSetup {
                setupRequiredView
                    .padding(24)
            } else if let selectedChat = conversationStore.selectedChat {
                V2ConversationPane(
                    store: conversationStore,
                    modelManager: modelManager,
                    chat: selectedChat
                )
            } else {
                V2EmptyStateView()
            }
        }
        .background(V2CanvasBackground())
        .environment(\.textSizeMultiplier, textSizeMultiplier)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    conversationStore.createNewChat(in: modelContext)
                } label: {
                    Label("New Chat", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
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
        .task {
            loadTextSize()
            loadAPIKeyStatus()
            await modelManager.refreshIfStale(context: modelContext)
            if conversationStore.selectedChat == nil {
                conversationStore.selectedChat = chats.first
            }
        }
        .onChange(of: chats.count) { _, _ in
            if conversationStore.selectedChat == nil {
                conversationStore.selectedChat = chats.first
            }
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
        !hasAPIKey
    }

    private var setupRequiredView: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Complete Setup")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Add your OpenRouter key to begin.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)

            VStack(alignment: .leading, spacing: 12) {
                setupItemRow(
                    title: "OpenRouter API Key",
                    isComplete: hasAPIKey,
                    detail: "Add your API key in Settings."
                )
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(.top, 6)

            HStack(spacing: 10) {
                Button("Open Settings") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)

                Button("Open Model Manager") {
                    showingModelManager = true
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .surfaceCard(cornerRadius: 22, borderOpacity: 0.16, fillOpacity: 0.06)
    }

    private func setupItemRow(title: String, isComplete: Bool, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isComplete ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct V2EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Select a chat or start a new one")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 900, minHeight: 700)
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
