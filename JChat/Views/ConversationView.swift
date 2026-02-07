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
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if let chat = viewModel.selectedChat {
                CostHeaderView(chat: chat)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chat.messages, id: \.id) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: chat.messages.count) { _, _ in
                        if let lastMessage = chat.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                MessageInputView(
                    text: $inputText,
                    temperature: .init(
                        get: { viewModel.selectedChat?.temperatureOverride ?? 0.7 },
                        set: { _ in }
                    ),
                    maxTokens: .init(
                        get: { viewModel.selectedChat?.maxTokensOverride ?? 4096 },
                        set: { _ in }
                    ),
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        let settings = APISettings.fetchOrCreate(in: modelContext)
                        await viewModel.sendMessage(content: inputText, settings: settings, context: modelContext)
                        inputText = ""
                    }
                }
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
