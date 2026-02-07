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

    var body: some View {
        HStack(spacing: 12) {
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 20, idealHeight: min(100, max(20, CGFloat(text.count) / 2)), maxHeight: 150)

            if isStreaming {
                Button(action: onStop) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(text.isEmpty ? Color.secondary : Color.blue)
                    }
                }
                .disabled(text.isEmpty || isLoading)
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
