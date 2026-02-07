//
//  ChatViewModel.swift
//  JChat
//

import SwiftUI
import SwiftData

@Observable
class ChatViewModel {
    var selectedChat: Chat?
    var isLoading = false
    var errorMessage: String?
    
    private let service = OpenRouterService.shared
    
    func createNewChat(in context: ModelContext) -> Chat {
        let chat = Chat()
        context.insert(chat)
        try? context.save()
        selectedChat = chat
        return chat
    }
    
    func deleteChat(_ chat: Chat, in context: ModelContext) {
        if selectedChat?.id == chat.id {
            selectedChat = nil
        }
        context.delete(chat)
        try? context.save()
    }
    
    @MainActor
    func sendMessage(content: String, settings: APISettings, context: ModelContext) async {
        guard let chat = selectedChat else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Add user message
        let userMessage = Message(role: .user, content: content)
        userMessage.chat = chat
        chat.messages.append(userMessage)
        
        // Prepare conversation history
        var history: [(role: String, content: String)] = []
        if chat.messages.count > 1 {
            history = chat.messages.dropLast().map { (role: $0.role.rawValue, content: $0.content) }
        }
        history.append((role: "user", content: content))
        
        do {
            let result = try await service.sendMessage(messages: history, settings: settings)
            
            // Add assistant message
            let assistantMessage = Message(
                role: .assistant,
                content: result.content,
                promptTokens: result.promptTokens,
                completionTokens: result.completionTokens,
                cost: result.cost
            )
            assistantMessage.chat = chat
            chat.messages.append(assistantMessage)
            
            // Update chat totals
            chat.totalPromptTokens += result.promptTokens
            chat.totalCompletionTokens += result.completionTokens
            chat.totalCost += result.cost
            
            // Update title if first message
            if chat.messages.count == 2 {
                chat.title = String(content.prefix(30)) + (content.count > 30 ? "..." : "")
            }
            
            try? context.save()
            
        } catch {
            errorMessage = error.localizedDescription
            // Remove the user message if failed
            if let lastMessage = chat.messages.last, lastMessage.role == .user {
                chat.messages.removeAll { $0.id == lastMessage.id }
                try? context.save()
            }
        }
        
        isLoading = false
    }
}
