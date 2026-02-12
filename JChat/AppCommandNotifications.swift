//
//  AppCommandNotifications.swift
//  JChat
//

import Foundation

enum AppCommandNotification {
    static let textSizeIncrease = Notification.Name("JChatTextSizeIncrease")
    static let textSizeDecrease = Notification.Name("JChatTextSizeDecrease")
    static let textSizeReset = Notification.Name("JChatTextSizeReset")
    static let openSettings = Notification.Name("JChatOpenSettings")
    static let newChat = Notification.Name("JChatNewChat")
    static let deleteSelectedChat = Notification.Name("JChatDeleteSelectedChat")
}
