# JChat Development TODO List

## macOS 26 & iOS 26 Compatibility

### Platform Adaptation
- [ ] Update minimum deployment targets to macOS 26.0 and iOS 26.0
- [ ] Create platform-specific conditional compilation directives
- [ ] Verify SwiftUI compatibility with latest APIs

### Liquid Glass Design Implementation
- [ ] Implement GlassBackgroundStyle for main window
- [ ] Add glassmorphism effects to chat bubbles
- [ ] Apply translucency to sidebar and headers
- [ ] Configure blur radius and opacity for glass elements
- [ ] Add subtle gradients and shadows for depth
- [ ] Implement dynamic glass appearance based on wallpaper

### UI/UX Updates per Apple HIG 2026
- [ ] Update typography to San Francisco 2026
- [ ] Implement new SF Symbols 7 icons
- [ ] Apply corner radius specifications for macOS 26
- [ ] Update button and control styles
- [ ] Implement new focus effects
- [ ] Add haptic feedback for iOS interactions

### Cross-Platform UI Adjustments
- [ ] Create size class-based layouts
- [ ] Implement adaptive layout for iPhone/iPad
- [ ] Add platform-specific modifiers:
  - [ ] macOS: .controlSize(), .controlProminence()
  - [ ] iOS: .toolbar(), .navigationBarTitleDisplayMode()
- [ ] Update keyboard shortcuts for macOS 26
- [ ] Configure contextual menus per platform

### SwiftData Migration
- [ ] Update SwiftData models for iOS 26 compatibility
- [ ] Test cloud synchronization features
- [ ] Verify persistence across platforms

## Model & API Updates
- [ ] Update OpenRouter API endpoint for latest version
- [ ] Add new model configurations
- [ ] Update pricing table
- [ ] Test API changes on both platforms

## Testing & Documentation
- [ ] Create iOS-specific preview providers
- [ ] Add macOS-specific preview providers
- [ ] Update AGENTS.md with platform compatibility
- [ ] Document Liquid Glass implementation
- [ ] Test using Swift Testing 2026 framework

## Build & Distribution
- [ ] Update app icons for macOS 26 and iOS 26
- [ ] Configure universal builds
- [ ] Test app store submission requirements
- [ ] Update privacy manifest for iOS 26
