import Testing
import UIKit

@testable import WordPressUI

@MainActor
@Suite("presentAdaptiveSheet")
struct UIViewControllerAdaptiveSheetTests {
    private func makeSheet() throws -> UISheetPresentationController {
        let viewController = UIViewController()
        viewController.modalPresentationStyle = .formSheet
        return try #require(viewController.sheetPresentationController)
    }

    @Test("a regular-width window gets the form sheet's own size and corners")
    func regularWindow() throws {
        let sheet = try makeSheet()

        sheet.configureAdaptiveSheet(for: .regular, compactDetents: [.medium()], compactCornerRadius: 16)

        #expect(sheet.detents.map(\.identifier) == [.large])
        #expect(sheet.preferredCornerRadius == nil)
    }

    @Test("a compact-width window gets the compact detents and corners")
    func compactWindow() throws {
        let sheet = try makeSheet()

        sheet.configureAdaptiveSheet(for: .compact, compactDetents: [.medium()], compactCornerRadius: 16)

        #expect(sheet.detents.map(\.identifier) == [.medium])
        #expect(sheet.preferredCornerRadius == 16)
    }

    @Test("widening the window again removes the compact detents")
    func compactThenRegularWindow() throws {
        let sheet = try makeSheet()

        sheet.configureAdaptiveSheet(for: .compact, compactDetents: [.medium()], compactCornerRadius: 16)
        sheet.configureAdaptiveSheet(for: .regular, compactDetents: [.medium()], compactCornerRadius: 16)

        #expect(sheet.detents.map(\.identifier) == [.large])
        #expect(sheet.preferredCornerRadius == nil)
    }

    @Test(
        "the presenter's window picks the starting detents",
        arguments: [
            (UIUserInterfaceSizeClass.regular, UISheetPresentationController.Detent.Identifier.large),
            (.compact, .medium)
        ]
    )
    func startingDetents(
        windowSizeClass: UIUserInterfaceSizeClass,
        expected: UISheetPresentationController.Detent.Identifier
    ) throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.horizontalSizeClass = windowSizeClass
        let presenter = UIViewController()
        window.addSubview(presenter.view)
        presenter.view.updateTraitsIfNeeded()
        let presented = UIViewController()

        presenter.presentAdaptiveSheet(
            presented,
            formSheetSize: CGSize(width: 380, height: 480),
            compactDetents: [.medium()],
            animated: false
        )

        #expect(presented.modalPresentationStyle == .formSheet)
        #expect(presented.preferredContentSize == CGSize(width: 380, height: 480))
        let sheet = try #require(presented.sheetPresentationController)
        #expect(sheet.detents.map(\.identifier) == [expected])
        withExtendedLifetime(window) {}
    }
}
