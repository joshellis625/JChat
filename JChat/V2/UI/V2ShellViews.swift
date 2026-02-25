//
//  V2ShellViews.swift
//  JChat
//

import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

struct V2SidebarView: View {
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    @Query(sort: \CachedModel.name) private var cachedModels: [CachedModel]
    @Bindable var store: ConversationStore
    @Bindable var modelManager: ModelManager
    @Environment(\.modelContext) private var modelContext
    @State private var chatToDelete: Chat?
    @State private var showingSettings = false
    @State private var showingModelManager = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 6) {
                Text("JChat")
                    .appFont(size: 24, weight: .bold, design: .rounded)
                    .foregroundStyle(.primary)
                Text("\(chats.count)")
                    .appFont(size: 12, weight: .semibold, design: .rounded)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            // Chat list
            ScrollViewReader { proxy in
                List {
                    ForEach(chats) { chat in
                        V2SidebarRow(
                            chat: chat,
                            isSelected: store.selectedChat?.id == chat.id,
                            isGeneratingTitle: store.isGeneratingTitle(for: chat.id),
                            didFailGeneratingTitle: store.didFailGeneratingTitle(for: chat.id),
                            selectedModelName: chat.selectedModelID.map {
                                ModelNaming.displayName(forModelID: $0, namesByID: modelNamesByID)
                            }
                        )
                        .id(chat.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.selectedChat = chat
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                chatToDelete = chat
                            }
                        }
                    }
                }
                .onChange(of: store.selectedChat?.id) { _, _ in
                    scrollToSelectedChat(using: proxy)
                }
                .onAppear {
                    scrollToSelectedChat(using: proxy)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            // Bottom navigation
            Divider()
                .padding(.horizontal, 4)
                .padding(.top, 4)

            Button {
                showingModelManager = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "server.rack")
                        .appFont(size: 13, weight: .medium)
                        .frame(width: 18)
                    Text("Model Manager")
                        .appFont(size: 13, weight: .medium, design: .rounded)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                showingSettings = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gear")
                        .appFont(size: 13, weight: .medium)
                        .frame(width: 18)
                    Text("Settings")
                        .appFont(size: 13, weight: .medium, design: .rounded)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .alert("Delete Chat", isPresented: Binding(
            get: { chatToDelete != nil },
            set: { if !$0 { chatToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                chatToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    store.deleteChat(chat, in: modelContext)
                    chatToDelete = nil
                }
            }
        } message: {
            Text("Delete this chat and all of its messages?")
        }
        .onAppear {
            if store.selectedChat == nil {
                store.selectedChat = chats.first
            }
        }
        .onChange(of: chats.count) { _, _ in
            if store.selectedChat == nil {
                store.selectedChat = chats.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.deleteSelectedChat)) { _ in
            guard chatToDelete == nil else { return }
            chatToDelete = store.selectedChat
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.openSettings)) { _ in
            showingSettings = true
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingModelManager) {
            ModelManagerView(modelManager: modelManager)
        }
    }

    private var modelNamesByID: [String: String] {
        ModelNaming.namesByID(from: cachedModels)
    }

    private func scrollToSelectedChat(using proxy: ScrollViewProxy) {
        guard let selectedID = store.selectedChat?.id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(selectedID, anchor: .top)
        }
    }
}

