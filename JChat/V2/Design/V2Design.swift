//
//  V2Design.swift
//  JChat
//

import SwiftUI

enum V2Palette {
    static let assistantBubble = Color.primary.opacity(0.06)
    static let assistantBubbleBorder = Color.primary.opacity(0.12)
    static let userBubble = Color.accentColor.opacity(0.26)
    static let panelBorder = Color.primary.opacity(0.12)
}

struct V2CanvasBackground: View {
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

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
    }
}

struct SurfaceCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double
    var fillOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(Color.primary.opacity(fillOpacity * 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(borderOpacity), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, borderOpacity: Double = 0.16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }

    func surfaceCard(
        cornerRadius: CGFloat = 20,
        borderOpacity: Double = 0.14,
        fillOpacity: Double = 0.22
    ) -> some View {
        modifier(
            SurfaceCardModifier(
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                fillOpacity: fillOpacity
            )
        )
    }
}
