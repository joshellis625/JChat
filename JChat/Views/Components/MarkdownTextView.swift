//
//  MarkdownTextView.swift
//  JChat
//

import SwiftUI

/// Renders Markdown-formatted text for assistant messages.
/// Handles inline formatting (bold, italic, code, links) and fenced code blocks
/// with a distinct monospaced background.
struct MarkdownTextView: View {
    let content: String
    @Environment(\.textSizeMultiplier) private var multiplier

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    Text(attributedString(from: text))
                        .font(.system(size: 13 * multiplier))
                        .textSelection(.enabled)

                case .codeBlock(let language, let code):
                    codeBlockView(language: language, code: code)
                }
            }
        }
    }

    // MARK: - Block Parsing

    private enum ContentBlock {
        case text(String)
        case codeBlock(language: String?, code: String)
    }

    /// Splits content into alternating text blocks and fenced code blocks.
    private func parseBlocks() -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: "\n")
        var currentText = ""
        var inCodeBlock = false
        var codeLanguage: String?
        var codeLines: [String] = []

        for line in lines {
            if !inCodeBlock && line.hasPrefix("```") {
                // Start of code block — flush any accumulated text
                let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    blocks.append(.text(trimmed))
                }
                currentText = ""

                // Extract optional language tag
                let langTag = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeLanguage = langTag.isEmpty ? nil : langTag
                codeLines = []
                inCodeBlock = true
            } else if inCodeBlock && line.hasPrefix("```") {
                // End of code block
                blocks.append(.codeBlock(language: codeLanguage, code: codeLines.joined(separator: "\n")))
                inCodeBlock = false
                codeLanguage = nil
                codeLines = []
            } else if inCodeBlock {
                codeLines.append(line)
            } else {
                if !currentText.isEmpty {
                    currentText += "\n"
                }
                currentText += line
            }
        }

        // Handle unclosed code block (streaming in progress)
        if inCodeBlock {
            blocks.append(.codeBlock(language: codeLanguage, code: codeLines.joined(separator: "\n")))
        }

        // Flush remaining text
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            blocks.append(.text(trimmed))
        }

        return blocks
    }

    // MARK: - Inline Markdown → AttributedString

    /// Converts inline Markdown (bold, italic, code, links) to an AttributedString.
    private func attributedString(from text: String) -> AttributedString {
        // Use Apple's built-in Markdown parser
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        // Fallback: plain text
        return AttributedString(text)
    }

    // MARK: - Code Block View

    private func codeBlockView(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(languageLabel(from: language))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    #if canImport(AppKit)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Copy code")
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12 * multiplier, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private func languageLabel(from language: String?) -> String {
        guard let lang = language?.trimmingCharacters(in: .whitespacesAndNewlines), !lang.isEmpty else {
            return "text"
        }
        return lang
    }
}

#Preview {
    MarkdownTextView(content: """
    Here's some **bold** text, *italic* text, and `inline code`.

    A paragraph with a [link](https://example.com) in it.

    ```swift
    struct ContentView: View {
        var body: some View {
            Text("Hello, world!")
        }
    }
    ```

    And a follow-up paragraph after the code block.

    ```python
    def hello():
        print("Hello from Python!")
    ```
    """)
    .padding()
    .frame(width: 500)
}
