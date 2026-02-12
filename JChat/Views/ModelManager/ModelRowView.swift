//
//  ModelRowView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ModelRowView: View {
    let model: CachedModel
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Favorite toggle
            Button(action: onToggleFavorite) {
                Image(systemName: model.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(model.isFavorite ? .yellow : .secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Top row: name + badges
                HStack(spacing: 6) {
                    Text(model.uiDisplayName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)

                    if model.isFree {
                        BadgeCapsule(text: "FREE", color: .green)
                    }

                    ForEach(model.variants, id: \.rawValue) { variant in
                        if variant != .free { // Don't double-show free
                            BadgeCapsule(text: variant.displayLabel, color: variant.badgeColor)
                        }
                    }
                }

                // Bottom row: slug + moderation
                HStack(spacing: 8) {
                    Text(model.modelSlug)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if model.isModerated {
                        HStack(spacing: 2) {
                            Image(systemName: "shield.fill")
                                .font(.caption2)
                            Text("Moderated")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Trailing: context + pricing
            VStack(alignment: .trailing, spacing: 4) {
                Text(model.contextLengthFormatted)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Text(model.displayPrice)
                    .font(.caption2)
                    .foregroundStyle(model.isFree ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge Capsule

struct BadgeCapsule: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}

#Preview {
    List {
        ModelRowView(
            model: {
                let m = CachedModel(
                    id: "anthropic/claude-sonnet-4",
                    name: "Claude Sonnet 4",
                    modelDescription: "Anthropic's latest model",
                    contextLength: 200000,
                    promptPricing: "0.000003",
                    completionPricing: "0.000015",
                    providerName: "Anthropic",
                    isModerated: true,
                    isFavorite: true
                )
                return m
            }(),
            onToggleFavorite: {}
        )
        ModelRowView(
            model: {
                let m = CachedModel(
                    id: "google/gemini-2.0-flash:free",
                    name: "Gemini 2.0 Flash (Free)",
                    contextLength: 1000000,
                    promptPricing: "0",
                    completionPricing: "0",
                    providerName: "Google"
                )
                return m
            }(),
            onToggleFavorite: {}
        )
        ModelRowView(
            model: {
                let m = CachedModel(
                    id: "openai/gpt-4o:extended",
                    name: "GPT-4o (Extended)",
                    contextLength: 128000,
                    promptPricing: "0.0000025",
                    completionPricing: "0.00001",
                    providerName: "OpenAI"
                )
                return m
            }(),
            onToggleFavorite: {}
        )
    }
    .modelContainer(for: [CachedModel.self], inMemory: true)
}
