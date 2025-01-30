import XCTest

@testable import WordPressUI

class UIViewAutoLayoutHelperTests: XCTestCase {
    private var view: UIView!
    private var subview: UIView!

    override func setUp() {
        super.setUp()
        view = UIView(frame: .zero)
        subview = UIView(frame: .zero)
    }

    // MARK: tests for `pinSubviewToAllEdges`

    func testPinSubviewToAllEdgesWithZeroInsets() {
        view.addSubview(subview)
        view.pinSubviewToAllEdges(subview)

        let topConstraint = getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.topAnchor && $0.secondAnchor == subview.topAnchor })
        XCTAssertEqual(topConstraint.constant, 0)

        let leadingConstraint = getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        XCTAssertEqual(leadingConstraint.constant, 0)

        let trailingConstraint = getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        XCTAssertEqual(trailingConstraint.constant, 0)

        let bottomConstraint = getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        XCTAssertEqual(bottomConstraint.constant, 0)
        XCTAssertEqual(bottomConstraint.secondAnchor, subview.bottomAnchor)
    }

    func testPinSubviewToAllEdgesWithNonZeroInsets() {
        view.addSubview(subview)
        let insets = UIEdgeInsets(top: 10, left: 12, bottom: 17, right: 25)
        view.pinSubviewToAllEdges(subview, insets: insets)

        // Self.top = subview.top - insets.top
        let topConstraint = getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.topAnchor && $0.secondAnchor == subview.topAnchor })
        XCTAssertEqual(topConstraint.constant, -insets.top)

        // Self.leading = subview.leading - insets.left
        let leadingConstraint = getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        XCTAssertEqual(leadingConstraint.constant, -insets.left)

        // Self.trailing = subview.trailing + insets.right
        let trailingConstraint = getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        XCTAssertEqual(trailingConstraint.constant, insets.right)

        // Self.bottom = subview.bottom + insets.bottom
        let bottomConstraint = getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        XCTAssertEqual(bottomConstraint.constant, insets.bottom)
    }

    // MARK: tests for `pinSubviewToSafeArea`

    func testPinSubviewToSafeAreaWithZeroInsets() {
        view.addSubview(subview)
        view.pinSubviewToSafeArea(subview)

        let topConstraint = getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.safeAreaLayoutGuide.topAnchor && $0.secondAnchor == subview.topAnchor })
        XCTAssertEqual(topConstraint.constant, 0)

        let leadingConstraint = getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.safeAreaLayoutGuide.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        XCTAssertEqual(leadingConstraint.constant, 0)

        let trailingConstraint = getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.safeAreaLayoutGuide.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        XCTAssertEqual(trailingConstraint.constant, 0)

        let bottomConstraint = getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.safeAreaLayoutGuide.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        XCTAssertEqual(bottomConstraint.constant, 0)
    }

    func testPinSubviewToSafeAreaWithNonZeroInsets() {
        view.addSubview(subview)
        let insets = UIEdgeInsets(top: 10, left: 12, bottom: 17, right: 25)
        view.pinSubviewToSafeArea(subview, insets: insets)

        // Self safe area.top = subview.top - insets.top
        let topConstraint = getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.safeAreaLayoutGuide.topAnchor && $0.secondAnchor == subview.topAnchor })
        XCTAssertEqual(topConstraint.constant, -insets.top)

        // Self safe area.leading = subview.leading - insets.left
        let leadingConstraint = getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.safeAreaLayoutGuide.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        XCTAssertEqual(leadingConstraint.constant, -insets.left)

        // Self safe area.trailing = subview.trailing + insets.right
        let trailingConstraint = getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.safeAreaLayoutGuide.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        XCTAssertEqual(trailingConstraint.constant, insets.right)

        // Self safe area.bottom = subview.bottom + insets.bottom
        let bottomConstraint = getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.safeAreaLayoutGuide.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        XCTAssertEqual(bottomConstraint.constant, insets.bottom)
    }

    private func getConstraint(from view: UIView, filter: (NSLayoutConstraint) -> Bool) -> NSLayoutConstraint {
        let constraints = view.constraints.filter(filter)
        guard let constraint = constraints.first, constraints.count == 1 else {
            XCTFail("Exactly one constraint corresponding to the given filter should have been created")
            fatalError()
        }
        return constraint
    }
}
