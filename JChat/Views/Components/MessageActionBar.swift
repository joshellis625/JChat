//
//  MessageActionBar.swift
//  JChat
//

import SwiftUI
import SwiftData

/// Horizontal action bar shown below message bubbles.
/// All messages show edit/copy/delete; assistant messages also show regenerate.
/// Left-aligned for AI messages, right-aligned for user messages.
struct MessageActionBar: View {
    let message: Message
    let isUser: Bool
    let onCopy: () -> Void
    var onRegenerate: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isUser { Spacer() }

            // Token count (assistant only)
            // TODO - Display token count for assistant and user messages. Ensure this number can support at least 3 digits if needed.
            if message.totalTokens > 0 {
                Label("\(message.totalTokens) tokens", systemImage: "number")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Cost (assistant only)
            // TODO - Remove cost per message inline and focus on total conversation tokens and cost in MessageActionBar.swift for accuracy using OpenRouter API endpoint model pricing. Increase numbers shown after the decimal point until at least one significant figure is shown, ideally two unless it get's ridiculously long.
            if message.cost > 0 {
                Text("$\(message.cost, format: .number.precision(.fractionLength(4)))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Edit message")

            // Copy button
            // TODO - Add a transient and clean text alert indicating that the message copy was successful, e.g. "Message copied!"
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Copy message")

            // Regenerate button (assistant messages only)
            if let onRegenerate {
                Button(action: onRegenerate) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Regenerate response")
            }

            // Delete button
            // TODO - ADD SIMPLE CONFIRMATION BEFORE DELETING
            // TODO - Clean animation upon deletion and gap in messages smoothly animated back together to close gap.
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete message")

            // TODO - Does the following if{} do anything? If not, remove it
            if !isUser { Spacer() }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
    }
}

#Preview("Assistant - Left Aligned") {
    MessageActionBar(
        message: Message(
            role: .assistant,
            content: "Hello!",
            promptTokens: 42,
            completionTokens: 128,
            cost: 0.0023,
            modelID: "anthropic/claude-sonnet-4"
        ),
        isUser: false,
        onCopy: {},
        onRegenerate: {},
        onEdit: {},
        onDelete: {}
    )
    .modelContainer(for: [Chat.self, Message.self], inMemory: true)
    .frame(width: 400)
    .padding()
}

#Preview("User - Right Aligned") {
    MessageActionBar(
        message: Message(role: .user, content: "Hello!"),
        isUser: true,
        onCopy: {},
        onEdit: {},
        onDelete: {}
    )
    .modelContainer(for: [Chat.self, Message.self], inMemory: true)
    .frame(width: 400)
    .padding()
}
