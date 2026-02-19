//
//  ModelManagerView.swift
//  JChat
//

import SwiftData
import SwiftUI

struct ModelManagerView: View {
    @Bindable var modelManager: ModelManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Provider filter pills
                providerFilterBar

                // Model list
                modelList
            }
            .navigationTitle("Model Manager")
            .searchable(text: $modelManager.searchText, prompt: "Search models...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        sortMenu
                        refreshButton
                    }
                }
            }
            .task {
                await modelManager.refreshIfStale(context: modelContext)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - Provider Filter Bar

    // TODO: - This selection should only be for search assistance and for reducing the number of listed models. Once the Model Manager is closed, these filters should be removed and they should NEVER effect the Inline Model Picker (See related TODO in InlineModelPicker.swift)
    private var providerFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                FilterPill(
                    title: "All",
                    isSelected: modelManager.selectedProvider == nil
                ) {
                    modelManager.selectedProvider = nil
                }

                ForEach(modelManager.providers, id: \.self) { provider in
                    FilterPill(
                        title: provider,
                        isSelected: modelManager.selectedProvider == provider
                    ) {
                        if modelManager.selectedProvider == provider {
                            modelManager.selectedProvider = nil
                        } else {
                            modelManager.selectedProvider = provider
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    // MARK: - Model List

    private var modelList: some View {
        Group {
            if modelManager.isLoading && modelManager.filteredModels.isEmpty {
                ContentUnavailableView {
                    ProgressView()
                        .scaleEffect(1.2)
                } description: {
                    Text("Loading models from OpenRouter...")
                }
            } else if modelManager.filteredModels.isEmpty {
                ContentUnavailableView {
                    Label("No Models Found", systemImage: "magnifyingglass")
                } description: {
                    if !modelManager.searchText.isEmpty {
                        Text("No models match \"\(modelManager.searchText)\"")
                    } else if modelManager.selectedProvider != nil {
                        Text("No models from this provider")
                    } else {
                        Text("Add your OpenRouter API key in Settings to browse models.")
                    }
                }
            } else {
                List {
                    // Favorites section (if any)
                    if !modelManager.favoriteModels.isEmpty && modelManager.selectedProvider == nil && modelManager.searchText.isEmpty {
                        Section("Favorites") {
                            ForEach(modelManager.favoriteModels, id: \.id) { model in
                                ModelRowView(model: model) {
                                    modelManager.toggleFavorite(model, context: modelContext)
                                }
                            }
                        }
                    }

                    // All models section
                    Section(modelManager.favoriteModels.isEmpty || modelManager.selectedProvider != nil || !modelManager.searchText.isEmpty ? "" : "All Models") {
                        ForEach(modelManager.filteredModels, id: \.id) { model in
                            ModelRowView(model: model) {
                                modelManager.toggleFavorite(model, context: modelContext)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = modelManager.errorMessage {
                Text(error)
                    .appFont(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                    .transition(.move(edge: .bottom))
            }
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(ModelSortOrder.allCases, id: \.rawValue) { order in
                Button {
                    modelManager.sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if modelManager.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button {
            Task {
                await modelManager.fetchAndCacheModels(context: modelContext)
            }
        } label: {
            if modelManager.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .disabled(modelManager.isLoading)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(.caption, weight: isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModelManagerView(modelManager: ModelManager())
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
