//
//  ContentView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @State private var modelManager = ModelManager()
    @State private var showingSettings = false
    @State private var showingModelManager = false
    @State private var showingCharacters = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            ChatListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            ConversationView(viewModel: viewModel, modelManager: modelManager)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingCharacters = true
                } label: {
                    Label("Characters", systemImage: "person.2")
                }
            }
            ToolbarItem {
                Button {
                    showingModelManager = true
                } label: {
                    Label("Model Manager", systemImage: "server.rack")
                }
            }
            ToolbarItem {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingModelManager) {
            ModelManagerView(modelManager: modelManager)
        }
        .sheet(isPresented: $showingCharacters) {
            CharacterListView(modelManager: modelManager)
        }
        .task {
            await modelManager.refreshIfStale(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
