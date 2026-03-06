//
//  ContentView.swift
//  JChat
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var conversationStore: ConversationStore
    @State private var modelManager = ModelManager()

    // previewForceSetup: pins needsSetup=true in previews without touching the real keychain
    private let previewForceSetup: Bool

    init(previewStore: ConversationStore? = nil, previewForceSetup: Bool = false) {
        _conversationStore = State(initialValue: previewStore ?? ConversationStore())
        self.previewForceSetup = previewForceSetup
    }
    @State private var textBaseSize: CGFloat = TextSizeConfig.defaultSize
    @State private var hasAPIKey = false

    // Setup screen only — sidebar owns its own copies for normal use
    @State private var showingSettingsFromSetup = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]

    var body: some View {
        NavigationSplitView {
            SidebarView(store: conversationStore, modelManager: modelManager)
                .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 360)
        } detail: {
            if needsSetup {
                ZStack {
                    setupRequiredView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let selectedChat = conversationStore.selectedChat {
                ConversationPane(
                    store: conversationStore,
                    modelManager: modelManager,
                    chat: selectedChat
                )
            } else {
                EmptyStateView()
            }
        }
        .background(CanvasBackground())
        .environment(\.textBaseSize, textBaseSize)
        .environment(\.font, .system(size: TextSizeConfig.size(for: .body, base: textBaseSize)))
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
        .task {
            loadTextSize()
            loadAPIKeyStatus()
            await modelManager.refreshIfStale(context: modelContext)
            await conversationStore.generatePendingAutoTitles(in: modelContext)
            selectFirstChatIfNeeded()
        }
        .onChange(of: chats.count) { _, _ in
            selectFirstChatIfNeeded()
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

    private func selectFirstChatIfNeeded() {
        if conversationStore.selectedChat == nil {
            conversationStore.selectedChat = chats.first
        }
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
        previewForceSetup || !hasAPIKey
    }

    private var setupRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: TextSizeConfig.scaled(32, base: textBaseSize), weight: .medium))
                .foregroundStyle(.secondary)

            Text("Add your OpenRouter API key to get started.")
                .font(.system(size: TextSizeConfig.scaled(15, base: textBaseSize), weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            Button("Open Settings") {
                showingSettingsFromSetup = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

}

private struct EmptyStateView: View {
    @Environment(\.textBaseSize) private var textBaseSize

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: TextSizeConfig.scaled(40, base: textBaseSize), weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Select a chat or start a new one")
                .font(.system(size: TextSizeConfig.scaled(24, base: textBaseSize), weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

@MainActor
private func makePreviewContainer() throws -> (ModelContainer, Chat) {
    let schema = Schema([Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let ctx = container.mainContext

    // Seed a few favorite models so the inline model picker has something to show
    let models: [(String, String)] = [
        ("anthropic/claude-sonnet-4-5", "Claude Sonnet 4.5"),
        ("google/gemini-2.0-flash-001", "Gemini 2.0 Flash"),
        ("openai/gpt-4o", "GPT-4o"),
    ]
    for (idx, (modelID, name)) in models.enumerated() {
        let m = CachedModel(id: modelID, name: name, contextLength: 200_000, isFavorite: true, sortOrder: idx)
        ctx.insert(m)
    }

    // Primary seeded chat — "What is Liquid Glass?"
    let chat = Chat(title: "What is Liquid Glass?")
    chat.selectedModelID = "anthropic/claude-sonnet-4-5"
    chat.totalPromptTokens = 1_242
    chat.totalCompletionTokens = 387
    chat.totalCost = 0.00183
    ctx.insert(chat)

    let msgs: [(MessageRole, String, Int, Int)] = [
        (.user,      "What is Liquid Glass in SwiftUI?", 18, 0),
        (.assistant, "Liquid Glass is a new dynamic material introduced in macOS/iOS 26. It provides an adaptive translucent surface that automatically responds to what's behind it — adjusting blur, reflection, and tint based on the underlying content and system appearance.", 18, 68),
        (.user,      "How do I use it in my own views?", 12, 0),
        (.assistant, "Use `.glassEffect(in: shape)` to apply the material to any view:\n\n```swift\nText(\"Hello\")\n    .padding()\n    .glassEffect(in: .rect(cornerRadius: 12))\n```\n\nFor interactive controls, `.buttonStyle(.glass)` gives you a first-class Liquid Glass button that handles hover, press, and dark/tinted appearances automatically.", 12, 92),
    ]
    var t = Date(timeIntervalSinceNow: -300)
    for (role, content, prompt, completion) in msgs {
        let msg = Message(role: role, content: content, promptTokens: prompt, completionTokens: completion, cost: 0.0, modelID: "anthropic/claude-sonnet-4-5")
        msg.timestamp = t
        chat.messages.append(msg)
        t += 30
    }

    // Second chat for sidebar population
    let chat2 = Chat(title: "SwiftData relationships")
    chat2.totalPromptTokens = 540
    ctx.insert(chat2)

    try ctx.save()
    return (container, chat)
}

#Preview("Empty / Setup") {
    ContentView(previewForceSetup: true)
        .frame(minWidth: 900, minHeight: 700)
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
#Preview("Active Chat") {
    // Seed data and pre-select the primary chat so ConversationPane renders immediately.
    // Falls back to an empty in-memory container if seeding fails, so the preview
    // still renders rather than crashing the canvas.
    let schema = Schema([Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self])
    let fallback = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    do {
        let (container, chat) = try makePreviewContainer()
        let store = ConversationStore()
        store.selectedChat = chat
        return ContentView(previewStore: store)
            .frame(minWidth: 900, minHeight: 700)
            .modelContainer(container)
    } catch {
        return ContentView()
            .frame(minWidth: 900, minHeight: 700)
            .modelContainer(fallback)
    }
}

