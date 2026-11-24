import CoreGraphics
import Testing
@testable import WordPress

@Suite("NoticePresenter layout")
struct NoticePresenterLayoutTests {
    /// A narrow iPad window (Stage Manager), in its own coordinate space.
    private let narrowWindow = CGRect(x: 0, y: 0, width: 373, height: 766)

    // MARK: - Bottom inset

    @Test("a keyboard that covers less of the window than the tab bar keeps the notice above the tab bar")
    func smallKeyboardOverlapStaysAboveTabBar() {
        #expect(NoticePresenter.onScreenBottomInset(keyboardOverlap: 30, tabBarHeight: 72) == 72)
    }

    @Test("a window that sits above the keyboard keeps the notice above the tab bar")
    func noKeyboardOverlapStaysAboveTabBar() {
        #expect(NoticePresenter.onScreenBottomInset(keyboardOverlap: 0, tabBarHeight: 72) == 72)
    }

    @Test("a keyboard taller than the tab bar keeps the notice above the keyboard")
    func largeKeyboardOverlapStaysAboveKeyboard() {
        #expect(NoticePresenter.onScreenBottomInset(keyboardOverlap: 336, tabBarHeight: 83) == 336)
    }

    @Test("with the keyboard hidden the notice sits above the tab bar, if there is one")
    func noKeyboard() {
        #expect(NoticePresenter.onScreenBottomInset(keyboardOverlap: nil, tabBarHeight: 72) == 72)
        #expect(NoticePresenter.onScreenBottomInset(keyboardOverlap: nil, tabBarHeight: 0) == 0)
    }

    // MARK: - Keyboard overlap

    @Test("a keyboard across the bottom of the window covers only the part inside it")
    func keyboardAcrossWindowBottom() {
        let keyboard = CGRect(x: -330, y: 708.5, width: 1032, height: 420)
        #expect(NoticePresenter.keyboardOverlap(keyboardFrame: keyboard, windowBounds: narrowWindow) == 57.5)
    }

    @Test("a keyboard below the window covers none of it")
    func keyboardBelowWindow() {
        let keyboard = CGRect(x: -330, y: 800, width: 1032, height: 420)
        #expect(NoticePresenter.keyboardOverlap(keyboardFrame: keyboard, windowBounds: narrowWindow) == 0)
    }

    @Test("a zero keyboard frame covers none of the window")
    func zeroKeyboardFrame() {
        // `CGRect.zero` in screen coordinates, converted to the window's.
        let keyboard = CGRect(x: -330, y: -305, width: 0, height: 0)
        #expect(NoticePresenter.keyboardOverlap(keyboardFrame: keyboard, windowBounds: narrowWindow) == 0)
    }

    @Test("a keyboard in a full-screen window covers its full height, less the window's inset")
    func fullScreenWindow() {
        let window = CGRect(x: 0, y: 0, width: 1030, height: 1374)
        let keyboard = CGRect(x: -1, y: 955, width: 1032, height: 420)
        #expect(NoticePresenter.keyboardOverlap(keyboardFrame: keyboard, windowBounds: window) == 419)
    }
}
