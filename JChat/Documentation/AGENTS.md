# JChat - AI Chat Client for macOS & iOS

## Project Overview

JChat is a universal Apple platform chat application (targeting macOS 26 and iOS 26) built with SwiftUI and SwiftData. It provides a single-window interface for conversing with Large Language Models (LLMs) through the OpenRouter.ai API, featuring real-time token usage tracking and cost estimation.

## Platform Support

### macOS 26 Tahoe
- Native app targeting macOS 26.0+
- Liquid Glass design with translucency
- Single window architecture using NavigationSplitView
- Native keyboard shortcuts and contextual menus
- Universal controls and focus effects

### iOS 26
- Universal iOS app targeting iOS 26.0+
- Adaptive layout for iPhone and iPad
- Dynamic Island integration for notifications
- Haptic feedback and gesture support
- Native navigation patterns

## Liquid Glass Design Implementation

### Visual Style
- **Background**: Glass background effect with blur radius (20pt)
- **Transparency**: System ultra-thin material for secondary UI
- **Depth**: Subtle shadows and glows for elevation
- **Color**: Dynamic color adaptation based on wallpaper
- **Lighting**: Acrylic effects with light direction awareness

### UI Components
- **Chat Bubbles**: Semi-transparent with glowing borders
- **Sidebar**: Translucent background with frosted effect
- **Headers**: Glass panels with gradient overlays
- **Controls**: Beveled buttons with light refraction

## Core Requirements

1. **Universal Architecture**: Adaptive UI for both platforms
2. **OpenRouter Integration**: Direct API integration with OpenRouter.ai for multi-model LLM access
3. **Cost Transparency**: Real-time token counting and cost estimation per message and cumulative per chat
4. **Parameter Control**: Adjustable inference parameters (temperature, max tokens) per request
5. **Persistent Storage**: Local storage of chat history using SwiftData with cloud sync
6. **Secure API Key Management**: API keys stored in platform keychain

## Architecture

### Design Patterns
- **MVVM**: ViewModels handle business logic and state management
- **Actor-based Concurrency**: Network service and Keychain access isolated to actors for thread safety
- **Repository Pattern**: SwiftData models act as local repositories with cloud synchronization

### Key Components

#### Models (SwiftData)
- **Chat**: Container for conversations
  - Tracks aggregate statistics: `totalPromptTokens`, `totalCompletionTokens`, `totalCost`
  - Per-chat overrides: `temperatureOverride`, `maxTokensOverride` (optional, falls back to global settings)
  - Cascade delete messages when chat is deleted
- **Message**: Individual chat message
  - Role: `.user`, `.assistant`, `.system`
  - Metadata: `promptTokens`, `completionTokens`, `cost`, `timestamp`
- **APISettings**: Global application preferences (NOT API key storage)
  - Default model selection
  - Default parameters: temperature, maxTokens, topP, frequencyPenalty, presencePenalty
  - API key is NOT stored here - use KeychainManager directly

#### Service Layer
- **OpenRouterService**: Actor-based singleton for API communication
  - Endpoint: `https://openrouter.ai/api/v1/chat/completions`
  - Pricing hardcoded in `modelPricing` dictionary (per 1M tokens)
  - Loads API key from Keychain internally (don't pass it in)
  - Returns usage statistics for cost calculation
- **KeychainManager**: Actor-based singleton for secure API key storage
  - Service identifier: `com.jchat.openrouter` (update existing implementation from `com.josh.jchat` for consistency)
  - Account: `apiKey`
  - Accessibility: `kSecAttrAccessibleWhenUnlocked`

#### Views (Platform Adaptive)
- **ContentView**: Root view with adaptive layout
  - macOS: NavigationSplitView with glass background
  - iOS: NavigationStack with tab bar
- **ChatListView**: Adaptive sidebar/list
  - macOS: Translucent sidebar with glass effect
  - iOS: List with context menus
- **ConversationView**: Main chat interface
  - Scrollable message history with auto-scroll to bottom
  - Cost header showing running totals
  - Input area with parameter controls
  - Error message display
- **MessageBubble**: Liquid Glass message renderer
  - User: Glass blue background with glow
  - Assistant: Glass gray background with token/cost metadata
- **MessageInputView**: Input area with expandable parameter controls
  - Growing text editor with glass background
  - Send button with loading state
  - Platform-specific keyboard handling
- **CostHeaderView**: Running totals display with glass panel
- **SettingsView**: API configuration sheet
  - Secure API key entry (stored to Keychain, never SwiftData)
  - Model selection dropdown
  - Default parameter configuration

### Security Model
- **API Keys**: Stored in platform keychain
  - Never store in SwiftData, UserDefaults, Core Data, or files
  - Never log to console or analytics
  - Never include in crash reports
- **Accessibility**: `kSecAttrAccessibleWhenUnlocked` (keychain item unavailable when device locked)

## Implementation Notes (Based on Codebase Scan)
- **Completed**: APISettings model, KeychainManager (needs service update), basic test setup.
- **Missing**: Chat/Message models, OpenRouterService, all views, main app struct. Prioritize these for Phase 1.
- **GitHub Integration**: Use branches for features (e.g., `feature/models`). Reference issues in commits (e.g., "Fixes #42: Implement Chat model").

## Platform-Specific Adaptations

### macOS 26
```swift
#if os(macOS)
// Glass background effect
.glassBackgroundEffect()
.backgroundEffect(.systemUltraThinMaterial)

// Window management
.windowStyle(.automatic)
.commands {
    CommandMenu("JChat") {
        Button("New Chat") { }
        Button("Settings") { }
    }
}
#endif

