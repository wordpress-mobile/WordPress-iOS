import XCTest
@testable import WordPress

class UIView_ExistingConstraints: XCTestCase {

    /// Tests that constraint(for:withRelation:) returns an existing constraint if there's one.
    ///
    func testConstraintReturnsExistingConstraint() {
        let parentView = UIView()
        let childView = UIView()

        parentView.addSubview(childView)

        let expectedConstraint = childView.heightAnchor.constraint(equalToConstant: 10)
        expectedConstraint.isActive = true

        XCTAssertEqual(childView.constraint(for: .height, withRelation: .equal), expectedConstraint)
    }

    /// Tests that constraint(for:withRelation:) returns `nil` when there's no existing constraint.
    ///
    func testConstraintReturnsNilWhenNoConstraintExists() {
        let parentView = UIView()
        let childView = UIView()

        parentView.addSubview(childView)

        XCTAssertNil(childView.constraint(for: .height, withRelation: .equal))
    }

    /// Tests that updateConstraint(for:withRelation:constant:active) works.
    ///
    func testUpdateConstraintWorks() {
        let parentView = UIView()
        let childView = UIView()

        parentView.addSubview(childView)

        let expectedConstraint = childView.heightAnchor.constraint(equalToConstant: 10)
        expectedConstraint.isActive = true

        XCTAssertEqual(expectedConstraint.constant, 10)

        childView.updateConstraint(for: .height, withRelation: .equal, setConstant: 20, setActive: true)

        XCTAssertEqual(childView.constraint(for: .height, withRelation: .equal)!.constant, 20)
    }

    /// Tests that updateConstraint(for:withRelation:constant:active) works even if no previous constraint exists.
    ///
    func testUpdateConstraintWorksEvenIfNoPreviousConstraintExists() {
        let parentView = UIView()
        let childView = UIView()

        parentView.addSubview(childView)

        XCTAssertNil(childView.constraint(for: .height, withRelation: .equal))

        childView.updateConstraint(for: .height, withRelation: .equal, setConstant: 20, setActive: true)

        XCTAssertEqual(childView.constraint(for: .height, withRelation: .equal)!.constant, 20)
    }
}
