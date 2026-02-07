//
//  ContentView.swift
//  JChat
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            ChatListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            ConversationView(viewModel: viewModel)
        }
        .toolbar {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Chat.self, Message.self, APISettings.self], inMemory: true)
}
