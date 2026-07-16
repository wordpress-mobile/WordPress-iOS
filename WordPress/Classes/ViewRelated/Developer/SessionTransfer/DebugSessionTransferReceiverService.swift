import BuildSettingsKit
import SwiftUI
import UIKit
import WordPressUI

/// Runs a headless `DebugSessionTransferReceiver` while the app is showing the login screen, so a
/// signed-out instance — most usefully a fresh Simulator — automatically advertises for a session and
/// can be signed in from a nearby device without opening a debug screen. When a sender signals intent,
/// it presents the receiver's challenge QR over the login screen for the sender to scan.
///
/// Scoped deliberately: the receiver only runs while the login prologue / WP.com login is on screen
/// (driven by `RootViewCoordinator`) and the app is in the foreground. It stops the moment the app UI
/// is shown or the app resigns active, so a signed-in app never advertises. Debug/internal builds
/// only.
@MainActor
final class DebugSessionTransferReceiverService {
    static let shared = DebugSessionTransferReceiverService()

    private var receiver: DebugSessionTransferReceiver?
    private weak var challengeController: UIViewController?
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
        // The receiver hops to the main thread before calling these, so `assumeIsolated` is safe.
        let receiver = DebugSessionTransferReceiver(
            onChallenge: { [weak self] publicKey in
                MainActor.assumeIsolated { self?.presentChallenge(publicKey: publicKey) }
            },
            onResolve: { [weak self] signedIn in
                MainActor.assumeIsolated { self?.challengeResolved(signedIn: signedIn) }
            }
        )
        self.receiver = receiver
        receiver.start()
    }

    private func stopReceiver() {
        receiver?.stop()
        receiver = nil
        dismissChallenge()
    }

    // MARK: - Challenge QR

    private func presentChallenge(publicKey: Data) {
        guard challengeController == nil,
            let presenter = WordPressAppDelegate.shared?.window?.topmostPresentedViewController
        else {
            return
        }
        let view = DebugSessionTransferChallengeView(
            publicKey: publicKey,
            onCancel: { [weak self] in self?.cancelChallenge() }
        )
        let controller = UIHostingController(rootView: view)
        // `.large` so the title, subtitle, and QR all fit without the sheet compressing (and clipping)
        // the text.
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }
        challengeController = controller
        presenter.present(controller, animated: true)
    }

    private func dismissChallenge() {
        challengeController?.dismiss(animated: true)
        challengeController = nil
    }

    /// The receiver finished a challenge. Take the QR down; if the pairing was abandoned (not signed
    /// in), recycle the receiver to resume advertising — it stopped advertising when the QR went up.
    /// Deferred so we don't tear the receiver down from inside its own callback.
    private func challengeResolved(signedIn: Bool) {
        dismissChallenge()
        guard !signedIn else { return }
        Task { @MainActor in
            self.stopReceiver()
            self.updateActivation()
        }
    }

    /// The user dismissed the QR: abandon the in-flight transfer by recycling the receiver, then keep
    /// listening for the next one (if we should still be advertising).
    private func cancelChallenge() {
        stopReceiver()
        updateActivation()
    }
}