private struct V2SidebarRow: View {
    let chat: Chat
    let isSelected: Bool
    let isGeneratingTitle: Bool
    let didFailGeneratingTitle: Bool
    let selectedModelName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isGeneratingTitle {
                AutoTitleLoadingTitleView(fontSize: 15, width: 170)
            } else {
                HStack(spacing: 6) {
                    Text(displayTitle)
                        .appFont(size: 15, weight: .semibold, design: .rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if didFailGeneratingTitle && chat.title == "New Chat" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .appFont(size: 10, weight: .semibold)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Text(previewText)
                .appFont(size: 12, weight: .medium, design: .rounded)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                if let selectedModelName {
                    Text(selectedModelName)
                        .lineLimit(1)
                } else {
                    Text("No model")
                        .lineLimit(1)
                }
                Text("•")
                Text(chatTimestampText)
            }
            .appFont(size: 11, weight: .semibold, design: .rounded)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? Color.primary.opacity(0.18) : Color.clear, lineWidth: 1)
        )
    }

    private var previewText: String {
        if let last = latestMessage?.content.trimmingCharacters(in: .whitespacesAndNewlines),
           !last.isEmpty {
            let singleLine = last.replacingOccurrences(of: "\n", with: " ")
            return String(singleLine.prefix(88))
        }
        return "New conversation"
    }

    private var displayTitle: String {
        let trimmed = chat.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New Chat" : trimmed
    }

    private var chatTimestampText: String {
        let referenceDate = latestMessage?.timestamp ?? chat.createdAt
        let calendar = Calendar.current
        if calendar.isDateInToday(referenceDate) {
            return referenceDate.formatted(.dateTime.hour().minute())
        }
        if calendar.isDate(referenceDate, equalTo: Date(), toGranularity: .year) {
            return referenceDate.formatted(.dateTime.month(.abbreviated).day())
        }
        return referenceDate.formatted(.dateTime.year().month(.abbreviated).day())
    }

    private var latestMessage: Message? {
        chat.sortedMessages.last
    }
}

