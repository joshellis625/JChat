//
//  ModelManager.swift
//  JChat
//

import Foundation
import SwiftData
import SwiftUI

enum ModelSortOrder: String, CaseIterable, Sendable {
    case name = "Name"
    case priceAsc = "Price (Low → High)"
    case priceDesc = "Price (High → Low)"
    case contextLength = "Context Length"
}

@Observable
class ModelManager {
    var isLoading = false
    var searchText = ""
    var selectedProvider: String?
    var sortOrder: ModelSortOrder = .name
    var errorMessage: String?

    private var allModels: [CachedModel] = []
    private let service = OpenRouterService.shared

    // MARK: - Computed Properties

    var filteredModels: [CachedModel] {
        var result = allModels

        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query) ||
                $0.providerName.lowercased().contains(query) ||
                $0.modelDescription.lowercased().contains(query)
            }
        }

        // Apply provider filter
        if let provider = selectedProvider {
            result = result.filter { $0.providerName == provider }
        }

        // Apply sort
        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .priceAsc:
            result.sort { ($0.promptPricePerMillion + $0.completionPricePerMillion) < ($1.promptPricePerMillion + $1.completionPricePerMillion) }
        case .priceDesc:
            result.sort { ($0.promptPricePerMillion + $0.completionPricePerMillion) > ($1.promptPricePerMillion + $1.completionPricePerMillion) }
        case .contextLength:
            result.sort { $0.contextLength > $1.contextLength }
        }

        return result
    }

    var favoriteModels: [CachedModel] {
        allModels
            .filter { $0.isFavorite }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var providers: [String] {
        let providerSet = Set(allModels.map { $0.providerName })
        return providerSet.sorted()
    }

    // MARK: - Data Loading

    func loadModels(from context: ModelContext) {
        let descriptor = FetchDescriptor<CachedModel>(sortBy: [SortDescriptor(\.name)])
        allModels = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Model Fetching

    func fetchAndCacheModels(context: ModelContext) async {
        let apiKey: String
        do {
            apiKey = try KeychainManager.shared.loadAPIKey()
        } catch {
            errorMessage = JChatError.apiKeyNotConfigured.errorDescription
            return
        }

        guard !apiKey.isEmpty else {
            errorMessage = JChatError.apiKeyNotConfigured.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let apiModels = try await service.fetchModels(apiKey: apiKey)

            // Build a set of IDs from the API response
            let apiModelIDs = Set(apiModels.map { $0.id })

            // Fetch existing cached models
            let existingDescriptor = FetchDescriptor<CachedModel>()
            let existingModels = (try? context.fetch(existingDescriptor)) ?? []
            let existingByID = Dictionary(uniqueKeysWithValues: existingModels.map { ($0.id, $0) })

            // Upsert: update existing, insert new
            for apiModel in apiModels {
                if let existing = existingByID[apiModel.id] {
                    // Update existing
                    existing.name = apiModel.name
                    existing.modelDescription = apiModel.description ?? ""
                    existing.contextLength = apiModel.context_length ?? 0
                    existing.maxCompletionTokens = apiModel.top_provider?.max_completion_tokens
                    existing.promptPricing = apiModel.pricing?.prompt ?? "0"
                    existing.completionPricing = apiModel.pricing?.completion ?? "0"
                    existing.imagePricing = apiModel.pricing?.image
                    existing.requestPricing = apiModel.pricing?.request
                    existing.providerName = extractProvider(from: apiModel.id)
                    existing.isModerated = apiModel.top_provider?.is_moderated ?? false
                    existing.modality = apiModel.architecture?.modality ?? "text→text"
                    existing.lastFetchedAt = Date()
                } else {
                    // Insert new
                    let cached = CachedModel(
                        id: apiModel.id,
                        name: apiModel.name,
                        modelDescription: apiModel.description ?? "",
                        contextLength: apiModel.context_length ?? 0,
                        maxCompletionTokens: apiModel.top_provider?.max_completion_tokens,
                        promptPricing: apiModel.pricing?.prompt ?? "0",
                        completionPricing: apiModel.pricing?.completion ?? "0",
                        imagePricing: apiModel.pricing?.image,
                        requestPricing: apiModel.pricing?.request,
                        providerName: extractProvider(from: apiModel.id),
                        isModerated: apiModel.top_provider?.is_moderated ?? false,
                        modality: apiModel.architecture?.modality ?? "text→text"
                    )
                    context.insert(cached)
                }
            }

            // Remove delisted models (not in API response and not favorited)
            for existing in existingModels {
                if !apiModelIDs.contains(existing.id) && !existing.isFavorite {
                    context.delete(existing)
                }
            }

            // Update settings
            let settings = AppSettings.fetchOrCreate(in: context)
            settings.lastModelFetchDate = Date()

            try? context.save()

            // Refresh local cache
            loadModels(from: context)

        } catch {
            let jchatError = (error as? JChatError) ?? .unknown(error)
            errorMessage = jchatError.errorDescription
        }

        isLoading = false
    }

    func refreshIfStale(context: ModelContext) async {
        // Load from cache first
        if allModels.isEmpty {
            loadModels(from: context)
        }

        let settings = AppSettings.fetchOrCreate(in: context)

        if let lastFetch = settings.lastModelFetchDate {
            let elapsed = Date().timeIntervalSince(lastFetch)
            if elapsed < settings.modelCacheMaxAge && !allModels.isEmpty {
                return // Cache is still fresh
            }
        }

        // Stale or never fetched
        await fetchAndCacheModels(context: context)
    }

    // MARK: - Actions

    func toggleFavorite(_ model: CachedModel, context: ModelContext) {
        model.isFavorite.toggle()
        try? context.save()
        loadModels(from: context)
    }

    // MARK: - Helpers

    private func extractProvider(from modelID: String) -> String {
        // OpenRouter model IDs are formatted as "provider/model-name"
        if let slashIndex = modelID.firstIndex(of: "/") {
            let provider = String(modelID[modelID.startIndex..<slashIndex])
            // Capitalize first letter of each word
            return provider
                .split(separator: "-")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
        return "Unknown"
    }
}
