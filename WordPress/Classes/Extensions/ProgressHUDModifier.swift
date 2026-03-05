import SVProgressHUD
import SwiftUI

enum ProgressHUDState: Equatable {
    case idle
    case running
    case success
    case failure(String)
}

private struct ProgressHUDModifier: ViewModifier {
    @Binding var state: ProgressHUDState
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: state) { _, newValue in
                dismissTask?.cancel()
                dismissTask = nil

                switch newValue {
                case .idle:
                    break
                case .running:
                    SVProgressHUD.show()
                case .success:
                    SVProgressHUD.showSuccess(withStatus: nil)
                    dismissAndReset()
                case .failure(let message):
                    SVProgressHUD.showError(withStatus: message)
                    dismissAndReset()
                }
            }
    }

    private func dismissAndReset() {
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await SVProgressHUD.dismiss()
            state = .idle
        }
    }
}

extension View {
    func progressHUD(state: Binding<ProgressHUDState>) -> some View {
        modifier(ProgressHUDModifier(state: state))
    }
}

// MARK: - Preview

#Preview("ProgressHUD Race Condition") {
    @Previewable @State var state: ProgressHUDState = .idle

    VStack(spacing: 20) {
        // Expected: .idle → .running → .success → .idle
        Button("Run & Succeed") {
            state = .running
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                state = .success
            }
        }

        // Expected: .idle → .running → .failure → .idle
        Button("Run & Fail") {
            state = .running
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                state = .failure("Something went wrong")
            }
        }

        // Expected: .idle → .success → .running (spinner stays on screen)
        Button("Quick Succession (auto)") {
            state = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                state = .running
            }
        }

        Text("State: \(String(describing: state))")
            .font(.headline)
            .animation(.none, value: state)
    }
    .progressHUD(state: $state)
}
