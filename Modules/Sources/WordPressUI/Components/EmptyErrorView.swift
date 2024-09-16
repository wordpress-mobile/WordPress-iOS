import SwiftUI

/// Useful if an error occured while fetching a list of objects
///
public struct EmptyErrorView: View {

    private let error: Error

    public init(error: Error) {
        self.error = error
    }

    public var body: some View {
        EmptyStateView(
            error.localizedDescription,
            systemImage: "exclamationmark.triangle.fill"
        ).multilineTextAlignment(.center)
    }
}

#Preview {
    enum TestError: LocalizedError {
        case foo
    }

    return EmptyErrorView(error: TestError.foo)
}
