//
//  ChatToolbarView.swift
//  JChat
//
//  Compact toolbar row combining character picker, model picker,
//  token/cost display, and parameter button.
//

import SwiftUI

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
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)

                        if chat.totalCost > 0 {
                            Text("$\(chat.totalCost, format: .number.precision(.fractionLength(4)))")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Parameters button
                Button(action: onShowParameters) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Advanced Parameters")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()
        }
    }
}
