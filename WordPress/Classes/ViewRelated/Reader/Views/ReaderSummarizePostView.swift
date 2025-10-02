import SwiftUI
import WordPressUI
import WordPressData
import FoundationModels

@available(iOS 26, *)
struct ReaderSummarizePostView: View {
    let post: ReaderPost

    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var isGenerating = false
    @State private var error: Error?
    @State private var generationTask: Task<Void, Never>?

    var body: some View {
        contentView
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateSummary()
            }
            .onDisappear {
                generationTask?.cancel()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button.make(role: .close) {
                        dismiss()
                    }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            if isGenerating && summary.isEmpty {
                progressView
                    .padding(.top, 4)
            } else if let error {
                EmptyStateView(error.localizedDescription, systemImage: "exclamationmark.message.fill")
                    .frame(minHeight: 460)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if !summary.isEmpty {
                Text(summary)
                    .contentTransition(.interpolate)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private var progressView: some View {
        SparkleProgressView()
            .padding()
            .padding(.leading, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func generateSummary() {
        generationTask?.cancel()
        summary = ""
        error = nil

        generationTask = Task {
            isGenerating = true
            defer { isGenerating = false }

            do {
                let content = post.content ?? ""
                let stream = await IntelligenceService().summarizePost(content: content)

                for try await result in stream {
                    guard !Task.isCancelled else { return }
                    withAnimation(.smooth) {
                        summary = result.content
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.article.summary", value: "Summary", comment: "Navigation title")
}
