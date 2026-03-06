//
//  AppDesign.swift
//  JChat
//

import SwiftUI

// MARK: - Color palette for chat content surfaces
// These are semantic content colors, not chrome/control surfaces.
// For chrome/controls, use native .glassEffect(in:) and .buttonStyle(.glass) directly.
enum AppPalette {
    static let assistantBubble = Color.primary.opacity(0.06)
    static let assistantBubbleBorder = Color.primary.opacity(0.12)
    static let userBubble = Color.accentColor.opacity(0.26)
    static let panelBorder = Color.primary.opacity(0.12)
}

// MARK: - Window canvas background
struct CanvasBackground: View {
    var body: some View {
        #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
        #else
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        #endif
    }
}
