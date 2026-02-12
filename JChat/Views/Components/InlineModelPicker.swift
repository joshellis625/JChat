//
//  InlineModelPicker.swift
//  JChat
//

import SwiftUI
import SwiftData
import Foundation

struct InlineModelPicker: View {
    @Binding var selectedModelID: String?
    @Bindable var modelManager: ModelManager
    @Query(sort: \CachedModel.name) private var cachedModels: [CachedModel]

    @State private var showingPopover = false
    @State private var showingFullManager = false
    @State private var pickerSearchText = ""

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Model")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(selectedModelName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(minWidth: 230, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            pickerPopover
        }
        .sheet(isPresented: $showingFullManager) {
            ModelManagerView(modelManager: modelManager)
        }
    }

    private var selectedModelName: String {
        guard let id = selectedModelID else { return "Select Model" }
        if let model = cachedModels.first(where: { $0.id == id }) {
            return model.displayName
        }
        // Fallback: show the ID in a readable form
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }

    private var pickerPopover: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose a Model")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("\(cachedModels.count) cached models")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Manager") {
                    showingPopover = false
                    showingFullManager = true
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Search models, IDs, providers...", text: $pickerSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))

                if !pickerSearchText.isEmpty {
                    Button {
                        pickerSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.bar)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    let favorites = filteredFavorites
                    if !favorites.isEmpty {
                        sectionHeader("Favorites")
                        ForEach(favorites, id: \.id) { model in
                            modelPickerRow(model)
                        }
                    }

                    let allFiltered = filteredAllModels
                    if !allFiltered.isEmpty {
                        sectionHeader("All Models")
                        ForEach(allFiltered, id: \.id) { model in
                            modelPickerRow(model)
                        }
                    } else if !pickerSearchText.isEmpty {
                        Text("No models match \"\(pickerSearchText)\"")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 390)

            Divider()

            Button {
                showingPopover = false
                showingFullManager = true
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Browse Full Model Manager")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 460)
    }

    private var filteredFavorites: [CachedModel] {
        let favorites = sortModels(cachedModels.filter { $0.isFavorite })
        if pickerSearchText.isEmpty { return favorites }
        let query = pickerSearchText.lowercased()
        return favorites.filter {
            $0.name.lowercased().contains(query) ||
            $0.id.lowercased().contains(query) ||
            $0.providerName.lowercased().contains(query)
        }
    }

    private var filteredAllModels: [CachedModel] {
        let all = sortModels(cachedModels.filter { !$0.isFavorite })
        if pickerSearchText.isEmpty { return Array(all.prefix(70)) }
        let query = pickerSearchText.lowercased()
        return all.filter {
            $0.name.lowercased().contains(query) ||
            $0.id.lowercased().contains(query) ||
            $0.providerName.lowercased().contains(query)
        }
    }

    private func sortModels(_ models: [CachedModel]) -> [CachedModel] {
        switch modelManager.sortOrder {
        case .name:
            return models.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .priceAsc:
            return models.sorted { ($0.promptPricePerMillion + $0.completionPricePerMillion) < ($1.promptPricePerMillion + $1.completionPricePerMillion) }
        case .priceDesc:
            return models.sorted { ($0.promptPricePerMillion + $0.completionPricePerMillion) > ($1.promptPricePerMillion + $1.completionPricePerMillion) }
        case .contextLength:
            return models.sorted { $0.contextLength > $1.contextLength }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func modelPickerRow(_ model: CachedModel) -> some View {
        Button {
            selectedModelID = model.id
            showingPopover = false
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        if model.isFree {
                            BadgeCapsule(text: "FREE", color: .green)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(model.providerName)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text("\(model.contextLengthFormatted) ctx")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text(compactPrice(for: model))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(model.isFree ? .green : .secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if model.id == selectedModelID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(model.id == selectedModelID ? Color.accentColor.opacity(0.14) : Color.clear)
        )
    }

    private func compactPrice(for model: CachedModel) -> String {
        guard !model.isFree else { return "Free" }
        return "$\(compact(model.promptPricePerMillion)) / $\(compact(model.completionPricePerMillion))"
    }

    private func compact(_ value: Double) -> String {
        if value < 0.01 {
            return String(format: "%.4f", value)
        }
        if value < 1.0 {
            return String(format: "%.2f", value)
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    InlineModelPicker(
        selectedModelID: .constant("anthropic/claude-sonnet-4"),
        modelManager: ModelManager()
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
