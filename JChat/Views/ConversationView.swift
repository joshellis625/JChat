//
//  ConversationView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ConversationView: View {
    @Bindable var viewModel: ChatViewModel
    var modelManager: ModelManager
    @Environment(\.modelContext) private var modelContext

    @State private var inputText = ""
    @State private var showAdvancedParams = false

    var body: some View {
        VStack(spacing: 0) {
            if let chat = viewModel.selectedChat {
                // Combined toolbar: character, model, tokens/cost, params
                ChatToolbarView(
                    chat: chat,
                    modelManager: modelManager,
                    onShowParameters: { showAdvancedParams = true }
                )

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chat.sortedMessages, id: \.id) { message in
                                MessageBubble(
                                    message: message,
                                    onCopy: {
                                        #if canImport(AppKit)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(message.content, forType: .string)
                                        #endif
                                    },
                                    onRegenerate: {
                                        Task {
                                            await viewModel.regenerateMessage(message, in: modelContext)
                                        }
                                    },
                                    onDelete: {
                                        viewModel.deleteMessage(message, in: modelContext)
                                    }
                                )
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

                // Error display
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            if let suggestion = viewModel.errorSuggestion {
                                Text(suggestion)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            viewModel.errorMessage = nil
                            viewModel.errorSuggestion = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                }

                // Input
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
        .sheet(isPresented: $showAdvancedParams) {
            if let chat = viewModel.selectedChat {
                AdvancedParameterPanel(chat: chat)
            }
        }
    }
}
