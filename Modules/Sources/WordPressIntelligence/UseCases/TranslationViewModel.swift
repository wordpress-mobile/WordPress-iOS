import Foundation
import SwiftUI
import WebKit
import Translation
import NaturalLanguage
import Combine
import WordPressShared

@available(iOS 26, *)
@MainActor
public final class TranslationViewModel: ObservableObject {
    @Published var configuration: TranslationSession.Configuration?

    private var content: [String] = []
    private var continuation: CheckedContinuation<[String], Error>?

    public init() {}

    public func translate(_ content: String, to targetLanguage: Locale.Language) async throws -> String {
        let content = try await translate([content], to: targetLanguage)
        guard let first = content.first else {
            throw URLError(.unknown) // Should never happen
        }
        return first
    }

    /// Translate content to the specified target language.
    ///
    /// This method detects the source language automatically and translates each string
    /// in the content array independently.
    public func translate(_ content: [String], to targetLanguage: Locale.Language = Locale.current.language) async throws -> [String] {
        wpAssert(continuation == nil, "Translation in progress")

        self.content = content
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            // This will trigger the .translationTask in TranslationHostView
            if self.configuration != nil {
                // Yes, this is how you restart translation with the existing configuration
                // in the Translation framework.
                self.configuration?.invalidate()
            } else {
                self.configuration = TranslationSession.Configuration(source: nil, target: targetLanguage)
            }
        }
    }

    /// Check if translation is available for the given content.
    public func isTranslationAvailable(for content: String, to targetLanguage: Locale.Language = Locale.current.language) async -> Bool {
        // Important. The `Translation` framework is effective at translating
        // HTML, but the `status(...)` method and `NLLanguageRecognizer`
        // incorrectly identify dominant langauge as English if a post has a
        // signifcant amount of HTML tags and/or CSS styles.
        let content = (try? ContentExtractor.extractRelevantText(from: content)) ?? content
        do {
            let availability = LanguageAvailability()
            let status = try await availability.status(for: content, to: targetLanguage)
            return status == .installed || status == .supported
        } catch {
            return false
        }
    }

    fileprivate func performTranslation(session: TranslationSession) async {
        do {
            var output: [String] = []
            for string in content {
                try Task.checkCancellation()
                let result = try await session.translate(string)
                output.append(result.targetText)
            }
            finish(with: .success(output))
        } catch {
            if (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == NSUserCancelledError {
                finish(with: .failure(CancellationError()))
            } else {
                finish(with: .failure(error))
            }
        }
    }

    private func finish(with result: Result<[String], Error>) {
        content = []
        if let continuation {
            self.continuation = nil
            continuation.resume(with: result)
        }
    }
}

// MARK: - TranslationHostView (SwiftUI)

/// SwiftUI view that hosts translation functionality using .translationTask()
///
/// This view manages the translation session lifecycle. It observes the view model's
/// configuration and triggers translation when it changes.
///
/// **IMPORTANT**: The `session` object must NEVER leave the `.translationTask` closure.
/// Capturing or storing the session causes crashes.
@available(iOS 26, *)
public struct TranslationHostView: View {
    @ObservedObject var viewModel: TranslationViewModel

    public init(viewModel: TranslationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(viewModel.configuration) { session in
                Task { @MainActor in
                    await viewModel.performTranslation(session: session)
                }
            }
    }
}

@available(iOS 18.0, *)
extension TranslationSession: @retroactive @unchecked(Sendable) {}
