import Foundation
import UIKit

// MARK: - Skeleton UITableView Methods
//
extension UITableView {

    /// Displays Ghost Content with the specified Settings.
    ///
    public func displayGhostContent(options: GhostOptions, style: GhostStyle = .default) {
        guard isDisplayingGhostContent == false else {
            return
        }

        preserveInitialDelegatesAndSettings()
        setupGhostHandler(options: options, style: style)
        allowsSelection = false

        reloadData()
    }

    /// Nukes the Ghost Style.
    ///
    public func removeGhostContent() {
        guard isDisplayingGhostContent else {
            return
        }

        restoreInitialDelegatesAndSettings()
        resetAssociatedReferences()
        removeGhostLayers()

        reloadData()
    }

    /// Indicates if the receiver is wired up to display Ghost Content.
    ///
    public var isDisplayingGhostContent: Bool {
        return ghostHandler != nil
    }
}

// MARK: - Private Methods
//
private extension UITableView {

    /// Sets up an internal (private) instance of GhostTableViewHandler.
    ///
    func setupGhostHandler(options: GhostOptions, style: GhostStyle) {
        let handler = GhostTableViewHandler(options: options, style: style)
        dataSource = handler
        delegate = handler
        ghostHandler = handler
    }

    /// Preserves the DataSource + Delegate + allowsSelection state.
    ///
    func preserveInitialDelegatesAndSettings() {
        initialDataSource = dataSource
        initialDelegate = delegate
        initialAllowsSelection = allowsSelection
    }

    /// Restores the initial DataSource + Delegate + allowsSelection state.
    ///
    func restoreInitialDelegatesAndSettings() {
        dataSource = initialDataSource
        delegate = initialDelegate
        allowsSelection = initialAllowsSelection ?? true
    }

    /// Cleans up all of the (private) internal references.
    ///
    func resetAssociatedReferences() {
        initialDataSource = nil
        initialDelegate = nil
        ghostHandler = nil
        initialAllowsSelection = nil
    }
}

// MARK: - Private "Associated" Properties
//
private extension UITableView {

    /// Reference to the GhostHandler.
    ///
    var ghostHandler: GhostTableViewHandler? {
        get {
            return objc_getAssociatedObject(self, &Keys.ghostHandler) as? GhostTableViewHandler
        }
        set {
            objc_setAssociatedObject(self, &Keys.ghostHandler, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// UITableViewDataSource state, previous to mapping the GhostHandler.
    ///
    var initialDataSource: UITableViewDataSource? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDataSource) as? UITableViewDataSource
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalDataSource, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// UITableViewDelegate state, previous to mapping the GhostHandler.
    ///
    var initialDelegate: UITableViewDelegate? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDelegate) as? UITableViewDelegate
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalDelegate, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// Previous allowsSelection state.
    ///
    var initialAllowsSelection: Bool? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalAllowsSelection) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalAllowsSelection, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: - Nested Types
//
private extension UITableView {

    enum Keys {
        static var ghostHandler = 0x1000
        static var originalDataSource = 0x1001
        static var originalDelegate = 0x1002
        static var originalAllowsSelection = 0x1003
    }
}
