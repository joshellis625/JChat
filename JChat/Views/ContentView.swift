//
//  ContentView.swift
//  JChat
//

import SwiftData
import SwiftUI

// MARK: - Text Size Environment Key (point size)

private enum TextSizeConfig {
    static let minimum: CGFloat = 10
    static let maximum: CGFloat = 20
    static let step: CGFloat = 1
    static let defaultSize: CGFloat = 15
}

private struct TextBaseSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = TextSizeConfig.defaultSize
}

extension EnvironmentValues {
    var textBaseSize: CGFloat {
        get { self[TextBaseSizeKey.self] }
        set { self[TextBaseSizeKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var conversationStore = ConversationStore()
    @State private var modelManager = ModelManager()
    @State private var textBaseSize: CGFloat = TextSizeConfig.defaultSize
    @State private var hasAPIKey = false

    // Setup screen only — sidebar owns its own copies for normal use
    @State private var showingSettingsFromSetup = false
    @State private var showingModelManagerFromSetup = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]

    var body: some View {
        NavigationSplitView {
            V2SidebarView(store: conversationStore, modelManager: modelManager)
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
        .environment(\.textBaseSize, textBaseSize)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    conversationStore.createNewChat(in: modelContext)
                } label: {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSettingsFromSetup) {
            SettingsView()
        }
        .onChange(of: showingSettingsFromSetup) { _, isShowing in
            if !isShowing {
                loadTextSize()
                loadAPIKeyStatus()
            }
        }
        .sheet(isPresented: $showingModelManagerFromSetup) {
            ModelManagerView(modelManager: modelManager)
        }
        .task {
            loadTextSize()
            loadAPIKeyStatus()
            await modelManager.refreshIfStale(context: modelContext)
            await conversationStore.generatePendingAutoTitles(in: modelContext)
            if conversationStore.selectedChat == nil {
                conversationStore.selectedChat = chats.first
            }
        }
        .onChange(of: chats.count) { _, _ in
            if conversationStore.selectedChat == nil {
                conversationStore.selectedChat = chats.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textSizeIncrease)) { _ in
            adjustTextSize(by: TextSizeConfig.step)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textSizeDecrease)) { _ in
            adjustTextSize(by: -TextSizeConfig.step)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textSizeReset)) { _ in
            resetTextSize()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.newChat)) { _ in
            conversationStore.createNewChat(in: modelContext)
        }
    }

    private func loadTextSize() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        textBaseSize = clampedTextSize(settings.textPointSize)
    }

    private func adjustTextSize(by delta: CGFloat) {
        let next = clampedTextSize(Double(textBaseSize + delta))
        guard next != textBaseSize else { return }
        textBaseSize = next
        saveTextSize()
    }

    private func resetTextSize() {
        guard textBaseSize != TextSizeConfig.defaultSize else { return }
        textBaseSize = TextSizeConfig.defaultSize
        saveTextSize()
    }

    private func saveTextSize() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        settings.textPointSize = Double(textBaseSize)
        try? modelContext.save()
    }

    private func clampedTextSize(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, Double(TextSizeConfig.minimum)), Double(TextSizeConfig.maximum)))
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
                    showingSettingsFromSetup = true
                }
                .buttonStyle(.borderedProminent)

                Button("Open Model Manager") {
                    showingModelManagerFromSetup = true
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
