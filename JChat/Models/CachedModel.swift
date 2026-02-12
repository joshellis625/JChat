//
//  CachedModel.swift
//  JChat
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Model Variant

enum ModelVariant: String, CaseIterable, Sendable {
    case free = ":free"
    case extended = ":extended"
    case exacto = ":exacto"

    var displayLabel: String {
        switch self {
        case .free: return "Free"
        case .extended: return "Extended"
        case .exacto: return "Exacto"
        }
    }

    var badgeColor: Color {
        switch self {
        case .free: return .green
        case .extended: return .blue
        case .exacto: return .red
        }
    }
}

// MARK: - CachedModel

@Model
final class CachedModel {
    @Attribute(.unique) var id: String
    var name: String
    var modelDescription: String
    var contextLength: Int
    var maxCompletionTokens: Int?
    var promptPricing: String
    var completionPricing: String
    var imagePricing: String?
    var requestPricing: String?
    var providerName: String
    var isModerated: Bool
    var modality: String
    var isFavorite: Bool
    var sortOrder: Int
    var lastFetchedAt: Date

    init(
        id: String,
        name: String,
        modelDescription: String = "",
        contextLength: Int = 0,
        maxCompletionTokens: Int? = nil,
        promptPricing: String = "0",
        completionPricing: String = "0",
        imagePricing: String? = nil,
        requestPricing: String? = nil,
        providerName: String = "",
        isModerated: Bool = false,
        modality: String = "text→text",
        isFavorite: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.modelDescription = modelDescription
        self.contextLength = contextLength
        self.maxCompletionTokens = maxCompletionTokens
        self.promptPricing = promptPricing
        self.completionPricing = completionPricing
        self.imagePricing = imagePricing
        self.requestPricing = requestPricing
        self.providerName = providerName
        self.isModerated = isModerated
        self.modality = modality
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.lastFetchedAt = Date()
    }

    // MARK: - Variant Detection

    var variants: [ModelVariant] {
        ModelVariant.allCases.filter { id.hasSuffix($0.rawValue) }
    }

    var displayName: String {
        var result = name
        for variant in ModelVariant.allCases {
            if result.lowercased().hasSuffix(" (\(variant.displayLabel.lowercased()))") {
                result = String(result.dropLast(variant.displayLabel.count + 3))
            }
        }
        return result
    }

    var uiDisplayName: String {
        ModelNaming.cleanedDisplayName(for: self)
    }

    var modelSlug: String {
        ModelNaming.slug(fromModelID: id)
    }

    // MARK: - Pricing

    var isFree: Bool {
        nonNegativePromptPricePerToken == 0 && nonNegativeCompletionPricePerToken == 0
    }

    var promptPricePerMillion: Double {
        nonNegativePromptPricePerToken * 1_000_000
    }

    var completionPricePerMillion: Double {
        nonNegativeCompletionPricePerToken * 1_000_000
    }

    var displayPrice: String {
        if isFree {
            return "Free"
        }
        return "$\(formatPrice(promptPricePerMillion)) / $\(formatPrice(completionPricePerMillion)) per 1M tokens"
    }

    var contextLengthFormatted: String {
        if contextLength >= 1_000_000 {
            return "\(contextLength / 1_000_000)M"
        } else if contextLength >= 1_000 {
            return "\(contextLength / 1_000)K"
        }
        return "\(contextLength)"
    }

    func calculateCost(promptTokens: Int, completionTokens: Int) -> Double {
        let promptCost = Double(promptTokens) * nonNegativePromptPricePerToken
        let completionCost = Double(completionTokens) * nonNegativeCompletionPricePerToken
        return promptCost + completionCost
    }

    private var nonNegativePromptPricePerToken: Double {
        max(0, Double(promptPricing) ?? 0.0)
    }

    private var nonNegativeCompletionPricePerToken: Double {
        max(0, Double(completionPricing) ?? 0.0)
    }

    private func formatPrice(_ price: Double) -> String {
        if price < 0.01 {
            return String(format: "%.4f", price)
        } else if price < 1.0 {
            return String(format: "%.2f", price)
        }
        return String(format: "%.1f", price)
    }
}
