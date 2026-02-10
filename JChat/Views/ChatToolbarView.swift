//
//  ChatToolbarView.swift
//  JChat
//
//  Compact toolbar row combining character picker, model picker,
//  token/cost display, and parameter button.
//

import SwiftUI
import SwiftData
import Foundation

struct ChatToolbarView: View {
    let chat: Chat
    var modelManager: ModelManager
    let onShowParameters: () -> Void
    @Environment(\.textSizeMultiplier) private var multiplier

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
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

                Divider()
                    .frame(height: 20)

                Spacer()

                // Token count + cost
                if chat.totalTokens > 0 {
                    metricPill(label: "TOKENS", value: "\(chat.totalTokens)")

                    if chat.totalCost > 0 {
                        metricPill(
                            label: "COST",
                            value: String(format: "$%.4f", chat.totalCost)
                        )
                    }
                }

                // Parameters button
                Button(action: onShowParameters) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Parameters")
                        if chat.overrideCount > 0 {
                            Text("\(chat.overrideCount)")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    .font(.system(size: 13 * multiplier))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.controlBackgroundColor))
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Advanced Parameters")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()
        }
    }

    @ViewBuilder
    private func metricPill(label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12 * multiplier).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .overlay(
            Capsule()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(Capsule())
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
