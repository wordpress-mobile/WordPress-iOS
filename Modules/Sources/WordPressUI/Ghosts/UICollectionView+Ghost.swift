import Foundation
import UIKit

// MARK: - Skeleton UICollectionView Methods
//
extension UICollectionView {

    /// Displays Ghost Content, based on cells with the given reuseIdentifier, and items hieararchy.
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
private extension UICollectionView {

    /// Sets up an internal (private) instance of GhostCollectionViewHandler.
    ///
    func setupGhostHandler(options: GhostOptions, style: GhostStyle) {
        let handler = GhostCollectionViewHandler(options: options, style: style)
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
private extension UICollectionView {

    /// Reference to the GhostHandler.
    ///
    var ghostHandler: GhostCollectionViewHandler? {
        get {
            return objc_getAssociatedObject(self, &Keys.ghostHandler) as? GhostCollectionViewHandler
        }
        set {
            objc_setAssociatedObject(self, &Keys.ghostHandler, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// UICollectionViewDataSource state, previous to mapping the GhostHandler.
    ///
    var initialDataSource: UICollectionViewDataSource? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDataSource) as? UICollectionViewDataSource
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalDataSource, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// UICollectionViewDelegate state, previous to mapping the GhostHandler.
    ///
    var initialDelegate: UICollectionViewDelegate? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDelegate) as? UICollectionViewDelegate
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
private extension UICollectionView {

    enum Keys {
        static var ghostHandler = 0x1000
        static var originalDataSource = 0x1001
        static var originalDelegate = 0x1002
        static var originalAllowsSelection = 0x1003
    }
}
