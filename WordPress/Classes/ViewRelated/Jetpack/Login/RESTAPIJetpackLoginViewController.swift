import Foundation
import UIKit
import SwiftUI
import WordPressCore
import WordPressShared
import WordPressAPIInternal

class RESTAPIJetpackLoginViewController: UIViewController, JetpackConnectionSupport {

    required init?(blog: Blog) {
        guard let service = JetpackConnectionService(blog: blog) else { return nil }

        self.blog = blog
        self.service = service

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let service: JetpackConnectionService

    var blog: Blog

    var promptType: JetpackLoginPromptType = .stats

    var completionBlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = JetpackConnectionViewModel(blog: blog, presentingViewController: self, connectionService: service) { [weak self] in
            self?.completionBlock?()
        }
        let jetpackView = JetpackConnectionView(promptType: promptType, viewModel: viewModel)

        let hostingController = UIHostingController(rootView: jetpackView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.pinEdges()
        hostingController.didMove(toParent: self)
    }

    func refreshUI() {
        // Do nothing.
    }
}

private struct JetpackConnectionView: View {
    let promptType: JetpackLoginPromptType
    @ObservedObject private var viewModel: JetpackConnectionViewModel

    init(promptType: JetpackLoginPromptType, viewModel: JetpackConnectionViewModel) {
        self.promptType = promptType
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(promptType.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)

            Text(promptType.connectMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.steps, id: \.rawValue) { step in
                        StepView(
                            step: step,
                            stage: viewModel.stepStages[step] ?? .pending,
                            onRetry: {
                                if step == viewModel.currentStep {
                                    viewModel.retryCurrentStep()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            if !viewModel.isConnecting {
                Button(Strings.connectButtonTitle) {
                    viewModel.connect()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.bottom, 12)
            } else if viewModel.isCompleted {
                CompletedAnimationView {
                    viewModel.finish()
                }
                .padding(.bottom, 12)
            }
        }
    }
}

private struct CompletedAnimationView: View {
    let onAnimationComplete: () -> Void
    let animationDuration: TimeInterval = 0.5

    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var hasTriggeredCallback = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                let animation = Animation.spring(response: animationDuration)

                if #available(iOS 17.0, *) {
                    withAnimation(animation) {
                        scale = 1.0
                        opacity = 1.0
                    } completion: {
                        onAnimationComplete()
                    }
                } else {
                    withAnimation(animation) {
                        scale = 1.0
                        opacity = 1.0
                    }

                    guard !hasTriggeredCallback else { return }
                    hasTriggeredCallback = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        onAnimationComplete()
                    }
                }
            }
    }
}

private struct StepView: View {
    let step: JetpackConnectionStep
    let stage: StepStage
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            statusIndicator
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(step.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(stage.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if case .error = stage {
                Button(action: onRetry) {
                    Text(Strings.retryButtonTitle)
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(3)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(indicatorBackgroundColor)
                .frame(width: 22, height: 22)

            switch stage {
            case .pending:
                Text(verbatim: "\(step.rawValue + 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            case .processing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.5)
            case .success:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            case .error:
                Image(systemName: "exclamationmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var indicatorBackgroundColor: Color {
        switch stage {
        case .pending:
            return Color.gray
        case .processing:
            return Color.blue
        case .success:
            return Color.green
        case .error:
            return Color.red
        }
    }

    private var borderColor: Color {
        switch stage {
        case .pending:
            return Color(.systemGray5)
        case .processing:
            return Color.blue.opacity(0.3)
        case .success:
            return Color.green.opacity(0.3)
        case .error:
            return Color.red.opacity(0.3)
        }
    }
}

private enum Strings {

    static let retryButtonTitle = NSLocalizedString(
        "jetpack.connection.retry.button",
        value: "Retry",
        comment: "Title for the retry button shown when a connection step fails"
    )

    static let connectButtonTitle = NSLocalizedString(
        "jetpack.connection.connect.button",
        value: "Connect your site",
        comment: "Title for the button that starts the Jetpack connection process"
    )

}
