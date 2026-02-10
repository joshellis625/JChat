//
//  AdvancedParameterPanel.swift
//  JChat
//

import SwiftUI
import SwiftData

//TODO - This entire window/panel and design needs to be dramatically overhauled and improved. It's very ugly and confusing.
struct AdvancedParameterPanel: View {
    @Bindable var chat: Chat
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Advanced Parameters")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        HStack(spacing: 6) {
                            Text("Overrides")
                                .font(.system(size: 13, weight: .semibold))
                            Text("\(chat.overrideCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Button(role: .destructive) {
                            chat.resetAllOverrides()
                            try? modelContext.save()
                        } label: {
                            Text("Reset All")
                        }
                        .controlSize(.small)
                    }

                    Text("Overrides apply to this chat only and fall back to global defaults when disabled.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    // MARK: - Sampling
                    ParamSection("Sampling") {
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
                    ParamSection("Penalties") {
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
                    ParamSection("Output") {
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
                    ParamSection("Reasoning") {
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

                        Text("For Anthropic models, Effort and Max Tokens are mutually exclusive.")
                            .font(.system(size: 11))
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
                    }

                    // MARK: - Verbosity
                    ParamSection("Verbosity") {
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

                        Text("Default: nil (medium on OpenRouter)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .frame(idealWidth: 520, idealHeight: 650)
        .frame(minWidth: 450, minHeight: 400)
    }
}

// MARK: - Section Container

private struct ParamSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(12)
            .background(Color(.controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    AdvancedParameterPanel(chat: Chat(title: "Preview Chat"))
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { value = $0 ? defaultValue : nil }
                )) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if isEnabled, let val = value {
                    Text(String(format: "%.2f", val))
                        .font(.system(size: 13).monospaced())
                        .foregroundStyle(.primary)
                } else {
                    Text("Default: \(String(format: "%.2f", defaultValue))")
                        .font(.system(size: 12).monospaced())
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
                .font(.system(size: 11))
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

    @State private var textValue: String = ""
    private var isEnabled: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            let def = defaultValue ?? range.lowerBound
                            value = def
                            textValue = "\(def)"
                        } else {
                            value = nil
                            textValue = ""
                        }
                    }
                )) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if isEnabled {
                    TextField("", text: $textValue)
                        .font(.system(size: 13).monospaced())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { commitTextValue() }
                        .onChange(of: textValue) { _, newVal in
                            if newVal.isEmpty { return }
                            let filtered = newVal.filter { $0.isNumber }
                            if filtered != newVal { textValue = filtered }
                        }
                } else {
                    if let def = defaultValue {
                        Text("Default: \(def)")
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Off")
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if let val = value { textValue = "\(val)" }
        }
        .onChange(of: value) { _, newVal in
            if let newVal {
                let str = "\(newVal)"
                if textValue != str { textValue = str }
            }
        }
    }

    private func commitTextValue() {
        if let parsed = Int(textValue) {
            value = max(range.lowerBound, min(range.upperBound, parsed))
        } else {
            let fallback = value ?? defaultValue ?? range.lowerBound
            value = fallback
            textValue = "\(fallback)"
        }
    }
}

private struct ParameterToggleRow: View {
    let label: String
    let description: String
    @Binding var value: Bool?
    let defaultValue: Bool

    private var effectiveValue: Bool { value ?? defaultValue }
    private var isOverridden: Bool { value != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                if isOverridden {
                    Button("Default") {
                        value = nil
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                }

                Toggle("", isOn: Binding(
                    get: { effectiveValue },
                    set: { value = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            }

            Text(description)
                .font(.system(size: 11))
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { value = $0 ? (defaultValue ?? options.first) : nil }
                )) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

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
                    .frame(width: 130)
                } else {
                    Text(defaultValue != nil ? "Default: \(defaultValue!)" : "Off")
                        .font(.system(size: 12).monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
