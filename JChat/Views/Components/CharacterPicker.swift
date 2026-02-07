//
//  CharacterPicker.swift
//  JChat
//

import SwiftUI
import SwiftData

struct CharacterPicker: View {
    @Binding var selectedCharacter: Character?
    @Bindable var modelManager: ModelManager

    @Query(sort: \Character.createdAt, order: .reverse) private var characters: [Character]

    @State private var showingPopover = false
    @State private var showingCharacterList = false

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 13))
                Text(selectedCharacter?.name ?? "No Character")
                    .font(.system(size: 13))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            pickerPopover
        }
        .sheet(isPresented: $showingCharacterList) {
            CharacterListView(modelManager: modelManager)
        }
    }

    // MARK: - Popover

    private var pickerPopover: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // "None" option
                    Button {
                        selectedCharacter = nil
                        showingPopover = false
                    } label: {
                        HStack {
                            Text("None")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if selectedCharacter == nil {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(selectedCharacter == nil ? Color.accentColor.opacity(0.1) : Color.clear)

                    Divider()
                        .padding(.vertical, 4)

                    // Characters list
                    ForEach(characters) { character in
                        Button {
                            selectedCharacter = character
                            showingPopover = false
                        } label: {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(character.name)
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                        if character.isDefault {
                                            BadgeCapsule(text: "DEFAULT", color: .blue)
                                        }
                                    }

                                    if !character.systemPrompt.isEmpty {
                                        Text(character.systemPrompt)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                if selectedCharacter?.id == character.id {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(selectedCharacter?.id == character.id ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                }
            }
            .frame(maxHeight: 250)

            Divider()

            // Manage Characters button
            Button {
                showingPopover = false
                showingCharacterList = true
            } label: {
                HStack {
                    Image(systemName: "person.2")
                    Text("Manage Characters...")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 13))
                .padding(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 280)
    }
}

#Preview {
    CharacterPicker(
        selectedCharacter: .constant(nil),
        modelManager: ModelManager()
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
    .padding()
}
