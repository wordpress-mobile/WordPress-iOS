import SwiftUI

public struct ErrorView: View {
    let title: String
    let message: String
    let systemImage: String
    let retryAction: (() -> Void)?

    public init(
        title: String = "Something went wrong",
        message: String = "Please try again later",
        systemImage: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Error icon
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.red.gradient)

            VStack(spacing: 8) {
                // Error title
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                // Error message
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }

            // Retry button (if action provided)
            if let retryAction {
                Button(Localization.tryAgain) {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
}

public struct FullScreenErrorView: View {

    let title: String
    let message: String
    let systemImage: String

    public init(
        title: String = "Something went wrong",
        message: String = "Please try again later",
        systemImage: String = "exclamationmark.triangle.fill"
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView(
            self.title,
            systemImage: self.systemImage,
            description: Text(self.message)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Basic error view
        ErrorView()

        // Network error with retry
        ErrorView(
            title: "Network Error",
            message: "Unable to connect to the server. Check your internet connection and try again.",
            systemImage: "wifi.exclamationmark",
            retryAction: {
                // You'd do something here if this wasn't a preview
            }
        )

        // Custom error
        ErrorView(
            title: "No Data Available",
            message: "There's nothing to show right now.",
            systemImage: "tray"
        )
    }
    .background(.gray.opacity(0.1))
}

#Preview("Full Screen Error View") {
    FullScreenErrorView(
        title: "Network Error",
        message: "Unable to connect to the server. Check your internet connection and try again.",
        systemImage: "wifi.exclamationmark"
    )
}
