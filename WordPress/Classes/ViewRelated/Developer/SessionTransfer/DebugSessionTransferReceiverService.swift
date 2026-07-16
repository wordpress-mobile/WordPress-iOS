import BuildSettingsKit
import UIKit

/// Runs a headless `DebugSessionTransferReceiver` while the app is showing the login screen, so a
/// signed-out instance — most usefully a fresh Simulator — automatically advertises for a session and
/// can be signed in from a nearby device without opening a debug screen.
///
/// Scoped deliberately: the receiver only runs while the login prologue / WP.com login is on screen
/// (driven by `RootViewCoordinator`) and the app is in the foreground. It stops the moment the app UI
/// is shown or the app resigns active, so a signed-in app never advertises. Debug/internal builds
/// only.
@MainActor
final class DebugSessionTransferReceiverService {
    static let shared = DebugSessionTransferReceiverService()

    private var receiver: DebugSessionTransferReceiver?
    private var isLoginScreenVisible = false
    private var isForeground = false
    private var lifecycleStarted = false

    private init() {}

    /// Begins observing the app's foreground lifecycle. Safe to call once at launch.
    func start() {
        guard BuildConfiguration.current.isInternal, !lifecycleStarted else { return }
        lifecycleStarted = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        isForeground = UIApplication.shared.applicationState == .active
        updateActivation()
    }

    /// Reported by `RootViewCoordinator` as it swaps between the login prologue and the app UI.
    /// `nonisolated` so the non-`@MainActor` coordinator can call it directly; it hops to the main
    /// actor to touch the receiver.
    nonisolated func setLoginScreenVisible(_ visible: Bool) {
        Task { @MainActor in
            guard BuildConfiguration.current.isInternal else { return }
            self.isLoginScreenVisible = visible
            self.updateActivation()
        }
    }

    @objc private func appDidBecomeActive() {
        isForeground = true
        updateActivation()
    }

    @objc private func appWillResignActive() {
        isForeground = false
        updateActivation()
    }

    private func updateActivation() {
        if BuildConfiguration.current.isInternal, isLoginScreenVisible, isForeground {
            startReceiver()
        } else {
            stopReceiver()
        }
    }

    private func startReceiver() {
        guard receiver == nil else { return }
        let receiver = DebugSessionTransferReceiver()
        self.receiver = receiver
        receiver.start()
    }

    private func stopReceiver() {
        receiver?.stop()
        receiver = nil
    }
}
