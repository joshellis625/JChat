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

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 10) {
                // Text input area
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if text.isEmpty {
                        Text("Message...")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14 * multiplier))
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .font(.system(size: 14 * multiplier))
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .frame(minHeight: 24, maxHeight: 35)
                        .focused($isFocused)
                        .onKeyPress(.return, phases: .down) { keyPress in
                            if keyPress.modifiers.contains(.shift) {
                                return .ignored
                            }
                            if canSend {
                                onSend()
                                return .handled
                            }
                            return .ignored
                        }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
                )

                // Send / Stop button
                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generating")
                } else {
                    Button(action: onSend) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 26, height: 26)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(canSend ? Color.accentColor : Color.secondary.opacity(0.4))
                        }
                    }
                    .disabled(!canSend)
                    .buttonStyle(.plain)
                    .help("Send message (Return)")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 8)

            HStack {
                Text("Return sends • Shift + Return adds a newline")
                    .font(.system(size: 11 * multiplier))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
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
