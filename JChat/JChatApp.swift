//
//  JChatApp.swift
//  JChat
//

import SwiftData
import SwiftUI

@main
struct JChatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self,
            AppSettings.self,
            Character.self,
            CachedModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(.ultraThinMaterial)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.automatic)
        .windowResizability(.contentSize)

        #if os(iOS)
            .commands {
                CommandGroup(replacing: .help) {
                    Link("JChat Help", destination: URL(string: "https://jchat.app/help")!)
                }
            }
        #endif

        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    NotificationCenter.default.post(name: AppCommandNotification.newChat, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: AppCommandNotification.openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }

            CommandGroup(after: .textEditing) {
                Button("Zoom In") {
                    NotificationCenter.default.post(name: AppCommandNotification.textSizeIncrease, object: nil)
                }
                .keyboardShortcut("=", modifiers: [.command])

                Button("Zoom Out") {
                    NotificationCenter.default.post(name: AppCommandNotification.textSizeDecrease, object: nil)
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Actual Size") {
                    NotificationCenter.default.post(name: AppCommandNotification.textSizeReset, object: nil)
                }
                .keyboardShortcut("0", modifiers: [.command])
            }

            CommandMenu("Chat") {
                Button("Delete Chat") {
                    NotificationCenter.default.post(name: AppCommandNotification.deleteSelectedChat, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Link("JChat Help", destination: URL(string: "https://jchat.app/help")!)
            }
        }
        #endif
    }
}
