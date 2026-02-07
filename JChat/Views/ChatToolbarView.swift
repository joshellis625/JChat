//
//  ChatToolbarView.swift
//  JChat
//
//  Compact toolbar row combining character picker, model picker,
//  token/cost display, and parameter button.
//

import SwiftUI
import SwiftData

struct ChatToolbarView: View {
    let chat: Chat
    var modelManager: ModelManager
    let onShowParameters: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Character picker
                CharacterPicker(
                    selectedCharacter: Binding(
                        get: { chat.character },
                        set: { chat.character = $0 }
                    ),
                    modelManager: modelManager
                )

                // Model picker
                InlineModelPicker(
                    selectedModelID: Binding(
                        get: { chat.selectedModelID },
                        set: { chat.selectedModelID = $0 }
                    ),
                    modelManager: modelManager
                )

                Spacer()

                // Token count + cost (compact)
                if chat.totalTokens > 0 {
                    HStack(spacing: 6) {
                        Text("\(chat.totalTokens) tok")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        if chat.totalCost > 0 {
                            Text("$\(chat.totalCost, format: .number.precision(.fractionLength(4)))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Parameters button
                Button(action: onShowParameters) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Params")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Advanced Parameters")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()
        }
    }
}

#Preview {
    ChatToolbarView(
        chat: Chat(title: "Preview Chat"),
        modelManager: ModelManager(),
        onShowParameters: {}
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
    .frame(width: 600)
}
