import SwiftUI
import WordPressUI
import DesignSystem
import FoundationModels

@available(iOS 26, *)
struct PostSettingsGenerateExcerptView: View {
    let postContent: String
    let onSelection: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage("jetpack_ai_generated_excerpt_style")
    private var style: GenerationStyle = .engaging

    @AppStorage("jetpack_ai_generated_excerpt_length")
    private var length: GeneratedContentLength = .medium

    @State private var results: [ExcerptGenerationResult.PartiallyGenerated] = []
    @State private var isGenerating = false
    @State private var isPreparingResponse = true
    @State private var error: Error?
    @State private var loadMoreError: Error?
    @State private var generationTask: Task<Void, Never>?
    @State private var debounceTask: Task<Void, Never>?
    @State private var session: LanguageModelSession?

    private var excerpts: [String] {
        results.flatMap { ($0.excerpts ?? []) }
    }

    init(postContent: String, onSelection: @escaping (String) -> Void) {
        self.postContent = postContent
        self.onSelection = onSelection
    }

    var body: some View {
        contentView
            .navigationTitle(Strings.generateExcerptTitle)
            .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            WPAnalytics.track(.intelligenceExcerptGeneratorOpened)
            generateExcerpts()
        }
        .onDisappear {
            cancelAllTasks()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isGenerating && results.isEmpty {
                    progressView
                        .padding(.top, 4)
                } else if let error {
                    EmptyStateView(error.localizedDescription, systemImage: "exclamationmark.message.fill")
                        .frame(minHeight: 460)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    listContent
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingControlPanel
        }
    }

    private var progressView: some View {
        SparkleProgressView()
            .padding()
            .padding(.leading, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var listContent: some View {
        let excerpts = self.excerpts

        ForEach(Array(excerpts.enumerated()), id: \.offset) { index, excerpt in
            VStack(spacing: 0) {
                Button(action: {
                    cancelAllTasks()
                    onSelection(excerpt)
                    WPAnalytics.track(.intelligenceExcerptSelected, properties: ["index": "\(index)"])
                    dismiss()
                }) {
                    ExcerptOptionView(
                        index: index,
                        excerpt: excerpt,
                        isPartial: index == excerpts.endIndex - 1 && isGenerating && !isPreparingResponse
                    )
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .buttonStyle(.plain)

                if index < excerpts.count - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }

        if !isGenerating {
            if let loadMoreError {
                Text(loadMoreError.localizedDescription)
                    .foregroundStyle(.secondary)
            } else if !results.isEmpty && results.count < 5 {
                Button(Strings.generateMore, action: generateMoreExcerpts)
                    .font(.subheadline.weight(.medium))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
        } else if isPreparingResponse {
            progressView
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
        .padding(.bottom)
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
                didChangeGenerationParameters()
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
            .fixedSize()
            .tint(Color.primary)
            .onChange(of: style) { _ in
                didChangeGenerationParameters()
            }
        }
    }

    // MARK: - Generation

    private func cancelAllTasks() {
        generationTask?.cancel()
        debounceTask?.cancel()
    }

    private func generateExcerpts() {
        generationTask?.cancel()

        session = nil
        results = []
        error = nil
        loadMoreError = nil

        generationTask = Task {
            do {
                let session = LanguageModelSession(
                    model: .init(guardrails: .permissiveContentTransformations),
                    instructions: LanguageModelHelper.generateExcerptInstructions
                )
                self.session = session
                try await actuallyGenerateExcerpts(in: session)
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
            }
        }
    }

    private func generateMoreExcerpts() {
        guard let session else {
            return wpAssertionFailure("session missing")
        }
        generationTask = Task {
            do {
                try await actuallyGenerateExcerpts(in: session, isLoadMore: true)
            } catch {
                guard !Task.isCancelled else { return }
                loadMoreError = error
            }
        }
    }

    private func didChangeGenerationParameters() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(330))
            guard !Task.isCancelled else { return }
            generateExcerpts()
        }
    }

    private func actuallyGenerateExcerpts(in session: LanguageModelSession, isLoadMore: Bool = false) async throws {
        isGenerating = true
        isPreparingResponse = true
        defer {
            isGenerating = false
        }

        let content = IntelligenceService().extractRelevantText(from: postContent)
        let prompt = isLoadMore ? LanguageModelHelper.generateMoreOptionsPrompt : LanguageModelHelper.makeGenerateExcerptPrompt(content: content, length: length, style: style)
        let stream = session.streamResponse(to: prompt, generating: ExcerptGenerationResult.self)

        for try await result in stream {
            guard !Task.isCancelled else { return }

            withAnimation(.smooth) {
                if isPreparingResponse {
                    isPreparingResponse = false
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }

                if let index = results.firstIndex(where: { $0.id == result.content.id }) {
                    results[index] = result.content
                } else {
                    results.append(result.content)
                }
            }
        }

        guard !Task.isCancelled else { return }

        WPAnalytics.track(.intelligenceExcerptOptionsGenerated, properties: [
            "length": length.trackingName,
            "style": style.rawValue,
            "load_more": isLoadMore ? 1 : 0
        ])
    }
}

@available(iOS 26, *)
@Generable
private struct ExcerptGenerationResult {
    @Guide(description: "Three different excerpt options, each capturing the main topic and key points of the post in a unique way")
    var excerpts: [String]
}

@available(iOS 26, *)
private struct ExcerptOptionView: View {
    let index: Int
    let excerpt: String
    let isPartial: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(Strings.optionLabel(index: index))
                    .font(.subheadline.weight(.medium))

                Spacer(minLength: 8)

                if !isPartial {
                    HStack(alignment: .center, spacing: 4) {
                        Text(Strings.characterCount(excerpt.count))
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                    .transition(.opacity.combined(with: .offset(x: 7)))
                }
            }
            .font(.footnote)

            Text(excerpt)
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

    static let generateMore = NSLocalizedString(
        "postSettings.excerpt.generator.generateMore",
        value: "Suggest More Options",
        comment: "Button to suggest (generate) more options"
    )
}

#if DEBUG

@available(iOS 26, *)
#Preview {
    PostSettingsGenerateExcerptView(postContent: PostSettingsExcerptEditor.mockPostContent) {
        print("Text selected:", $0)
    }
    .accentColor(AppColor.primary)
}

#endif
