//
//  MessageInputView.swift
//  JChat
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    @Binding var temperature: Double
    @Binding var maxTokens: Int
    let isLoading: Bool
    let onSend: () -> Void
    
    @State private var showParameters = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showParameters {
                parameterControls
                    .padding()
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) {
                        showParameters.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(showParameters ? Color.blue : Color.secondary)
                }
                .buttonStyle(.plain)
                
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 20, idealHeight: min(100, max(20, CGFloat(text.count) / 2)), maxHeight: 150)
                
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
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    private var parameterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Temperature: \(temperature, format: .number.precision(.fractionLength(2)))")
                    .font(.caption)
                Slider(value: $temperature, in: 0...2, step: 0.1)
            }
            
            HStack {
                Text("Max Tokens: \(maxTokens)")
                    .font(.caption)
                Slider(value: .init(
                    get: { Double(maxTokens) },
                    set: { maxTokens = Int($0) }
                ), in: 256...8192, step: 256)
            }
        }
    }
}
