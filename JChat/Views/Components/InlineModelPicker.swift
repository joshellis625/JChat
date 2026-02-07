//
//  InlineModelPicker.swift
//  JChat
//

import SwiftUI
import SwiftData

struct InlineModelPicker: View {
    @Binding var selectedModelID: String?
    @Bindable var modelManager: ModelManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingPopover = false
    @State private var showingFullManager = false
    @State private var pickerSearchText = ""

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.caption)
                Text(selectedModelName)
                    .font(.caption)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            pickerPopover
        }
        .sheet(isPresented: $showingFullManager) {
            ModelManagerView(modelManager: modelManager)
        }
    }

    // MARK: - Selected Model Name

    private var selectedModelName: String {
        guard let id = selectedModelID else { return "Select Model" }
        if let model = modelManager.filteredModels.first(where: { $0.id == id }) ?? modelManager.favoriteModels.first(where: { $0.id == id }) {
            return model.displayName
        }
        // Fallback: show the ID in a readable form
        if let slashIndex = id.lastIndex(of: "/") {
            return String(id[id.index(after: slashIndex)...])
        }
        return id
    }

    // MARK: - Popover Content

    private var pickerPopover: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search models...", text: $pickerSearchText)
                    .textFieldStyle(.plain)
                if !pickerSearchText.isEmpty {
                    Button {
                        pickerSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.bar)

            Divider()

            // Model list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Favorites section
                    let favorites = filteredFavorites
                    if !favorites.isEmpty {
                        sectionHeader("Favorites")
                        ForEach(favorites, id: \.id) { model in
                            modelPickerRow(model)
                        }
                        Divider()
                            .padding(.vertical, 4)
                    }

                    // All models section
                    let allFiltered = filteredAllModels
                    if !allFiltered.isEmpty {
                        sectionHeader("All Models")
                        ForEach(allFiltered, id: \.id) { model in
                            modelPickerRow(model)
                        }
                    } else if !pickerSearchText.isEmpty {
                        Text("No models match \"\(pickerSearchText)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .frame(maxHeight: 350)

            Divider()

            // Browse All button
            Button {
                showingPopover = false
                showingFullManager = true
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("Browse All Models...")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 320)
    }

    // MARK: - Filtered Lists

    private var filteredFavorites: [CachedModel] {
        let favorites = modelManager.favoriteModels
        if pickerSearchText.isEmpty { return favorites }
        let query = pickerSearchText.lowercased()
        return favorites.filter {
            $0.name.lowercased().contains(query) ||
            $0.id.lowercased().contains(query) ||
            $0.providerName.lowercased().contains(query)
        }
    }

    private var filteredAllModels: [CachedModel] {
        let all = modelManager.filteredModels
        if pickerSearchText.isEmpty { return Array(all.prefix(50)) } // Limit for performance
        let query = pickerSearchText.lowercased()
        return all.filter {
            $0.name.lowercased().contains(query) ||
            $0.id.lowercased().contains(query) ||
            $0.providerName.lowercased().contains(query)
        }
    }

    // MARK: - Row Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func modelPickerRow(_ model: CachedModel) -> some View {
        Button {
            selectedModelID = model.id
            showingPopover = false
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(model.displayName)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)

                        if model.isFree {
                            BadgeCapsule(text: "FREE", color: .green)
                        }
                    }

                    Text(model.providerName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.id == selectedModelID {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }

                Text(model.contextLengthFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(model.id == selectedModelID ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}

#Preview {
    InlineModelPicker(
        selectedModelID: .constant("anthropic/claude-sonnet-4"),
        modelManager: ModelManager()
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
