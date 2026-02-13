//
//  V2ParameterInspector.swift
//  JChat
//

import SwiftUI
import SwiftData

// MARK: - Parameter Inspector View

struct V2ParameterInspector: View {
    @Bindable var chat: Chat
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            basicSection
            samplingSection
            penaltiesSection
            reasoningSection
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    chat.resetAllOverrides()
                    try? modelContext.save()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Parameters")
    }

    // MARK: - Basic

    private var basicSection: some View {
        Section("Basic") {
            // Temperature
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveTemperature))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.temperatureOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveTemperature },
                            set: { chat.temperatureOverride = $0; saveQuiet() }
                        ),
                        in: 0...2,
                        step: 0.01
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Temperature", isOverridden: chat.temperatureOverride != nil)
            }

            // Max Tokens
            LabeledContent {
                Stepper(
                    value: Binding(
                        get: { chat.effectiveMaxTokens },
                        set: { chat.maxTokensOverride = $0; saveQuiet() }
                    ),
                    in: 256...32768,
                    step: 256
                ) {
                    Text("\(chat.effectiveMaxTokens)")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.maxTokensOverride != nil ? .primary : .secondary)
                }
            } label: {
                paramLabel("Max Tokens", isOverridden: chat.maxTokensOverride != nil)
            }

            // Stream
            Toggle(isOn: Binding(
                get: { chat.effectiveStream },
                set: { chat.streamOverride = $0; saveQuiet() }
            )) {
                paramLabel("Stream", isOverridden: chat.streamOverride != nil)
            }
        }
    }

    // MARK: - Sampling

    private var samplingSection: some View {
        Section("Sampling") {
            // Top P
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveTopP))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.topPOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveTopP },
                            set: { chat.topPOverride = $0; saveQuiet() }
                        ),
                        in: 0...1
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Top P", isOverridden: chat.topPOverride != nil)
            }

            // Top K
            LabeledContent {
                Stepper(
                    value: Binding(
                        get: { chat.effectiveTopK },
                        set: { chat.topKOverride = $0; saveQuiet() }
                    ),
                    in: 0...200,
                    step: 1
                ) {
                    Text("\(chat.effectiveTopK)")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.topKOverride != nil ? .primary : .secondary)
                }
            } label: {
                paramLabel("Top K", isOverridden: chat.topKOverride != nil)
            }

            // Min P
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveMinP))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.minPOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveMinP },
                            set: { chat.minPOverride = $0; saveQuiet() }
                        ),
                        in: 0...1
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Min P", isOverridden: chat.minPOverride != nil)
            }

            // Top A
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveTopA))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.topAOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveTopA },
                            set: { chat.topAOverride = $0; saveQuiet() }
                        ),
                        in: 0...1
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Top A", isOverridden: chat.topAOverride != nil)
            }
        }
    }

    // MARK: - Penalties

    private var penaltiesSection: some View {
        Section("Penalties") {
            // Frequency Penalty
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveFrequencyPenalty))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.frequencyPenaltyOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveFrequencyPenalty },
                            set: { chat.frequencyPenaltyOverride = $0; saveQuiet() }
                        ),
                        in: 0...2
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Frequency", isOverridden: chat.frequencyPenaltyOverride != nil)
            }

            // Presence Penalty
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectivePresencePenalty))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.presencePenaltyOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectivePresencePenalty },
                            set: { chat.presencePenaltyOverride = $0; saveQuiet() }
                        ),
                        in: 0...2
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Presence", isOverridden: chat.presencePenaltyOverride != nil)
            }

            // Repetition Penalty
            LabeledContent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", chat.effectiveRepetitionPenalty))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(chat.repetitionPenaltyOverride != nil ? .primary : .secondary)
                    Slider(
                        value: Binding(
                            get: { chat.effectiveRepetitionPenalty },
                            set: { chat.repetitionPenaltyOverride = $0; saveQuiet() }
                        ),
                        in: 0.5...2
                    )
                    .frame(width: 140)
                }
            } label: {
                paramLabel("Repetition", isOverridden: chat.repetitionPenaltyOverride != nil)
            }
        }
    }

    // MARK: - Reasoning

    private var reasoningSection: some View {
        Section("Reasoning") {
            // Reasoning Enabled
            Toggle(isOn: Binding(
                get: { chat.effectiveReasoningEnabled },
                set: { chat.reasoningEnabledOverride = $0; saveQuiet() }
            )) {
                paramLabel("Reasoning", isOverridden: chat.reasoningEnabledOverride != nil)
            }

            if chat.effectiveReasoningEnabled {
                // Reasoning Effort (mutually exclusive with Max Tokens)
                LabeledContent {
                    Picker("", selection: Binding(
                        get: { chat.reasoningEffortOverride ?? "medium" },
                        set: {
                            chat.reasoningEffortOverride = $0
                            // Mutually exclusive with max tokens
                            chat.reasoningMaxTokensOverride = nil
                            saveQuiet()
                        }
                    )) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                } label: {
                    paramLabel("Effort", isOverridden: chat.reasoningEffortOverride != nil)
                }

                // Reasoning Max Tokens (mutually exclusive with Effort)
                LabeledContent {
                    Stepper(
                        value: Binding(
                            get: { chat.reasoningMaxTokensOverride ?? 0 },
                            set: {
                                if $0 == 0 {
                                    chat.reasoningMaxTokensOverride = nil
                                } else {
                                    chat.reasoningMaxTokensOverride = $0
                                    // Mutually exclusive with effort
                                    chat.reasoningEffortOverride = nil
                                }
                                saveQuiet()
                            }
                        ),
                        in: 0...32000,
                        step: 256
                    ) {
                        let value = chat.reasoningMaxTokensOverride ?? 0
                        Text(value == 0 ? "Off" : "\(value)")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(chat.reasoningMaxTokensOverride != nil ? .primary : .secondary)
                    }
                } label: {
                    paramLabel("Max Tokens", isOverridden: chat.reasoningMaxTokensOverride != nil)
                }

                // Reasoning Exclude
                Toggle(isOn: Binding(
                    get: { chat.effectiveReasoningExclude ?? false },
                    set: { chat.reasoningExcludeOverride = $0; saveQuiet() }
                )) {
                    paramLabel("Exclude from Output", isOverridden: chat.reasoningExcludeOverride != nil)
                }
            }

            // Verbosity
            LabeledContent {
                Picker("", selection: Binding(
                    get: { chat.effectiveVerbosity ?? "" },
                    set: { chat.verbosityOverride = $0.isEmpty ? nil : $0; saveQuiet() }
                )) {
                    Text("Default").tag("")
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.menu)
            } label: {
                paramLabel("Verbosity", isOverridden: chat.verbosityOverride != nil)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func paramLabel(_ name: String, isOverridden: Bool) -> some View {
        HStack(spacing: 5) {
            Text(name)
            if isOverridden {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func saveQuiet() {
        try? modelContext.save()
    }
}

// MARK: - Inspector Trigger Button

struct V2ParameterInspectorButton: View {
    @Bindable var chat: Chat
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isPresented ? Color.accentColor : .secondary)

                if chat.overrideCount > 0 {
                    Text("\(chat.overrideCount)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -6)
                }
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help("Chat Parameters")
    }
}
