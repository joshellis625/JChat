//
//  MessageActionBar.swift
//  JChat
//

import SwiftUI
import SwiftData

/// Horizontal action bar shown below message bubbles.
/// For assistant messages (left-aligned): token count, cost, edit, copy, regenerate, delete.
/// For user messages (right-aligned): edit, copy, delete.
struct MessageActionBar: View {
    let message: Message
    let isUser: Bool
    let onCopy: () -> Void
    var onRegenerate: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if isUser { Spacer() }

            // Token count (assistant only)
            if message.totalTokens > 0 {
                Label("\(message.totalTokens) tokens", systemImage: "number")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Cost (assistant only)
            if message.cost > 0 {
                Text("$\(message.cost, format: .number.precision(.fractionLength(4)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Edit message")

            // Copy button
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Copy message")

            // Regenerate button (assistant messages only)
            if let onRegenerate {
                Button(action: onRegenerate) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Regenerate response")
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete message")

            if !isUser { Spacer() }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
