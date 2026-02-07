//
//  CachedModel.swift
//  JChat
//

import Foundation
import SwiftData

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
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.lastFetchedAt = Date()
    }

    var promptPricePerMillion: Double {
        (Double(promptPricing) ?? 0.0) * 1_000_000
    }

    var completionPricePerMillion: Double {
        (Double(completionPricing) ?? 0.0) * 1_000_000
    }

    var displayPrice: String {
        let prompt = promptPricePerMillion
        let completion = completionPricePerMillion
        if prompt == 0 && completion == 0 {
            return "Free"
        }
        return "$\(formatPrice(prompt)) / $\(formatPrice(completion)) per 1M tokens"
    }

    var contextLengthFormatted: String {
        if contextLength >= 1_000_000 {
            return "\(contextLength / 1_000_000)M context"
        } else if contextLength >= 1_000 {
            return "\(contextLength / 1_000)K context"
        }
        return "\(contextLength) context"
    }

    func calculateCost(promptTokens: Int, completionTokens: Int) -> Double {
        let promptCost = Double(promptTokens) * (Double(promptPricing) ?? 0.0)
        let completionCost = Double(completionTokens) * (Double(completionPricing) ?? 0.0)
        return promptCost + completionCost
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
