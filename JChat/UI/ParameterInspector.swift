//
//  ParameterInspector.swift
//  JChat
//

import SwiftData
import SwiftUI

// MARK: - Default values (source of truth for "is this overridden?")

private enum ParameterDefaults {
    static let temperature: Double = 1.0
    static let maxTokens: Int = 0 // 0 = unlimited / Off
    static let topP: Double = 1.0
    static let topK: Int = 0 // 0 = Off
    static let minP: Double = 0.0
    static let topA: Double = 0.0
    static let frequencyPenalty: Double = 0.0
    static let presencePenalty: Double = 0.0
    static let repetitionPenalty: Double = 1.0
    static let reasoningEnabled: Bool = true
    static let reasoningEffort: String = "medium"
    static let reasoningMaxTokens: Int = 0 // 0 = unlimited / Off
    static let reasoningExclude: Bool = false
    static let verbosity: String = "medium"
}

// MARK: - Keyboard-editable numeric field

/// A TextField that buffers string input and only commits on blur/submit,
/// preventing the "stuck single digit" bug from live-binding to numeric types.
private struct NumberField<T: Numeric & Comparable>: View {
    let label: String
    @Binding var value: T
    let range: ClosedRange<T>
    let format: (T) -> String
    let parse: (String) -> T?

    @Environment(\.textBaseSize) private var textBaseSize
    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $draft)
            .focused($focused)
            .multilineTextAlignment(.trailing)
            .frame(width: 62)
            .font(.system(size: TextSizeConfig.scaled(13, base: textBaseSize), weight: .regular, design: .monospaced))
            .foregroundStyle(.primary)
            .onAppear { draft = format(value) }
            .onChange(of: value) { _, newVal in
                if !focused { draft = format(newVal) }
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { commit() }
            }
            .onSubmit { commit(); focused = false }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if let parsed = parse(trimmed) {
            let clamped: T = parsed < range.lowerBound ? range.lowerBound
                : parsed > range.upperBound ? range.upperBound
                : parsed
            value = clamped
            draft = format(clamped)
        } else {
            // Restore to current value if unparseable
            draft = format(value)
        }
    }
}

// MARK: - Slider row (label + value display + slider + text field)

private struct SliderRow: View {
    let title: String
    let isOverridden: Bool
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatValue: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                paramLabel(title, isOverridden: isOverridden)
                Spacer()
                NumberField(
                    label: title,
                    value: $value,
                    range: range,
                    format: formatValue,
                    parse: { Double($0) }
                )
            }
            Slider(value: $value, in: range, step: step)
                .tint(.accentColor)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Int slider row (for Top K and token counts)

private struct IntSliderRow: View {
    let title: String
    let isOverridden: Bool
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let zeroLabel: String? // if set, display this instead of "0"

    private var doubleBinding: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { value = Int($0.rounded()) }
        )
    }

    var displayValue: String {
        if value == 0, let zeroLabel { return zeroLabel }
        return "\(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                paramLabel(title, isOverridden: isOverridden)
                Spacer()
                NumberField(
                    label: title,
                    value: $value,
                    range: range.lowerBound ... range.upperBound,
                    format: { v in
                        if v == 0, let zeroLabel { return zeroLabel }
                        return "\(v)"
                    },
                    parse: { s in
                        if let zeroLabel, s.lowercased() == zeroLabel.lowercased() { return 0 }
                        return Int(s)
                    }
                )
            }
            Slider(value: doubleBinding, in: Double(range.lowerBound) ... Double(range.upperBound), step: Double(step))
                .tint(.accentColor)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Label helper

