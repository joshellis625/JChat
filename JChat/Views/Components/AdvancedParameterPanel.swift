//
//  AdvancedParameterPanel.swift
//  JChat
//

import SwiftUI
import SwiftData

struct AdvancedParameterPanel: View {
    @Bindable var chat: Chat
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Sampling
                Section("Sampling") {
                    ParameterSliderRow(
                        label: "Temperature",
                        description: "Controls randomness. Higher = more creative, lower = more focused.",
                        value: Binding(
                            get: { chat.temperatureOverride },
                            set: { chat.temperatureOverride = $0 }
                        ),
                        defaultValue: 1.0,
                        range: 0.0...2.0,
                        step: 0.05
                    )

                    ParameterSliderRow(
                        label: "Top P",
                        description: "Nucleus sampling. Considers tokens with cumulative probability up to this value.",
                        value: Binding(
                            get: { chat.topPOverride },
                            set: { chat.topPOverride = $0 }
                        ),
                        defaultValue: 1.0,
                        range: 0.0...1.0,
                        step: 0.05
                    )

                    ParameterIntRow(
                        label: "Top K",
                        description: "Limits to top K tokens. 0 = disabled.",
                        value: Binding(
                            get: { chat.topKOverride },
                            set: { chat.topKOverride = $0 }
                        ),
                        defaultValue: 0,
                        range: 0...500
                    )

                    ParameterSliderRow(
                        label: "Min P",
                        description: "Minimum probability threshold relative to the top token.",
                        value: Binding(
                            get: { chat.minPOverride },
                            set: { chat.minPOverride = $0 }
                        ),
                        defaultValue: 0.0,
                        range: 0.0...1.0,
                        step: 0.05
                    )

                    ParameterSliderRow(
                        label: "Top A",
                        description: "Adaptive sampling threshold.",
                        value: Binding(
                            get: { chat.topAOverride },
                            set: { chat.topAOverride = $0 }
                        ),
                        defaultValue: 0.0,
                        range: 0.0...1.0,
                        step: 0.05
                    )
                }

                // MARK: - Penalties
                Section("Penalties") {
                    ParameterSliderRow(
                        label: "Frequency Penalty",
                        description: "Penalizes tokens based on frequency in the text so far.",
                        value: Binding(
                            get: { chat.frequencyPenaltyOverride },
                            set: { chat.frequencyPenaltyOverride = $0 }
                        ),
                        defaultValue: 0.0,
                        range: -2.0...2.0,
                        step: 0.1
                    )

                    ParameterSliderRow(
                        label: "Presence Penalty",
                        description: "Penalizes tokens based on whether they appear in the text so far.",
                        value: Binding(
                            get: { chat.presencePenaltyOverride },
                            set: { chat.presencePenaltyOverride = $0 }
                        ),
                        defaultValue: 0.0,
                        range: -2.0...2.0,
                        step: 0.1
                    )

                    ParameterSliderRow(
                        label: "Repetition Penalty",
                        description: "Penalizes repeated tokens. 1.0 = no penalty.",
                        value: Binding(
                            get: { chat.repetitionPenaltyOverride },
                            set: { chat.repetitionPenaltyOverride = $0 }
                        ),
                        defaultValue: 1.0,
                        range: 0.0...2.0,
                        step: 0.05
                    )
                }

                // MARK: - Output
                Section("Output") {
                    ParameterIntRow(
                        label: "Max Tokens",
                        description: "Maximum number of tokens to generate.",
                        value: Binding(
                            get: { chat.maxTokensOverride },
                            set: { chat.maxTokensOverride = $0 }
                        ),
                        defaultValue: 4096,
                        range: 1...128000
                    )

                    ParameterToggleRow(
                        label: "Stream",
                        description: "Stream responses token by token.",
                        value: Binding(
                            get: { chat.streamOverride },
                            set: { chat.streamOverride = $0 }
                        ),
                        defaultValue: true
                    )
                }

