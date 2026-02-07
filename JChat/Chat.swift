   //
   //  Chat.swift
   //  JChat
   //

   import Foundation
   import SwiftData

   @Model
   final class Chat {
       @Attribute(.unique) var id: UUID
       var title: String
       var createdAt: Date
       @Relationship(deleteRule: .cascade) var messages: [Message] = []
       var totalPromptTokens: Int
       var totalCompletionTokens: Int
       var totalCost: Double
       var temperatureOverride: Double?
       var maxTokensOverride: Int?
       
       init(title: String = "New Chat") {
           self.id = UUID()
           self.title = title
           self.createdAt = Date()
           self.totalPromptTokens = 0
           self.totalCompletionTokens = 0
           self.totalCost = 0.0
       }
       
       var totalTokens: Int {
           totalPromptTokens + totalCompletionTokens
       }
   }

   @Model
   final class Message {
       @Attribute(.unique) var id: UUID  // Added for uniqueness
       var role: MessageRole
       var content: String
       var timestamp: Date
       var promptTokens: Int
       var completionTokens: Int
       var cost: Double
       @Relationship(inverse: \Chat.messages) var chat: Chat?
       
       init(role: MessageRole, content: String, promptTokens: Int = 0, completionTokens: Int = 0, cost: Double = 0.0) {
           self.id = UUID()
           self.role = role
           self.content = content
           self.timestamp = Date()
           self.promptTokens = promptTokens
           self.completionTokens = completionTokens
           self.cost = cost
       }
       
       var totalTokens: Int {
           promptTokens + completionTokens
       }
   }

   enum MessageRole: String, Codable {
       case user
       case assistant
       case system
   }
