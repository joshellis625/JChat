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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.title)
                            .lineLimit(1)
                        Text(chat.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
}
