import SwiftUI
import WordPressUI
import DesignSystem

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26, *)
struct PostSettingsGenerateExcerptView: View {
    let postContent: String
    let onSelection: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage("jetpack_ai_generated_excerpt_style")
    private var style: GenerationStyle = .engaging

    @AppStorage("jetpack_ai_generated_excerpt_length")
    private var length: GeneratedContentLength = .medium

    @State private var excerpts: [GeneratedExcerpt] = []
    @State private var isFirstResult = true
    @State private var isGenerating = false
    @State private var error: Error?
    @State private var generationTask: Task<Void, Never>?
    @State private var debounceTask: Task<Void, Never>?

    private var testScenario: TestScenario?

    init(postContent: String, onSelection: @escaping (String) -> Void) {
        self.postContent = postContent
        self.onSelection = onSelection
    }

    var body: some View {
        contentView
            .navigationTitle(Strings.generateExcerptTitle)
            .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let testScenario {
                setupTestScenario(testScenario)
            } else {
                generateExcerpts()
            }
        }
        .onDisappear {
            cancelAllTasks()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isGenerating && excerpts.isEmpty {
                    ProgressView()
                        .scaleEffect(x: 0.9, y: 0.9)
                        .padding()
                        .padding(.top, 4)
                        .padding(.leading, 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if let error {
                    EmptyStateView.failure(error: error)
                        .frame(minHeight: 460)
                } else {
                    results
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingControlPanel
        }
    }

    private var results: some View {
        ForEach(Array(excerpts.enumerated()), id: \.offset) { index, excerpt in
            VStack(spacing: 0) {
                Button(action: {
                    cancelAllTasks()
                    onSelection(excerpt.content)
                    dismiss()
                }) {
                    ExcerptOptionView(index: index, excerpt: excerpt)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .buttonStyle(.plain)

                if index < excerpts.count - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Controls

    private var floatingControlPanel: some View {
        VStack(spacing: 12) {
            lengthPicker
            stylePicker
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text(Strings.lengthLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "textformat.size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(length.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(length.rawValue) },
                    set: { length = GeneratedContentLength(rawValue: Int($0)) ?? .medium }
                ),
                in: 0...Double(GeneratedContentLength.allCases.count - 1),
                step: 1
            ) {
                Text(Strings.lengthSliderAccessibilityLabel)
            } minimumValueLabel: {
                Image(systemName: "textformat.size.smaller")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Image(systemName: "textformat.size.larger")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .tint(AppColor.primary)
            .onChange(of: length) { _ in
                debouncedRegenerateExcerpts()
            }
        }
    }

    private var stylePicker: some View {
        HStack(spacing: 0) {
            Label {
                Text(Strings.styleLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: "wand.and.rays")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Picker(Strings.stylePickerAccessibilityLabel, selection: $style) {
                ForEach(GenerationStyle.allCases, id: \.self) { style in
                    Text(style.displayName)
                        .tag(style)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.primary)
            .onChange(of: style) { _ in
                debouncedRegenerateExcerpts()
            }
        }
    }

    // MARK: - Generation

    private func cancelAllTasks() {
        generationTask?.cancel()
        debounceTask?.cancel()
    }

    private func generateExcerpts() {
        // Cancel any existing generation task
        generationTask?.cancel()

        isGenerating = true
        isFirstResult = true
        error = nil

        generationTask = Task {
            do {
                try await startGeneration()
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
            if !Task.isCancelled {
                isGenerating = false
            }
        }
    }

    private func regenerateExcerpts() {
        excerpts = []
        generateExcerpts()
    }

    private func debouncedRegenerateExcerpts() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(330))
            guard !Task.isCancelled else { return }
            regenerateExcerpts()
        }
    }

    private func startGeneration() async throws {
        let session = LanguageModelSession()
        let prompt = LanguageModelHelper.makeGenerateExcerptPrompt(
            content: postContent,
            length: length,
            style: style
        )
        let stream = session.streamResponse(to: prompt, generating: ExcerptGenerationResult.self)

        for try await result in stream {
            guard !Task.isCancelled else { return }

            if isFirstResult {
                isFirstResult = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            let values = (result.content.excerpts ?? [])
            let excerpts: [GeneratedExcerpt] = values.enumerated().map { index, excerpt in
                GeneratedExcerpt(content: excerpt, isPartial: index == values.endIndex - 1)
            }
            if !excerpts.isEmpty {
                withAnimation(.smooth) {
                    self.excerpts = excerpts
                }
            }
        }

        guard !Task.isCancelled else { return }

        withAnimation(.smooth) {
            for index in excerpts.indices {
                excerpts[index].isPartial = false
            }
        }
    }

    enum TestScenario: String, CaseIterable {
        case loading
        case error
        case finished
    }

    func testing(scenario: TestScenario) -> PostSettingsGenerateExcerptView {
        var copy = self
        copy.testScenario = scenario
        return copy
    }

    private func setupTestScenario(_ scenario: TestScenario) {
#if DEBUG
        switch scenario {
        case .loading:
            isGenerating = true
        case .error:
            error = URLError(.unknown)
        case .finished:
            excerpts = [
                GeneratedExcerpt(
                    content: "Discover the cutting-edge trends transforming web development today. This comprehensive guide covers advanced JavaScript frameworks, innovative CSS techniques, and performance optimization strategies that modern developers use to create faster, more accessible websites.",
                    isPartial: false
                ),
                GeneratedExcerpt(
                    content: "Whether you're a seasoned developer or just starting out, this practical guide provides actionable insights into the latest web development trends. Learn about responsive design principles, modern frameworks, and techniques to build engaging digital experiences.",
                    isPartial: false
                ),
                GeneratedExcerpt(
                    content: "The future of web development is here! Explore innovative approaches to creating digital experiences, from advanced JavaScript frameworks to CSS techniques that enhance performance and accessibility. Get ready to transform your development workflow with these proven strategies.",
                    isPartial: false
                )
            ]
        }
#endif
    }
}

@available(iOS 26, *)
@Generable
private struct ExcerptGenerationResult {
    @Guide(description: "Three different excerpt options, each capturing the main topic and key points of the post in a unique way")
    var excerpts: [String]
}

private struct GeneratedExcerpt {
    let content: String
    var isPartial: Bool
}

@available(iOS 26, *)
private struct ExcerptOptionView: View {
    let index: Int
    let excerpt: GeneratedExcerpt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(Strings.optionLabel(index: index))
                    .font(.subheadline.weight(.medium))

                Spacer(minLength: 8)

                if !excerpt.isPartial {
                    HStack(alignment: .center, spacing: 4) {
                        Text(Strings.characterCount(excerpt.content.count))
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel).opacity(0.5))
                    }
                    .transition(.opacity.combined(with: .offset(x: 7)))
                }
            }
            .font(.footnote)

            Text(excerpt.content)
                .contentTransition(.interpolate)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

private enum Strings {
    static let generateExcerptTitle = NSLocalizedString(
        "postSettings.excerpt.generator.title",
        value: "Excerpt",
        comment: "Title for the excerpt generator popover"
    )

    static let readyToGenerate = NSLocalizedString(
        "postSettings.excerpt.generator.ready",
        value: "Ready to Generate",
        comment: "Title shown when ready to generate excerpts"
    )

    static let readyToGenerateDescription = NSLocalizedString(
        "postSettings.excerpt.generator.readyDescription",
        value: "Tap to create AI-powered excerpt options",
        comment: "Description shown when ready to generate excerpts"
    )

    static let stylePickerTitle = NSLocalizedString(
        "postSettings.excerpt.generator.style",
        value: "Writing Style",
        comment: "Title for the style picker section"
    )

    static let shorterButton = NSLocalizedString(
        "postSettings.excerpt.generator.shorter",
        value: "Shorter",
        comment: "Button to make excerpts shorter"
    )

    static let longerButton = NSLocalizedString(
        "postSettings.excerpt.generator.longer",
        value: "Longer",
        comment: "Button to make excerpts longer"
    )

    static let lengthLabel = NSLocalizedString(
        "postSettings.excerpt.generator.length",
        value: "Length",
        comment: "Label for the length picker section"
    )

    static let lengthSliderAccessibilityLabel = NSLocalizedString(
        "postSettings.excerpt.generator.lengthSlider",
        value: "Length Slider",
        comment: "Accessibility label for the length adjustment slider"
    )

    static let styleLabel = NSLocalizedString(
        "postSettings.excerpt.generator.styleLabel",
        value: "Style",
        comment: "Label for the style picker section"
    )

    static let stylePickerAccessibilityLabel = NSLocalizedString(
        "postSettings.excerpt.generator.stylePicker",
        value: "Style",
        comment: "Accessibility label for the style picker"
    )

    static func optionLabel(index: Int) -> String {
        let format = NSLocalizedString(
            "postSettings.excerpt.generator.option",
            value: "Option %d",
            comment: "Label for excerpt option number. %d is replaced with the option number."
        )
        return String(format: format, index + 1)
    }

    static func characterCount(_ count: Int) -> String {
        let format = NSLocalizedString(
            "postSettings.excerpt.generator.characterCount",
            value: "%d characters",
            comment: "Character count display. %d is replaced with the number of characters."
        )
        return String(format: format, count)
    }
}

#if DEBUG
@available(iOS 26, *)
struct PostSettingsGenerateExcerptView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(PostSettingsGenerateExcerptView.TestScenario.allCases, id: \.self) { scenario in
                PostSettingsGenerateExcerptView(postContent: PostSettingsExcerptEditor.mockPostContent) {
                    print("Text selected:", $0)
                }
                .testing(scenario: scenario)
                .previewDisplayName(scenario.rawValue.capitalized)
                .accentColor(AppColor.primary)
            }
        }
    }
}
#endif
