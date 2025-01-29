import XCTest

@testable import WordPressUI

class UITableViewGhostTests: XCTestCase {
    func test_call_will_start_ghost_animation_before_animating() {
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        tableView.dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(GhostMockCell.willStartGhostAnimationCalled)
    }

    func test_cell_doesnt_have_to_conform_to_GhostCellDelegate() {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "cell", rowsPerSection: [1]), style: .default)

        let cell = tableView.dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        XCTAssertNotNil(cell)
    }

    func test_tableview_will_disable_selection_when_animating() {
        // Given
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        XCTAssertTrue(tableView.allowsSelection)

        // When
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        // Then
        XCTAssertFalse(tableView.allowsSelection)

        // When
        tableView.removeGhostContent()

        // Then
        XCTAssertTrue(tableView.allowsSelection)
    }

    func test_tableview_will_have_original_selection_state_after_removing_ghost_content() {
        // Given
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        tableView.allowsSelection = false

        // When
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        // Then
        XCTAssertFalse(tableView.allowsSelection)

        // When
        tableView.removeGhostContent()

        // Then
        XCTAssertFalse(tableView.allowsSelection)
    }
}

class GhostMockCell: UITableViewCell, GhostableView {
    static var willStartGhostAnimationCalled = false

    func ghostAnimationWillStart() {
        GhostMockCell.willStartGhostAnimationCalled = true
    }
}