@ViewBuilder
private func paramLabel(_ name: String, isOverridden: Bool) -> some View {
    HStack(spacing: 5) {
        Text(name)
            .appFont(.subheadline, weight: .medium)
            .foregroundStyle(.primary)
        if isOverridden {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Parameter Inspector

struct ParameterInspector: View {
    @Bindable var chat: Chat
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            // Reset button at the top
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    chat.resetAllOverrides()
                    saveQuiet()
                }
                .frame(maxWidth: .infinity)
            }

            basicSection
            samplingSection
            penaltiesSection
            reasoningSection
        }
        .formStyle(.grouped)
        .frame(width: 300)
    }

    // MARK: - Basic

    private var basicSection: some View {
        Section("Basic") {
            SliderRow(
                title: "Temperature",
                isOverridden: chat.temperatureOverride != nil && chat.temperatureOverride != ParameterDefaults.temperature,
                value: Binding(
                    get: { chat.effectiveTemperature },
                    set: { newVal in
                        chat.temperatureOverride = (newVal == ParameterDefaults.temperature) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 2,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )

            IntSliderRow(
                title: "Max Tokens",
                isOverridden: chat.maxTokensOverride != nil && chat.maxTokensOverride != ParameterDefaults.maxTokens,
                value: Binding(
                    get: { chat.effectiveMaxTokens },
                    set: { newVal in
                        chat.maxTokensOverride = (newVal == ParameterDefaults.maxTokens) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 32768,
                step: 256,
                zeroLabel: "Off"
            )
        }
    }

    // MARK: - Sampling

    private var samplingSection: some View {
        Section("Sampling") {
            SliderRow(
                title: "Top P",
                isOverridden: chat.topPOverride != nil && chat.topPOverride != ParameterDefaults.topP,
                value: Binding(
                    get: { chat.effectiveTopP },
                    set: { newVal in
                        chat.topPOverride = (newVal == ParameterDefaults.topP) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 1,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )

            IntSliderRow(
                title: "Top K",
                isOverridden: chat.topKOverride != nil && chat.topKOverride != ParameterDefaults.topK,
                value: Binding(
                    get: { chat.effectiveTopK },
                    set: { newVal in
                        chat.topKOverride = (newVal == ParameterDefaults.topK) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 200,
                step: 1,
                zeroLabel: "Off"
            )

            SliderRow(
                title: "Min P",
                isOverridden: chat.minPOverride != nil && chat.minPOverride != ParameterDefaults.minP,
                value: Binding(
                    get: { chat.effectiveMinP },
                    set: { newVal in
                        chat.minPOverride = (newVal == ParameterDefaults.minP) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 1,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )

            SliderRow(
                title: "Top A",
                isOverridden: chat.topAOverride != nil && chat.topAOverride != ParameterDefaults.topA,
                value: Binding(
                    get: { chat.effectiveTopA },
                    set: { newVal in
                        chat.topAOverride = (newVal == ParameterDefaults.topA) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 1,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )
        }
    }

    // MARK: - Penalties

    private var penaltiesSection: some View {
        Section("Penalties") {
            SliderRow(
                title: "Frequency",
                isOverridden: chat.frequencyPenaltyOverride != nil && chat.frequencyPenaltyOverride != ParameterDefaults.frequencyPenalty,
                value: Binding(
                    get: { chat.effectiveFrequencyPenalty },
                    set: { newVal in
                        chat.frequencyPenaltyOverride = (newVal == ParameterDefaults.frequencyPenalty) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 2,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )

            SliderRow(
                title: "Presence",
                isOverridden: chat.presencePenaltyOverride != nil && chat.presencePenaltyOverride != ParameterDefaults.presencePenalty,
                value: Binding(
                    get: { chat.effectivePresencePenalty },
                    set: { newVal in
                        chat.presencePenaltyOverride = (newVal == ParameterDefaults.presencePenalty) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0 ... 2,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )

            SliderRow(
                title: "Repetition",
                isOverridden: chat.repetitionPenaltyOverride != nil && chat.repetitionPenaltyOverride != ParameterDefaults.repetitionPenalty,
                value: Binding(
                    get: { chat.effectiveRepetitionPenalty },
                    set: { newVal in
                        chat.repetitionPenaltyOverride = (newVal == ParameterDefaults.repetitionPenalty) ? nil : newVal
                        saveQuiet()
                    }
                ),
                range: 0.5 ... 2,
                step: 0.05,
                formatValue: { String(format: "%.2f", $0) }
            )
        }
    }

    // MARK: - Reasoning

    private var reasoningSection: some View {
        Section("Reasoning") {
            Toggle(isOn: Binding(
                get: { chat.effectiveReasoningEnabled },
                set: { newVal in
                    chat.reasoningEnabledOverride = (newVal == ParameterDefaults.reasoningEnabled) ? nil : newVal
                    saveQuiet()
                }
            )) {
                paramLabel("Reasoning", isOverridden: chat.reasoningEnabledOverride != nil && chat.reasoningEnabledOverride != ParameterDefaults.reasoningEnabled)
            }

            // Reasoning Effort (segmented, mutually exclusive with Reasoning Max Tokens)
            LabeledContent {
                Picker("", selection: Binding(
                    get: { chat.reasoningEffortOverride ?? ParameterDefaults.reasoningEffort },
                    set: { newVal in
                        chat.reasoningEffortOverride = (newVal == ParameterDefaults.reasoningEffort) ? nil : newVal
                        chat.reasoningMaxTokensOverride = nil // mutually exclusive
                        saveQuiet()
                    }
                )) {
                    Text("Low").tag("low")
                    Text("Med").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            } label: {
                paramLabel("Effort", isOverridden: chat.reasoningEffortOverride != nil && chat.reasoningEffortOverride != ParameterDefaults.reasoningEffort)
            }

            // Reasoning Max Tokens (mutually exclusive with Effort)
            IntSliderRow(
                title: "Rsn Tokens",
                isOverridden: chat.reasoningMaxTokensOverride != nil && chat.reasoningMaxTokensOverride != ParameterDefaults.reasoningMaxTokens,
                value: Binding(
                    get: { chat.reasoningMaxTokensOverride ?? ParameterDefaults.reasoningMaxTokens },
                    set: { newVal in
                        if newVal == ParameterDefaults.reasoningMaxTokens {
                            chat.reasoningMaxTokensOverride = nil
                        } else {
                            chat.reasoningMaxTokensOverride = newVal
                            chat.reasoningEffortOverride = nil // mutually exclusive
                        }
                        saveQuiet()
                    }
                ),
                range: 0 ... 32000,
                step: 256,
                zeroLabel: "Off"
            )

            Toggle(isOn: Binding(
                get: { chat.effectiveReasoningExclude ?? ParameterDefaults.reasoningExclude },
                set: { newVal in
                    chat.reasoningExcludeOverride = (newVal == ParameterDefaults.reasoningExclude) ? nil : newVal
                    saveQuiet()
                }
            )) {
                paramLabel("Exclude from Output", isOverridden: chat.reasoningExcludeOverride != nil && chat.reasoningExcludeOverride != ParameterDefaults.reasoningExclude)
            }

            // Verbosity — segmented picker matching Effort style
            LabeledContent {
                Picker("", selection: Binding(
                    get: { chat.verbosityOverride ?? ParameterDefaults.verbosity },
                    set: { newVal in
                        chat.verbosityOverride = (newVal == ParameterDefaults.verbosity) ? nil : newVal
                        saveQuiet()
                    }
                )) {
                    Text("Low").tag("low")
                    Text("Med").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            } label: {
                paramLabel("Verbosity", isOverridden: chat.verbosityOverride != nil && chat.verbosityOverride != ParameterDefaults.verbosity)
            }
        }
    }

    // MARK: - Helpers

    private func saveQuiet() {
        try? modelContext.save()
    }
}
