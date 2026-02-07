//
//  MessageInputView.swift
//  JChat
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @Environment(\.textSizeMultiplier) private var multiplier
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if text.isEmpty {
                        Text("Message...")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 13 * multiplier))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .font(.system(size: 13 * multiplier))
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .frame(minHeight: 20, maxHeight: 150)
                        .fixedSize(horizontal: false, vertical: true)
                        .focused($isFocused)
                        .onKeyPress(.return, phases: .down) { keyPress in
                            if keyPress.modifiers.contains(.shift) {
                                return .ignored
                            }
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming {
                                onSend()
                                return .handled
                            }
                            return .ignored
                        }
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
                )

                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generating")
                } else {
                    Button(action: onSend) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .buttonStyle(.plain)
                    .help("Send message (Return)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview("Empty") {
    MessageInputView(
        text: .constant(""),
        isLoading: false,
        isStreaming: false,
        onSend: {},
        onStop: {}
    )
    .frame(width: 500)
}

#Preview("With Text") {
    MessageInputView(
        text: .constant("Hello, how are you doing today?"),
        isLoading: false,
        isStreaming: false,
        onSend: {},
        onStop: {}
    )
    .frame(width: 500)
}

#Preview("Loading") {
    MessageInputView(
        text: .constant(""),
        isLoading: true,
        isStreaming: false,
        onSend: {},
        onStop: {}
    )
    .frame(width: 500)
}

#Preview("Streaming") {
    MessageInputView(
        text: .constant(""),
        isLoading: false,
        isStreaming: true,
        onSend: {},
        onStop: {}
    )
    .frame(width: 500)
}
