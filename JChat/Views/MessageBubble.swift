//
//  MessageBubble.swift
//  JChat
//

import SwiftUI
import SwiftData

struct MessageBubble: View {
    let message: Message

    private var text: String { message.content }
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding(12)
                .background(isUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 4)
                .background(.ultraThinMaterial.opacity(0.2), in: RoundedRectangle(cornerRadius: 18))
            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MessageBubble(message: Message(role: .user, content: "Test message"))
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
