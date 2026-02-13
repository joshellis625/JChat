//
//  ModelNaming.swift
//  JChat
//

import Foundation

enum ModelNaming {
    static func namesByID(from models: [CachedModel]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, cleanedDisplayName(for: $0)) })
    }

    static func displayName(forModelID id: String, namesByID: [String: String]) -> String {
        if let name = namesByID[id], !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return humanizedSlug(fromModelID: id)
    }

    static func slug(fromModelID id: String) -> String {
        guard let slashIndex = id.firstIndex(of: "/") else { return id }
        return String(id[id.index(after: slashIndex)...])
    }

    static func cleanedDisplayName(for model: CachedModel) -> String {
        cleanedDisplayName(model.displayName, providerName: model.providerName)
    }

    static func cleanedDisplayName(_ rawName: String, providerName: String?) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return rawName }
        guard let providerName, !providerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return trimmed
        }

        let separators = [":", "-", "|", "•", "—"]
        for separator in separators {
            let parts = trimmed.components(separatedBy: separator)
            guard parts.count >= 2 else { continue }

            let left = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let right = parts.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !right.isEmpty else { continue }

            if normalizedToken(left) == normalizedToken(providerName) {
                return right
            }
        }
        return trimmed
    }

    static func humanizedSlug(fromModelID id: String) -> String {
        let slug = slug(fromModelID: id)
        let separators = CharacterSet(charactersIn: "-_:")
        let pieces = slug.components(separatedBy: separators).filter { !$0.isEmpty }
        if pieces.isEmpty { return slug }
        return pieces
            .map { word in
                guard let first = word.first else { return word }
                return String(first).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func normalizedToken(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
