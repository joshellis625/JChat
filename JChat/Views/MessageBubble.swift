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
    var onSaveEdit: ((String) -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.textSizeMultiplier) private var multiplier
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @State private var editText = ""

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
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

                // Message content — display or edit mode
                if isEditing {
                    VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                        TextEditor(text: $editText)
                            .font(.system(size: 13 * multiplier))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 32, maxHeight: 200)
                            .padding(8)
                            .background(Color(.textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )

                        HStack(spacing: 8) {
                            Button {
                                isEditing = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .help("Cancel editing")

                            Button {
                                let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                onSaveEdit?(trimmed)
                                isEditing = false
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13))
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                            .help("Save edit")
                        }
                    }
                } else {
                    Group {
                        if isUser {
                            Text(message.content)
                                .font(.system(size: 13 * multiplier))
                                .textSelection(.enabled)
                        } else {
                            MarkdownTextView(content: message.content)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 520, alignment: isUser ? .trailing : .leading)
                }

                HStack(spacing: 6) {
                    if message.isEdited {
                        Text("Edited")
                            .font(.system(size: 11 * multiplier, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(formattedTimestamp(message.timestamp))
                        .font(.system(size: 11 * multiplier))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 520, alignment: isUser ? .trailing : .leading)

                // Action bar — always visible, hidden during editing
                if !isEditing {
                    MessageActionBar(
                        message: message,
                        isUser: isUser,
                        onCopy: { onCopy?() },
                        onRegenerate: isUser ? nil : { onRegenerate?() },
                        onEdit: {
                            editText = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                            isEditing = true
                        },
                        onDelete: { showDeleteConfirmation = true }
                    )
                    .padding(.horizontal, 4)
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
        .alert("Delete Message", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete this message? This cannot be undone.")
        }
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

    private func formattedTimestamp(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return MessageBubble.timeFormatter.string(from: date)
        }
        return MessageBubble.dateTimeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
    }()
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