struct V2ConversationPane: View {
    @Bindable var store: ConversationStore
    @Bindable var modelManager: ModelManager
    let chat: Chat

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CachedModel.name) private var cachedModels: [CachedModel]
    @Environment(\.textBaseSize) private var textBaseSize
    @State private var rows: [MessageRowViewData] = []
    @State private var totalMessageCount = 0
    @State private var lastStreamAutoScrollAt = ContinuousClock.now
    @State private var didInitialBottomScroll = false
    @State private var errorDismissTask: Task<Void, Never>?
    @State private var showParameterInspector = false
    private let bottomAnchorID = "v2-conversation-bottom-anchor"
    private let streamAutoScrollInterval: Duration = .milliseconds(140)
    private let maxVisibleMessages = 60
    private let errorAutoDismissDelay: Duration = .seconds(6)

    var body: some View {
        VStack(spacing: 8) {
            headerCard

            ScrollViewReader { proxy in
                let liveAssistantID = store.isStreaming ? rows.last(where: { $0.role == .assistant })?.id : nil

                List {
                    if totalMessageCount > rows.count {
                        Text("Showing most recent \(rows.count) messages for stability")
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 4, trailing: 12))
                            .listRowBackground(Color.clear)
                    }

                    ForEach(rows) { row in
                        messageRow(
                            for: row,
                            liveAssistantID: liveAssistantID,
                            liveStreamingContent: liveAssistantID == row.id ? store.streamingContent : nil
                        )
                        .id(row.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                        .listRowBackground(Color.clear)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .transaction { transaction in
                    transaction.animation = nil
                }
                .onAppear {
                    refreshRows()
                    didInitialBottomScroll = false
                    DispatchQueue.main.async {
                        scrollToBottom(proxy: proxy, animated: false)
                        didInitialBottomScroll = true
                    }
                }
                .onChange(of: chat.id) { _, _ in
                    refreshRows()
                    didInitialBottomScroll = false
                    DispatchQueue.main.async {
                        scrollToBottom(proxy: proxy, animated: false)
                        didInitialBottomScroll = true
                    }
                }
                .onChange(of: store.isStreaming) { _, isStreaming in
                    refreshRows()
                    if isStreaming {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }
                .onChange(of: store.streamingContent) { _, newValue in
                    guard store.isStreaming, !newValue.isEmpty else { return }
                    if didInitialBottomScroll {
                        throttledStreamAutoScroll(proxy: proxy)
                    }
                }
            }

            if let error = store.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(error)
                            .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if let suggestion = store.errorSuggestion {
                            Text(suggestion)
                                .font(.system(size: TextSizeConfig.scaled(12, base: textBaseSize), weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        dismissErrorBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .appFont(size: 16, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .surfaceCard(cornerRadius: 12, borderOpacity: 0.14, fillOpacity: 0.06)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            V2Composer(
                isLoading: store.isLoading,
                isStreaming: store.isStreaming,
                onSend: { text in
                    Task {
                        await store.sendMessage(content: text, context: modelContext)
                        refreshRows()
                    }
                },
                onStop: {
                    store.stopStreaming()
                    refreshRows()
                }
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .inspector(isPresented: $showParameterInspector) {
            V2ParameterInspector(chat: chat)
                .inspectorColumnWidth(min: 300, ideal: 300, max: 300)
        }
        .onChange(of: store.errorMessage) { _, newError in
            errorDismissTask?.cancel()
            guard let newError else { return }
            errorDismissTask = Task {
                try? await Task.sleep(for: errorAutoDismissDelay)
                await MainActor.run {
                    guard store.errorMessage == newError else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.clearError()
                    }
                }
            }
        }
        .onDisappear {
            errorDismissTask?.cancel()
            errorDismissTask = nil
        }
        .animation(.easeOut(duration: 0.2), value: store.errorMessage != nil)
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if store.isGeneratingTitle(for: chat.id) {
                    AutoTitleLoadingTitleView(fontSize: TextSizeConfig.scaled(17, base: textBaseSize), width: 220)
                } else {
                    HStack(spacing: 8) {
                        Text(displayTitle)
                            .font(.system(size: TextSizeConfig.scaled(17, base: textBaseSize), weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if store.didFailGeneratingTitle(for: chat.id) && chat.title == "New Chat" {
                            Text("Title generation failed")
                                .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Text("\(chat.totalTokens) tokens • \(chat.totalCost, format: .currency(code: "USD"))")
                    .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            InlineModelPicker(
                selectedModelID: Binding(
                    get: { chat.selectedModelID },
                    set: { newValue in
                        chat.selectedModelID = newValue
                        try? modelContext.save()
                    }
                ),
                modelManager: modelManager
            )
            .layoutPriority(2)

            // Parameter inspector toggle — Liquid Glass circle, moves left with content as inspector opens
            Button {
                showParameterInspector.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .appFont(size: 13, weight: .medium)
                    .foregroundStyle(showParameterInspector ? Color.accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .overlay(alignment: .topTrailing) {
                        let count = chat.activeOverrideCount
                        if count > 0 {
                            Text("\(count)")
                                .appFont(size: 9, weight: .bold, design: .rounded)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 3.5)
                                .padding(.vertical, 1)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .glassEffect(in: .circle)
            .help("Chat Parameters")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(V2Palette.panelBorder, lineWidth: 1)
        )
    }

    private var displayTitle: String {
        let trimmed = chat.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New Chat" : trimmed
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
    }

    @MainActor
    private func refreshRows() {
        let sorted = chat.messages.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.timestamp < rhs.timestamp
        }

        let mapped = sorted.map(MessageRowViewData.init(message:))
        totalMessageCount = mapped.count
        if mapped.count > maxVisibleMessages {
            rows = Array(mapped.suffix(maxVisibleMessages))
        } else {
            rows = mapped
        }
    }

    private func throttledStreamAutoScroll(proxy: ScrollViewProxy) {
        let now = ContinuousClock.now
        guard now - lastStreamAutoScrollAt >= streamAutoScrollInterval else { return }
        lastStreamAutoScrollAt = now
        scrollToBottom(proxy: proxy, animated: false)
    }

    private func dismissErrorBanner() {
        errorDismissTask?.cancel()
        errorDismissTask = nil
        withAnimation(.easeOut(duration: 0.2)) {
            store.clearError()
        }
    }

    @ViewBuilder
    private func messageRow(
        for row: MessageRowViewData,
        liveAssistantID: UUID?,
        liveStreamingContent: String?
    ) -> some View {
        let isLast = row.id == rows.last?.id
        let isOrphaned = isLast && row.role == .user && !store.isLoading && !store.isStreaming

        V2MessageRow(
            row: row,
            displayedContent: liveStreamingContent ?? row.content,
            isLiveStreaming: liveAssistantID == row.id,
            resolvedModelName: row.modelID.map { ModelNaming.displayName(forModelID: $0, namesByID: modelNamesByID) },
            isOrphanedLastUserMessage: isOrphaned,
            onDelete: {
                store.deleteMessage(withID: row.id, in: modelContext)
                refreshRows()
            },
            onEdit: { newContent in
                store.updateMessageContent(messageID: row.id, newContent: newContent, in: modelContext)
                refreshRows()
            },
            onRegenerate: {
                Task {
                    if isOrphaned {
                        await store.resendLastUserMessage(in: modelContext)
                    } else {
                        await store.regenerateMessage(withID: row.id, in: modelContext)
                    }
                    refreshRows()
                }
            },
            onResend: {
                Task {
                    await store.resendLastUserMessage(in: modelContext)
                    refreshRows()
                }
            }
        )
    }

    private var modelNamesByID: [String: String] {
        ModelNaming.namesByID(from: cachedModels)
    }
}

private struct AutoTitleLoadingTitleView: View {
    let fontSize: CGFloat
    let width: CGFloat
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.primary.opacity(0.14))
            .frame(width: width, height: max(16, fontSize + 2))
            .overlay(alignment: .leading) {
                Text("Generating title...")
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
            .opacity(pulse ? 0.45 : 0.92)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct MessageActionButtonStyle: ButtonStyle {
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 1.0 : (isHovered ? 0.85 : 0.55))
    }
}

private struct MessageActionButton: View {
    let systemImage: String
    var tint: Color = .secondary
    var activeTint: Color?
    let action: () -> Void

    @State private var isHovered = false

    private var isActive: Bool { activeTint != nil }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isActive ? .white : tint)
                .frame(width: 30, height: 30)
                .background {
                    if let activeTint {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(activeTint)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(MessageActionButtonStyle(isHovered: isHovered))
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

private struct MessageInspectorSheet: View {
    let title: String
    let json: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(json, forType: .string)
                    copied = true
                    Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied" : "Copy")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(copied ? .green : .secondary)
                    .contentTransition(.interpolate)
                    .animation(.easeInOut(duration: 0.25), value: copied)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // JSON content
            ScrollView {
                Text(json)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(.regularMaterial)
    }
}

private struct V2MessageRow: View, Equatable {
    let row: MessageRowViewData
    let displayedContent: String
    let isLiveStreaming: Bool
    let resolvedModelName: String?
    let isOrphanedLastUserMessage: Bool
    var onDelete: () -> Void = {}
    var onEdit: (_ newContent: String) -> Void = { _ in }
    var onRegenerate: () -> Void = {}
    var onResend: () -> Void = {}

    @Environment(\.textBaseSize) private var textBaseSize

    // Action toolbar state
    @State private var copied = false
    @State private var isEditing = false
    @State private var editText = ""
    @State private var isCommitting = false
    @State private var deleteArmed = false
    @State private var deleteArmTask: Task<Void, Never>?
    @State private var showInspector = false
    @FocusState private var isEditFocused: Bool

    private var isUser: Bool { row.role == .user }
    private let renderCharacterLimit = 6000

    // Closures excluded from Equatable — they capture stable references
    static func == (lhs: V2MessageRow, rhs: V2MessageRow) -> Bool {
        lhs.row == rhs.row &&
            lhs.displayedContent == rhs.displayedContent &&
            lhs.isLiveStreaming == rhs.isLiveStreaming &&
            lhs.resolvedModelName == rhs.resolvedModelName &&
            lhs.isOrphanedLastUserMessage == rhs.isOrphanedLastUserMessage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 0)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 5) {
                if !isUser, let resolvedModelName {
                    Text(resolvedModelName)
                        .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Group {
                    if isEditing {
                        TextEditor(text: $editText)
                            .font(.system(size: TextSizeConfig.scaled(14, base: textBaseSize), weight: .regular, design: .default))
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .focused($isEditFocused)
                            .frame(minHeight: 60)
                            .onAppear { isEditFocused = true }
                    } else {
                        Text(renderedContent)
                            .font(.system(size: TextSizeConfig.scaled(14, base: textBaseSize), weight: .regular, design: .default))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.primary.opacity(isEditing ? 0.25 : (isUser ? 0.12 : 0.10)), lineWidth: isEditing ? 1.5 : 1)
                )
                .frame(maxWidth: 720, alignment: isUser ? .trailing : .leading)
                .opacity(isLiveStreaming ? 0.98 : 1.0)

                actionToolbar

                HStack(spacing: 8) {
                    Text(row.timestamp, style: .time)
                    if row.role == .assistant, row.completionTokens > 0 {
                        Text("\(row.completionTokens) tokens")
                    }
                    if row.cost > 0 {
                        Text(row.cost, format: .currency(code: "USD"))
                    }
                }
                .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }
            .frame(maxWidth: 720, alignment: isUser ? .trailing : .leading)
            .onChange(of: isEditFocused) { _, focused in
                if !focused && !isCommitting { isEditing = false }
            }
            .onKeyPress(.escape) {
                guard isEditing else { return .ignored }
                isEditing = false
                return .handled
            }
            .sheet(isPresented: $showInspector) {
                MessageInspectorSheet(
                    title: isUser ? "Request JSON" : "Response JSON",
                    json: isUser ? (row.rawRequestJSON ?? "No request data captured") : (row.rawResponseJSON ?? "No response data captured")
                )
            }

            if !isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }

    // MARK: - Action Toolbar

    @ViewBuilder
    private var actionToolbar: some View {
        HStack(spacing: 2) {
            // Copy
            MessageActionButton(
                systemImage: copied ? "checkmark" : "doc.on.doc",
                activeTint: copied ? .green : nil
            ) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(displayedContent, forType: .string)
                copied = true
                Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
            }

            // Edit — toggles between pencil (start editing) and checkmark (commit edit).
            // When committing, isCommitting prevents the focus-loss handler from
            // cancelling the edit before the save completes.
            MessageActionButton(
                systemImage: isEditing ? "checkmark.circle" : "pencil",
                activeTint: isEditing ? .green : nil
            ) {
                if isEditing {
                    isCommitting = true
                    let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        isCommitting = false
                        return
                    }
                    onEdit(trimmed)
                    isEditing = false
                    // Must reset on the next runloop cycle — if we reset synchronously,
                    // the focus-loss handler fires after us and sees isCommitting == false,
                    // defeating the guard.
                    DispatchQueue.main.async { isCommitting = false }
                } else {
                    editText = displayedContent
                    isEditing = true
                }
            }

            // Regenerate — assistant messages, or orphaned last user message
            if !isEditing, row.role == .assistant || isOrphanedLastUserMessage {
                MessageActionButton(systemImage: "arrow.2.circlepath") {
                    if isOrphanedLastUserMessage {
                        onResend()
                    } else {
                        onRegenerate()
                    }
                }
            }

            // Delete — two-tap safety pattern to prevent accidental deletion.
            // First tap arms (turns red), second tap within 3 seconds confirms.
            // Timer auto-disarms after 3 seconds if the user doesn't confirm.
            if !isEditing {
                MessageActionButton(
                    systemImage: "trash",
                    activeTint: deleteArmed ? .red : nil
                ) {
                    if deleteArmed {
                        deleteArmTask?.cancel()
                        deleteArmTask = nil
                        onDelete()
                    } else {
                        deleteArmTask?.cancel()
                        deleteArmed = true
                        deleteArmTask = Task {
                            try? await Task.sleep(for: .seconds(3))
                            deleteArmed = false
                            deleteArmTask = nil
                        }
                    }
                }
            }

            // JSON Inspector
            MessageActionButton(systemImage: "curlybraces") {
                showInspector = true
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var bubbleBackground: some ShapeStyle {
        if isUser {
            return AnyShapeStyle(V2Palette.userBubble)
        }
        return AnyShapeStyle(V2Palette.assistantBubble)
    }

    private var renderedContent: String {
        guard displayedContent.count > renderCharacterLimit else { return displayedContent }
        return String(displayedContent.prefix(renderCharacterLimit)) + "\n\n[Truncated in stability mode]"
    }
}

private struct V2Composer: View {
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: (String) -> Void
    let onStop: () -> Void

    @State private var draft = ""
    @Environment(\.textBaseSize) private var textBaseSize
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask anything", text: $draft, axis: .vertical)
                .lineLimit(1 ... 5)
                .focused($focused)
                .font(.system(size: TextSizeConfig.scaled(15, base: textBaseSize), weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .textFieldStyle(.plain)
                .onSubmit {
                    sendIfPossible()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(V2Palette.panelBorder, lineWidth: 1)
                )

            composerActionButton
        }
        .onAppear {
            focused = true
        }
    }

    @ViewBuilder
    private var composerActionButton: some View {
        if isStreaming {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .appFont(size: 14, weight: .bold)
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.22))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        } else {
            Button(action: sendIfPossible) {
                Image(systemName: "arrow.up")
                    .appFont(size: 14, weight: .bold)
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(canSend ? Color.primary.opacity(0.16) : Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
    }

    private func sendIfPossible() {
        guard canSend else { return }
        let text = draft
        draft = ""
        onSend(text)
    }
}
