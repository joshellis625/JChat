//
//  InlineModelPicker.swift
//  JChat
//

import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
    import AppKit
#endif

struct InlineModelPicker: View {
    @Binding var selectedModelID: String?
    @Bindable var modelManager: ModelManager
    @Query(sort: \CachedModel.name) private var cachedModels: [CachedModel]
    @Environment(\.textBaseSize) private var textBaseSize

    @State private var showingPopover = false
    @State private var showingFullManager = false
    @State private var pickerSearchText = ""

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: TextSizeConfig.scaled(12, base: textBaseSize), weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(selectedModelName)
                    .font(.system(size: TextSizeConfig.scaled(14, base: textBaseSize), weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: TextSizeConfig.scaled(9, base: textBaseSize), weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.small)
        .popover(isPresented: $showingPopover) {
            pickerPopover
        }
        .sheet(isPresented: $showingFullManager) {
            ModelManagerView(modelManager: modelManager)
        }
    }

    private var selectedModelName: String {
        guard let id = selectedModelID else { return "Select Model" }
        return ModelNaming.displayName(forModelID: id, namesByID: modelNamesByID)
    }

    private var modelNamesByID: [String: String] {
        ModelNaming.namesByID(from: cachedModels)
    }

    private var pickerPopover: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose a Model")
                        .font(.system(size: TextSizeConfig.scaled(14, base: textBaseSize), weight: .bold, design: .rounded))
                    Text("\(cachedModels.count) cached models")
                        .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Manager") {
                    showingPopover = false
                    showingFullManager = true
                }
                .font(.system(size: TextSizeConfig.scaled(12, base: textBaseSize), weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: TextSizeConfig.scaled(12, base: textBaseSize), weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Search models, IDs, providers...", text: $pickerSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .medium))

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
                            .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .medium))
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
                .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 460)
    }

    private var filteredFavorites: [CachedModel] {
        let favorites = modelManager.sorted(cachedModels.filter { $0.isFavorite }, by: modelManager.sortOrder)
        if pickerSearchText.isEmpty { return favorites }
        let query = pickerSearchText.lowercased()
        return favorites.filter {
            $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query) ||
                $0.providerName.lowercased().contains(query)
        }
    }

    private var filteredAllModels: [CachedModel] {
        let all = modelManager.sorted(cachedModels.filter { !$0.isFavorite }, by: modelManager.sortOrder)
        if pickerSearchText.isEmpty { return Array(all.prefix(70)) }
        let query = pickerSearchText.lowercased()
        return all.filter {
            $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query) ||
                $0.providerName.lowercased().contains(query)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: TextSizeConfig.scaled(10, base: textBaseSize), weight: .semibold, design: .rounded))
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
                        Text(model.uiDisplayName)
                            .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        if model.isFree {
                            BadgeCapsule(text: "FREE", color: .green)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(model.modelSlug)
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text("\(model.contextLengthFormatted) ctx")
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text(compactPrice(for: model))
                            .font(.system(size: TextSizeConfig.scaled(11, base: textBaseSize), weight: .medium, design: .rounded))
                            .foregroundStyle(model.isFree ? .green : .secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if model.id == selectedModelID {
                    Image(systemName: "checkmark")
                        .font(.system(size: TextSizeConfig.scaled(12, base: textBaseSize), weight: .bold))
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
        return "$\(model.promptPricePerMillion.formattedPrice) / $\(model.completionPricePerMillion.formattedPrice)"
    }
}

#Preview {
    InlineModelPicker(
        selectedModelID: .constant("anthropic/claude-sonnet-4"),
        modelManager: ModelManager()
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
