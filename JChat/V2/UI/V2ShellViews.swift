//
//  V2ShellViews.swift
//  JChat
//

import SwiftUI
import SwiftData

private let v2DefaultTextBaseSize: CGFloat = 14

private func v2TextSize(_ original: CGFloat, baseSize: CGFloat) -> CGFloat {
    original + (baseSize - v2DefaultTextBaseSize)
}

struct V2SidebarView: View {
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    @Bindable var store: ConversationStore
    @Environment(\.modelContext) private var modelContext
    @State private var chatToDelete: Chat?

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Text("JChat")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(chats.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)

            List {
                ForEach(chats) { chat in
                    Button {
                        store.selectedChat = chat
                    } label: {
                        V2SidebarRow(chat: chat, isSelected: store.selectedChat?.id == chat.id)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            chatToDelete = chat
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .padding(12)
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
    }
}

private struct V2SidebarRow: View {
    let chat: Chat
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chat.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(previewText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                if let model = chat.selectedModelID {
                    Text(displayModelName(model))
                        .lineLimit(1)
                } else {
                    Text("No model")
                        .lineLimit(1)
                }
                Text("•")
                Text(chatTimestampText)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private func displayModelName(_ id: String) -> String {
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
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
    @Environment(\.textBaseSize) private var textBaseSize
    @State private var rows: [MessageRowViewData] = []
    @State private var totalMessageCount = 0
    @State private var lastStreamAutoScrollAt = ContinuousClock.now
    @State private var didInitialBottomScroll = false
    @State private var errorDismissTask: Task<Void, Never>?
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
                            .font(.system(size: v2TextSize(11, baseSize: textBaseSize), weight: .semibold, design: .rounded))
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
                            .font(.system(size: v2TextSize(13, baseSize: textBaseSize), weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if let suggestion = store.errorSuggestion {
                            Text(suggestion)
                                .font(.system(size: v2TextSize(12, baseSize: textBaseSize), weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        dismissErrorBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
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
                Text(chat.title)
                    .font(.system(size: v2TextSize(17, baseSize: textBaseSize), weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(chat.totalTokens) tokens • \(chat.totalCost, format: .currency(code: "USD"))")
                    .font(.system(size: v2TextSize(11, baseSize: textBaseSize), weight: .medium, design: .rounded))
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
        V2MessageRow(
            row: row,
            displayedContent: liveStreamingContent ?? row.content,
            isLiveStreaming: liveAssistantID == row.id
        )
    }
}

private struct V2MessageRow: View, Equatable {
    let row: MessageRowViewData
    let displayedContent: String
    let isLiveStreaming: Bool

    @Environment(\.textBaseSize) private var textBaseSize

    private var isUser: Bool { row.role == .user }
    private let renderCharacterLimit = 6000

    static func == (lhs: V2MessageRow, rhs: V2MessageRow) -> Bool {
        lhs.row == rhs.row &&
        lhs.displayedContent == rhs.displayedContent &&
        lhs.isLiveStreaming == rhs.isLiveStreaming
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 0)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 5) {
                if !isUser, let modelID = row.modelID {
                    Text(displayModelName(modelID))
                        .font(.system(size: v2TextSize(11, baseSize: textBaseSize), weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(renderedContent)
                    .font(.system(size: v2TextSize(14, baseSize: textBaseSize), weight: .regular, design: .default))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Color.primary.opacity(isUser ? 0.12 : 0.10), lineWidth: 1)
                    )
                    .frame(maxWidth: 720, alignment: isUser ? .trailing : .leading)
                    .opacity(isLiveStreaming ? 0.98 : 1.0)

                HStack(spacing: 8) {
                    Text(row.timestamp, style: .time)
                    if row.role == .assistant, row.completionTokens > 0 {
                        Text("\(row.completionTokens) tokens")
                    }
                    if row.cost > 0 {
                        Text(row.cost, format: .currency(code: "USD"))
                    }
                }
                .font(.system(size: v2TextSize(11, baseSize: textBaseSize), weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }
            .frame(maxWidth: 720, alignment: isUser ? .trailing : .leading)

            if !isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
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

    private func displayModelName(_ id: String) -> String {
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
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
            TextField("Message OpenRouter...", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($focused)
                .font(.system(size: v2TextSize(15, baseSize: textBaseSize), weight: .regular, design: .default))
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.22))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        } else {
            Button(action: sendIfPossible) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
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
