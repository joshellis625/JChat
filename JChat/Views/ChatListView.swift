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

    var body: some View {
        List(selection: $viewModel.selectedChat) {
            ForEach(chats) { chat in
                NavigationLink(value: chat) {
                    chatRow(chat)
                }
                .tag(chat)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteChat(chat, in: modelContext)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    let _ = viewModel.createNewChat(in: modelContext)
                }) {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Chats")
    }

    // MARK: - Chat Row

    private func chatRow(_ chat: Chat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
                .lineLimit(1)
                .font(.body.weight(.medium))

            // Badges row: character + model
            HStack(spacing: 6) {
                if let character = chat.character {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(character.name)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                if let modelID = chat.selectedModelID {
                    HStack(spacing: 2) {
                        Image(systemName: "cpu")
                            .font(.caption2)
                        Text(displayModelName(modelID))
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }

            // Date + message count
            HStack(spacing: 6) {
                Text(chat.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if chat.messages.count > 0 {
                    Text("· \(chat.messages.count) msg")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func displayModelName(_ id: String) -> String {
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }
}
