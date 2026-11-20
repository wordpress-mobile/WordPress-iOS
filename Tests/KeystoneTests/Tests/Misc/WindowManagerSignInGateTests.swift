import Testing
import UIKit
@testable import WordPress

@MainActor
@Suite(.serialized)
struct WindowManagerSignInGateTests {
    private let scene: UIWindowScene
    private let windowManager: WindowManager
    private let hostKeyWindow: UIWindow?

    init() throws {
        scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        windowManager = WindowManager(window: UIWindow(windowScene: scene))
        hostKeyWindow = scene.keyWindow
    }

    /// Removes the gate and gives the key window back to the test host. Showing the gate makes its window key, and
    /// removing it makes this test's hidden main window key; other tests read `UIApplication.mainWindow`.
    private func tearDownGate() {
        windowManager.dismissSignInGate()
        hostKeyWindow?.makeKey()
    }

    @Test func gateWindowIsVisibleAgainAfterSceneReconnect() throws {
        windowManager.showSignInGate(UIViewController())
        defer { tearDownGate() }
        let gateWindow = try #require(windowManager.overlayingWindow)

        // The system disconnects the scene in the background.
        gateWindow.windowScene = nil
        #expect(!windowManager.isSignInGateVisible)

        windowManager.reattachOverlayingWindow(to: scene)

        #expect(gateWindow.windowScene === scene)
        #expect(!gateWindow.isHidden)
        #expect(windowManager.isSignInGateVisible)
    }

    @Test func gateTakesOverTheOverlayingWindow() {
        var isOverlayReplaced = false
        windowManager.displayOverlayingWindow(with: UIViewController()) {
            isOverlayReplaced = true
        }
        defer { tearDownGate() }

        let gate = UIViewController()
        windowManager.showSignInGate(gate)

        #expect(isOverlayReplaced)
        #expect(windowManager.overlayingWindow?.rootViewController === gate)
        #expect(windowManager.isSignInGateVisible)
    }

    @Test func otherContentCannotCoverOrRemoveTheGate() {
        let gate = UIViewController()
        windowManager.showSignInGate(gate)
        defer { tearDownGate() }

        let isDisplayed = windowManager.displayOverlayingWindow(with: UIViewController())
        windowManager.clearOverlayingWindow()

        #expect(!isDisplayed)
        #expect(windowManager.overlayingWindow?.rootViewController === gate)
        #expect(windowManager.isSignInGateVisible)
    }

    @Test func dismissingTheGateRemovesItsWindow() {
        windowManager.showSignInGate(UIViewController())
        defer { tearDownGate() }

        windowManager.dismissSignInGate()

        #expect(windowManager.overlayingWindow == nil)
        #expect(!windowManager.isSignInGateVisible)
    }
}
