//
//  TextSizeConfig.swift
//  JChat
//

import SwiftUI

// MARK: - Text Size Environment Key (point size)

enum TextSizeConfig {
    static let minimum: CGFloat = 10
    static let maximum: CGFloat = 20
    static let step: CGFloat = 1
    static let defaultSize: CGFloat = 15

    static func scaled(_ original: CGFloat, base: CGFloat) -> CGFloat {
        base + (original - defaultSize)
    }

    static func size(for style: Font.TextStyle, base: CGFloat) -> CGFloat {
        switch style {
        case .largeTitle:
            return base + 17
        case .title:
            return base + 10
        case .title2:
            return base + 6
        case .title3:
            return base + 4
        case .headline:
            return base + 2
        case .body:
            return base
        case .callout:
            return base - 1
        case .subheadline:
            return base - 2
        case .footnote:
            return base - 3
        case .caption:
            return base - 4
        case .caption2:
            return base - 5
        @unknown default:
            return base
        }
    }
}

private struct TextBaseSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = TextSizeConfig.defaultSize
}

extension EnvironmentValues {
    var textBaseSize: CGFloat {
        get { self[TextBaseSizeKey.self] }
        set { self[TextBaseSizeKey.self] = newValue }
    }
}

private struct AppFontModifier: ViewModifier {
    @Environment(\.textBaseSize) private var textBaseSize
    let style: Font.TextStyle
    let weight: Font.Weight?
    let design: Font.Design

    func body(content: Content) -> some View {
        let size = TextSizeConfig.size(for: style, base: textBaseSize)
        if let weight {
            return content.font(.system(size: size, weight: weight, design: design))
        }
        return content.font(.system(size: size, weight: .regular, design: design))
    }
}

private struct AppSystemFontModifier: ViewModifier {
    @Environment(\.textBaseSize) private var textBaseSize
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        let scaledSize = TextSizeConfig.scaled(size, base: textBaseSize)
        return content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

extension View {
    func appFont(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil,
        design: Font.Design = .default
    ) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, design: design))
    }

    func appFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(AppSystemFontModifier(size: size, weight: weight, design: design))
    }
}
