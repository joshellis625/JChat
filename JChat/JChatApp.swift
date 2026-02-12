//
//  JChatApp.swift
//  JChat
//

import SwiftUI
import SwiftData

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
            CommandGroup(after: .textEditing) {
                Button("Zoom In") {
                    NotificationCenter.default.post(
                        name: Notification.Name("JChatTextSizeIncrease"),
                        object: nil
                    )
                }
                .keyboardShortcut("=", modifiers: [.command])

                Button("Zoom Out") {
                    NotificationCenter.default.post(
                        name: Notification.Name("JChatTextSizeDecrease"),
                        object: nil
                    )
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Actual Size") {
                    NotificationCenter.default.post(
                        name: Notification.Name("JChatTextSizeReset"),
                        object: nil
                    )
                }
                .keyboardShortcut("0", modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Link("JChat Help", destination: URL(string: "https://jchat.app/help")!)
            }
        }
        #endif
    }
}
