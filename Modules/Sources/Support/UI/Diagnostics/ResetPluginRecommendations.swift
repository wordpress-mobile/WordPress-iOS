import SwiftUI

struct ResetPluginRecommendationsView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case idle
        case resetting
        case error(Error)
        case complete

        var buttonIsDisabled: Bool {
            switch self {
            case .idle: false
            case .resetting: true
            case .error: false
            case .complete: true
            }
        }

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.resetting, .resetting): return true
            case (.error, .error): return false // Errors aren't equatable, so always redraw the view
            case (.complete, .complete): return true
            default: return false
            }
        }
    }

    @State
    var state: ViewState = .idle

    var body: some View {
        DiagnosticCard(
            title: Strings.title,
            subtitle: Strings.subtitle,
            systemImage: "puzzlepiece.extension"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    Task { await resetRecommendations() }
                } label: {
                    Label(buttonLabel, systemImage: buttonIcon)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.buttonIsDisabled)

                if case .error(let error) = state {
                    Text(String(format: Strings.error, error.localizedDescription))
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var buttonLabel: String {
        switch state {
        case .idle:
            return Strings.buttonIdle
        case .resetting, .error:
            return Strings.buttonResetting
        case .complete:
            return Strings.buttonComplete
        }
    }

    private var buttonIcon: String {
        switch state {
        case .idle:
            return "arrow.counterclockwise"
        case .resetting:
            return "hourglass"
        case .error:
            return "exclamationmark.triangle"
        case .complete:
            return "checkmark"
        }
    }

    private func resetRecommendations() async {
        await MainActor.run {
            withAnimation {
                state = .resetting
            }
        }

        do {
            try await Task.runForAtLeast(.seconds(1)) {
                try await dataProvider.resetPluginRecommendations()
            }

            await MainActor.run {
                withAnimation {
                    state = .complete
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    state = .error(error)
                }
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.title",
        value: "Reset Plugin Recommendations",
        comment: "Title for the reset plugin recommendations diagnostic card"
    )

    static let subtitle = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.subtitle",
        value: "Clear saved plugin recommendation preferences to see prompts again.",
        comment: "Subtitle explaining what resetting plugin recommendations does"
    )

    static let buttonIdle = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.button.idle",
        value: "Reset Recommendations",
        comment: "Button label to reset plugin recommendations"
    )

    static let buttonResetting = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.button.resetting",
        value: "Resetting…",
        comment: "Button label shown while resetting plugin recommendations"
    )

    static let buttonComplete = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.button.complete",
        value: "Reset Complete",
        comment: "Button label shown after plugin recommendations have been reset"
    )

    static let error = NSLocalizedString(
        "diagnostics.reset-plugin-recommendations.complete.message",
        value: "Error: %@",
        comment: "Error message shown if resetting plugin recommendations doesn't work"
    )
}

#Preview {
    ResetPluginRecommendationsView()
        .environmentObject(SupportDataProvider.testing)
}
