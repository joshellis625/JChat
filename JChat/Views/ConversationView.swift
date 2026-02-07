//
//  ConversationView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ConversationView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            if let chat = viewModel.selectedChat {
                CostHeaderView(chat: chat)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chat.sortedMessages, id: \.id) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: chat.messages.count) { _, _ in
                        if let lastMessage = chat.sortedMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    VStack(spacing: 4) {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        if let suggestion = viewModel.errorSuggestion {
                            Text(suggestion)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }

                MessageInputView(
                    text: $inputText,
                    isLoading: viewModel.isLoading,
                    isStreaming: viewModel.isStreaming,
                    onSend: {
                        let content = inputText
                        inputText = ""
                        Task {
                            await viewModel.sendMessage(content: content, context: modelContext)
                        }
                    },
                    onStop: {
                        viewModel.stopStreaming()
                    }
                )
            } else {
                ContentUnavailableView {
                    Label("No Chat Selected", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Select a chat from the sidebar or create a new one.")
                }
            }
        }
    }
}
