//
//  MessageBubble.swift
//  JChat
//

import SwiftUI
import SwiftData

struct MessageBubble: View {
    let message: Message
    var onCopy: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var isHovered = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Model badge for assistant messages
                if !isUser, let modelID = message.modelID {
                    Text(displayModelName(modelID))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                // Message content
                Group {
                    if isUser {
                        Text(message.content)
                            .textSelection(.enabled)
                    } else {
                        MarkdownTextView(content: message.content)
                    }
                }
                .padding(12)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Action bar for assistant messages (hover only)
                if !isUser, isHovered {
                    MessageActionBar(
                        message: message,
                        onCopy: { onCopy?() },
                        onRegenerate: { onRegenerate?() },
                        onDelete: { onDelete?() }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.horizontal, 4)
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var bubbleBackground: some ShapeStyle {
        if isUser {
            return AnyShapeStyle(Color.accentColor.opacity(0.85))
        } else {
            return AnyShapeStyle(Color(.windowBackgroundColor).opacity(0.8))
        }
    }

    private func displayModelName(_ id: String) -> String {
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: Message(role: .user, content: "Hello, how are you?"))
        MessageBubble(
            message: Message(role: .assistant, content: "I'm doing well! Here's some **bold** and *italic* text.\n\n```swift\nlet x = 42\nprint(x)\n```\n\nAnd a regular paragraph."),
            onCopy: {},
            onRegenerate: {},
            onDelete: {}
        )
    }
    .padding()
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
