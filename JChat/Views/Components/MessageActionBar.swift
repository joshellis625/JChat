//
//  MessageActionBar.swift
//  JChat
//

import SwiftUI
import SwiftData

/// Horizontal action bar shown below each assistant message.
/// Displays token count, cost, and action buttons (copy, regenerate, delete).
struct MessageActionBar: View {
    let message: Message
    let onCopy: () -> Void
    let onRegenerate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Token count
            if message.totalTokens > 0 {
                Label("\(message.totalTokens) tokens", systemImage: "number")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Cost
            if message.cost > 0 {
                Text("$\(message.cost, format: .number.precision(.fractionLength(4)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Copy button
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Copy message")

            // Regenerate button
            Button(action: onRegenerate) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Regenerate response")

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete message")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

#Preview("With Tokens") {
    MessageActionBar(
        message: Message(
            role: .assistant,
            content: "Hello!",
            promptTokens: 42,
            completionTokens: 128,
            cost: 0.0023,
            modelID: "anthropic/claude-sonnet-4"
        ),
        onCopy: {},
        onRegenerate: {},
        onDelete: {}
    )
    .modelContainer(for: [Chat.self, Message.self], inMemory: true)
    .frame(width: 400)
    .padding()
}

#Preview("No Tokens") {
    MessageActionBar(
        message: Message(role: .assistant, content: "Streaming..."),
        onCopy: {},
        onRegenerate: {},
        onDelete: {}
    )
    .modelContainer(for: [Chat.self, Message.self], inMemory: true)
    .frame(width: 400)
    .padding()
}