                // MARK: - Reasoning
                Section {
                    ParameterToggleRow(
                        label: "Enabled",
                        description: "Enable reasoning/thinking for supported models.",
                        value: Binding(
                            get: { chat.reasoningEnabledOverride },
                            set: { chat.reasoningEnabledOverride = $0 }
                        ),
                        defaultValue: true
                    )

                    ParameterPickerRow(
                        label: "Effort",
                        description: "How much reasoning effort to use.",
                        value: Binding(
                            get: { chat.reasoningEffortOverride },
                            set: { chat.reasoningEffortOverride = $0 }
                        ),
                        defaultValue: "medium",
                        options: ["xhigh", "high", "medium", "low", "minimal", "none"]
                    )

                    ParameterIntRow(
                        label: "Max Tokens",
                        description: "Max reasoning tokens. Min 1024, max 128000.",
                        value: Binding(
                            get: { chat.reasoningMaxTokensOverride },
                            set: { chat.reasoningMaxTokensOverride = $0 }
                        ),
                        defaultValue: nil,
                        range: 1024...128000
                    )

                    Text("For Anthropic models, Effort and Max Tokens are mutually exclusive. Setting one disables the other.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ParameterToggleRow(
                        label: "Exclude Output",
                        description: "Exclude reasoning tokens from response output.",
                        value: Binding(
                            get: { chat.reasoningExcludeOverride },
                            set: { chat.reasoningExcludeOverride = $0 }
                        ),
                        defaultValue: false
                    )
                } header: {
                    Text("Reasoning")
                }

                // MARK: - Verbosity
                Section {
                    ParameterPickerRow(
                        label: "Verbosity",
                        description: "Maps to output_config.effort for Claude. Only Opus supports 'max'.",
                        value: Binding(
                            get: { chat.verbosityOverride },
                            set: { chat.verbosityOverride = $0 }
                        ),
                        defaultValue: nil,
                        options: ["low", "medium", "high", "max"]
                    )
                } header: {
                    Text("Verbosity")
                } footer: {
                    Text("Default: nil (medium on OpenRouter)")
                        .font(.caption2)
                }

                // MARK: - Reset
                Section {
                    Button(role: .destructive) {
                        chat.resetAllOverrides()
                        try? modelContext.save()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All Overrides")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Advanced Parameters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Parameter Row Components

private struct ParameterSliderRow: View {
    let label: String
    let description: String
    @Binding var value: Double?
    let defaultValue: Double
    let range: ClosedRange<Double>
    let step: Double

    private var isEnabled: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            value = defaultValue
                        } else {
                            value = nil
                        }
                    }
                )) {
                    Text(label)
                        .font(.body.weight(.medium))
                }
                .toggleStyle(.switch)

                Spacer()

                if isEnabled, let val = value {
                    Text(String(format: "%.2f", val))
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                } else {
                    Text("Default: \(String(format: "%.2f", defaultValue))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            if isEnabled {
                Slider(
                    value: Binding(
                        get: { value ?? defaultValue },
                        set: { value = $0 }
                    ),
                    in: range,
                    step: step
                )
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ParameterIntRow: View {
    let label: String
    let description: String
    @Binding var value: Int?
    let defaultValue: Int?
    let range: ClosedRange<Int>

    private var isEnabled: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            value = defaultValue ?? range.lowerBound
                        } else {
                            value = nil
                        }
                    }
                )) {
                    Text(label)
                        .font(.body.weight(.medium))
                }
                .toggleStyle(.switch)

                Spacer()

                if isEnabled, let val = value {
                    TextField("", value: Binding(
                        get: { val },
                        set: { value = max(range.lowerBound, min(range.upperBound, $0)) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                } else {
                    if let def = defaultValue {
                        Text("Default: \(def)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Off")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ParameterToggleRow: View {
    let label: String
    let description: String
    @Binding var value: Bool?
    let defaultValue: Bool

    private var isEnabled: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            value = defaultValue
                        } else {
                            value = nil
                        }
                    }
                )) {
                    Text(label)
                        .font(.body.weight(.medium))
                }
                .toggleStyle(.switch)

                Spacer()

                if isEnabled, let val = value {
                    Toggle("", isOn: Binding(
                        get: { val },
                        set: { value = $0 }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                } else {
                    Text("Default: \(defaultValue ? "ON" : "OFF")")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ParameterPickerRow: View {
    let label: String
    let description: String
    @Binding var value: String?
    let defaultValue: String?
    let options: [String]

    private var isEnabled: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            value = defaultValue ?? options.first
                        } else {
                            value = nil
                        }
                    }
                )) {
                    Text(label)
                        .font(.body.weight(.medium))
                }
                .toggleStyle(.switch)

                Spacer()

                if isEnabled, let val = value {
                    Picker("", selection: Binding(
                        get: { val },
                        set: { value = $0 }
                    )) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                } else {
                    Text(defaultValue != nil ? "Default: \(defaultValue!)" : "Off")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
