//
//  ChatListView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ChatListView: View {
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]
    @Bindable var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var chatToDelete: Chat?

    var body: some View {
        List(selection: $viewModel.selectedChat) {
            ForEach(chats) { chat in
                NavigationLink(value: chat) {
                    chatRow(chat)
                }
                .tag(chat)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if chat.messages.isEmpty {
                            viewModel.deleteChat(chat, in: modelContext)
                        } else {
                            chatToDelete = chat
                        }
                    }
                }
            }
        }
        .alert("Delete Chat", isPresented: Binding(
            get: { chatToDelete != nil },
            set: { if !$0 { chatToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { chatToDelete = nil }
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    viewModel.deleteChat(chat, in: modelContext)
                    chatToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this chat? All messages will be lost.")
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    let _ = viewModel.createNewChat(in: modelContext)
                }) {
                    Label("New Chat", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .navigationTitle("Chats")
    }

    // MARK: - Chat Row

    private func chatRow(_ chat: Chat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
                .lineLimit(1)
                .font(.system(size: 15, weight: .medium))

            // Model badge
            if let modelID = chat.selectedModelID {
                HStack(spacing: 3) {
                    Image(systemName: "cpu")
                        .font(.system(size: 12))
                    Text(displayModelName(modelID))
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            // Date + message count
            HStack(spacing: 6) {
                Text(chat.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)

                if chat.messages.count > 0 {
                    Text("· \(chat.messages.count) msg")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func displayModelName(_ id: String) -> String {
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }
}

#Preview {
    ChatListView(viewModel: ChatViewModel())
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
        .frame(width: 250, height: 400)
}
