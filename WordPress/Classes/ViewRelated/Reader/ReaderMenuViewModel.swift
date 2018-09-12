import Foundation
import CocoaLumberjack
import Gridicons

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



/// Enum of the sections shown in the reader.
///
enum ReaderMenuSectionType: Int {
    case defaults
    case teams
    case lists
    case tags
}


/// Enum of the types of row items shown in the reader.
///
enum ReaderMenuItemType: Int {
    case topic
    case search
    case recommended
    case addItem
    case savedPosts
}


/// Represents a section in the Reader's menu.
///
struct ReaderMenuSection {
    let title: String
    let type: ReaderMenuSectionType
}


/// Represents an row, or menu item in a reader menu section.
///
struct ReaderMenuItem {
    let title: String
    let type: ReaderMenuItemType
    // A custom icon for the menu item.
    var icon: UIImage?
    // The corresponding topic for the item, if there is one (e.g. Search does not have a topic)
    var topic: ReaderAbstractTopic?
    // The order of the item if a custom order is used by the section.
    var order: Int = 0


    init(title: String, type: ReaderMenuItemType, icon: UIImage?, topic: ReaderAbstractTopic?) {
        self.title = title
        self.type = type
        self.icon = icon
        self.topic = topic
    }


    init(title: String, type: ReaderMenuItemType) {
        self.title = title
        self.type = type
    }
}

extension ReaderMenuItem: Comparable {
    static func == (lhs: ReaderMenuItem, rhs: ReaderMenuItem) -> Bool {
        return lhs.order == rhs.order && lhs.title == rhs.title
    }

    static func < (lhs: ReaderMenuItem, rhs: ReaderMenuItem) -> Bool {
        if lhs.order < rhs.order {
            return true
        }

        if lhs.order > rhs.order {
            return false
        }

        if lhs.title < rhs.title {
            return true
        }

        return false
    }
}


/// Protocol allowing a reader menu view model to notify content changes.
///
protocol ReaderMenuViewModelDelegate: class {

    /// Notifies the delegate that the menu did reload its content.
    ///
    func menuDidReloadContent()


    /// Notifies the delegate that the content of the specified section has changed.
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    func menuSectionDidChangeContent(_ index: Int)
}


/// Defines the preferred order of items in the default section.
///
enum ReaderDefaultMenuItemOrder: Int {
    case followed
    case discover
    case search
    case recommendations
    case likes
    case savedForLater
    case other
}


/// The view model used by the reader.
///
@objc class ReaderMenuViewModel: NSObject {
    @objc var defaultsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    @objc var teamsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    @objc var listsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    @objc var tagsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!

    var sections = [ReaderMenuSection]()
    var defaultSectionItems = [ReaderMenuItem]()
    weak var delegate: ReaderMenuViewModelDelegate?

    private let sectionCreators: [ReaderMenuItemCreator]

    private enum Strings {
        static let savedForLaterMenuTitle = NSLocalizedString("Saved Posts", comment: "Section title for Saved Posts in Reader")
    }

    // MARK: - Lifecycle Methods
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    init(sectionCreators: [ReaderMenuItemCreator]) {
        self.sectionCreators = sectionCreators
        super.init()
        listenForWordPressAccountChanged()
        setupResultsControllers()
        setupSections()
    }


    @objc func listenForWordPressAccountChanged() {
        NotificationCenter.default.addObserver(self, selector: #selector(ReaderMenuViewModel.handleWordPressComAccountChanged(_:)), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)
    }


    // MARK: - Setup


    /// Sets up the results controllers.
    ///
    @objc func setupResultsControllers() {
        setupDefaultResultsController()
        setupTeamsResultsController()
        setupListResultsController()
        setupTagsResultsController()
    }


    /// Sets up the sections. This should be called only once during init, or when
    /// the user signs in / out of wpcom.
    /// Call the section setup methods in the order the sections should appear
    /// in the menu.
    ///
    @objc func setupSections() {
        // Clear anything that's cached.
        sections.removeAll()

        // Rebuild!
        setupDefaultsSection()

        if ReaderHelpers.isLoggedIn() && teamsFetchedResultsController.fetchedObjects?.count > 0 {
            setupTeamsSection()
        }

        if ReaderHelpers.isLoggedIn() && listsFetchedResultsController.fetchedObjects?.count > 0 {
            setupListsSection()
        }

        setupTagsSection()
    }


    // MARK: - Default Section


    /// Sets up the default fetched results controller.
    ///
    @objc func setupDefaultResultsController() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderDefaultTopic")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        defaultsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: ContextManager.sharedInstance().mainContext,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
        defaultsFetchedResultsController.delegate = self

        do {
            let _ = try defaultsFetchedResultsController.performFetch()
        } catch {
            DDLogError("There was a problem fetching default topics for the menu.")
            assertionFailure("There was a problem fetching default topics.")
        }
    }


    /// Sets up the defaults section and its corresponding NSFetchedResultsController.
    ///
    @objc func setupDefaultsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Streams", comment: "Section title of the default reader items."), type: .defaults)
        sections.append(section)

        buildDefaultSectionItems()
    }


    /// Builds (or rebuilds) the items for the default menu section.
    /// Since the default section shows items representing things other than topics,
    /// we construct and cache menu items in an array with the desired item order.
    ///
    @objc func buildDefaultSectionItems() {
        defaultSectionItems.removeAll()

        // Create menu items from the fetched results
        if let fetchedObjects = defaultsFetchedResultsController.fetchedObjects {
            for topic in fetchedObjects {
                guard let abstractTopic = topic as? ReaderAbstractTopic else {
                    continue
                }

                let item = sectionCreator(for: abstractTopic).menuItem(with: abstractTopic)

                defaultSectionItems.append(item)
            }
        }

        defaultSectionItems.append(searchMenuItem())

        defaultSectionItems.append(savedPostsMenuItem())

        // Sort the items ascending.
        defaultSectionItems.sort(by: <)
    }


    /// Selects and returns the entity responsible for creating a menu item for a given topic
    ///
    private func sectionCreator(for topic: ReaderAbstractTopic) -> ReaderMenuItemCreator {
        return sectionCreators.filter {
            $0.supports(topic)
            }.first ?? OtherMenuItemCreator()
    }

    /// Returns the menu item to use for the reader search
    ///
    func searchMenuItem() -> ReaderMenuItem {
        return SearchMenuItemCreator().menuItem()
    }

    /// Returns the menu item to use for the reader search
    ///
    func savedPostsMenuItem() -> ReaderMenuItem {
        return SavedForLaterMenuItemCreator().menuItem()
    }


    /// Returns the number of items for the default section.
    ///
    /// - Returns: The number of items in the section.
    ///
    @objc func itemCountForDefaultSection() -> Int {
        return defaultSectionItems.count
    }


    /// Returns the menu item from the default section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForDefaultAtIndex(_ index: Int) -> ReaderMenuItem? {
        return defaultSectionItems[index]
    }


    // MARK: - Teams Section


    /// Sets up the teams section.
    ///
    @objc func setupTeamsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Teams", comment: "Section title of the teams reader section."), type: .teams)
        sections.append(section)
    }


    /// Sets up the teams fetched results controller.
    ///
    @objc func setupTeamsResultsController() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderTeamTopic")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        teamsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: ContextManager.sharedInstance().mainContext,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        teamsFetchedResultsController.delegate = self

        do {
            let _ = try teamsFetchedResultsController.performFetch()
        } catch {
            DDLogError("There was a problem fetching team topics for the menu.")
            assertionFailure("There was a problem fetching team topics.")
        }
    }


    /// Returns the number of items for the teams section.
    ///
    /// - Returns: The number of items in the section.
    ///
    @objc func itemCountForTeamsSection() -> Int {
        return teamsFetchedResultsController.fetchedObjects?.count ?? 0
    }


    /// Returns the menu item from the teams section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForTeamsAtIndex(_ index: Int) -> ReaderMenuItem? {
        guard let topic = teamsFetchedResultsController.object(at: IndexPath(row: index, section: 0)) as? ReaderTeamTopic else {
            return nil
        }

        return ReaderMenuItem(title: topic.title, type: .topic, icon: topic.icon, topic: topic)
    }


    // MARK: - List Section


    /// Sets up the list fetched results controller
    ///
    @objc func setupListResultsController() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderListTopic")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        listsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: ContextManager.sharedInstance().mainContext,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        listsFetchedResultsController.delegate = self

        updateAndPerformListsFetchRequest()
    }


    /// Updates the lists results controller's fetch request predicate and performs a new fetch
    ///
    @objc func updateAndPerformListsFetchRequest() {
        listsFetchedResultsController.fetchRequest.predicate = predicateForRequests()
        do {
            let _ = try listsFetchedResultsController.performFetch()
        } catch {
            DDLogError("There was a problem fetching list topics for the menu.")
            assertionFailure("There was a problem fetching list topics.")
        }
    }


    /// Sets up the lists section and its corresponding NSFetchedResultsController.
    ///
    @objc func setupListsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Lists", comment: "Section title of the lists reader section."), type: .lists)
        sections.append(section)
    }


    /// Returns the number of items for the lists section.
    ///
    /// - Returns: The number of items in the section.
    ///
    @objc func itemCountForListSection() -> Int {
        return listsFetchedResultsController.fetchedObjects?.count ?? 0
    }


    /// Returns the menu item from the lists section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForListAtIndex(_ index: Int) -> ReaderMenuItem? {
        guard let topic = listsFetchedResultsController.object(at: IndexPath(row: index, section: 0)) as? ReaderAbstractTopic else {
            return nil
        }
        return ReaderMenuItem(title: topic.title, type: .topic, icon: nil, topic: topic)
    }


    // MARK: - Tags Section


    /// Sets up the tags fetched results controller
    ///
    @objc func setupTagsResultsController() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderTagTopic")
        fetchRequest.predicate = predicateForRequests()
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        tagsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: ContextManager.sharedInstance().mainContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        tagsFetchedResultsController.delegate = self

        do {
            let _ = try tagsFetchedResultsController.performFetch()
        } catch {
            DDLogError("There was a problem fetching tag topics for the menu.")
            assertionFailure("There was a problem fetching tag topics.")
        }
    }


    /// Updates the lists results controller's fetch request predicate and performs a new fetch
    ///
    @objc func updateAndPerformTagsFetchRequest() {
        tagsFetchedResultsController.fetchRequest.predicate = predicateForRequests()
        do {
            let _ = try tagsFetchedResultsController.performFetch()
        } catch {
            DDLogError("There was a problem fetching tag topics for the menu.")
            assertionFailure("There was a problem fetching tag topics.")
        }
    }


    /// Sets up the tags section and its corresponding NSFetchedResultsController.
    ///
    @objc func setupTagsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Tags", comment: "Section title of the tags reader section."), type: .tags)
        sections.append(section)
    }


    /// Returns the number of items for the tags section.
    ///
    /// - Returns: The number of items in the section.
    ///
    @objc func itemCountForTagSection() -> Int {
        var count = tagsFetchedResultsController.fetchedObjects?.count ?? 0
        if ReaderHelpers.isLoggedIn() {
            // The first time for a logged in user will be an "AddItem" type, so increase the count by 1.
            count += 1
        }
        return count
    }


    /// Returns the menu item from the tags section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForTagAtIndex(_ index: Int) -> ReaderMenuItem? {
        var fetchedIndex = index
        if ReaderHelpers.isLoggedIn() {
            if fetchedIndex == 0 {
                let title = NSLocalizedString("Add a Tag", comment: "Title. Lets the user know that they can use this feature to subscribe to new tags.")
                return ReaderMenuItem(title: title, type: .addItem)
            } else {
                // Adjust the index by one to account for AddItem
                fetchedIndex -= 1
            }
        }

        guard let topic = tagsFetchedResultsController.object(at: IndexPath(row: fetchedIndex, section: 0)) as? ReaderAbstractTopic else {
            return nil
        }
        return ReaderMenuItem(title: topic.title, type: .topic, icon: nil, topic: topic)
    }


    // MARK: - Helper Methods


    /// Returns the predicate for tag and list fetch requests.
    ///
    /// - Returns: An NSPredicate
    ///
    @objc func predicateForRequests() -> NSPredicate {
        if ReaderHelpers.isLoggedIn() {
            return NSPredicate(format: "following = YES AND showInMenu = YES")
        } else {
            return NSPredicate(format: "following = NO AND showInMenu = YES")
        }
    }


    // MARK: - Notifications


    /// Handles a notification that the signed in wpcom account was changed.
    /// All the content in the view model is updated as a result.
    ///
    @objc func handleWordPressComAccountChanged(_ notification: Foundation.Notification) {
        // Update predicates to correctly fetch following or not following.
        updateAndPerformListsFetchRequest()
        updateAndPerformTagsFetchRequest()

        setupSections()
        delegate?.menuDidReloadContent()
    }


    // MARK: - View Model Interaction Methods


    /// Returns the number of sections the menu should show.
    ///
    /// - Returns: The number of sections.
    ///
    @objc func numberOfSectionsInMenu() -> Int {
        return sections.count
    }


    /// Retuns the index of the section with the specified type.
    ///
    /// - Paramters:
    ///     - type: The type of the section.
    ///
    /// - Return: The index of the section or nil if it was not found.
    ///
    func indexOfSectionWithType(_ type: ReaderMenuSectionType) -> Int? {
        for (index, section) in sections.enumerated() {
            if section.type == type {
                return index
            }
        }
        return nil
    }


    /// Returns the number of items in the specified section.
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The number of rows in the section.
    ///
    @objc func numberOfItemsInSection(_ index: Int) -> Int {
        let section = sections[index]

        switch section.type {
        case .defaults:
            return itemCountForDefaultSection()

        case .teams:
            return itemCountForTeamsSection()

        case .lists:
            return itemCountForListSection()

        case .tags:
            return itemCountForTagSection()
        }
    }


    /// Returns the title for the specified section
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The title of the section.
    ///
    @objc func titleForSection(_ index: Int) -> String {
        return sections[index].title
    }


    /// Returns the type for the specified section
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The type of the section.
    ///
    func typeOfSection(_ index: Int) -> ReaderMenuSectionType {
        return sections[index].type
    }


    /// Returns the section info for the specified section
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The section info.
    ///
    func sectionInfoAtIndex(_ index: Int) -> ReaderMenuSection {
        return sections[index]
    }


    /// Returns the menu item for the specified section and row
    ///
    /// - Parameters:
    ///     - index: The indexPath of the item.
    ///
    /// - Returns: The menu item for the specified index path.
    ///
    func menuItemAtIndexPath(_ indexPath: IndexPath) -> ReaderMenuItem? {
        let section = sections[indexPath.section]

        switch section.type {
        case .defaults:
            return menuItemForDefaultAtIndex(indexPath.row)

        case .teams:
            return menuItemForTeamsAtIndex(indexPath.row)

        case .lists:
            return menuItemForListAtIndex(indexPath.row)

        case .tags:
            return menuItemForTagAtIndex(indexPath.row)
        }
    }


    /// Get the indexPath of a specific item in the default menu section
    /// e.g. Discover.
    ///
    /// - Parameter order: The ReaderDefaultMenuItemOrder representing the item
    ///                    to find.
    ///
    /// - Returns: An NSIndexPath representing the item.
    ///
    func indexPathOfDefaultMenuItemWithOrder(order: ReaderDefaultMenuItemOrder) -> IndexPath {
        if let sectionIndex = indexOfSectionWithType(.defaults) {
            for (index, item) in defaultSectionItems.enumerated() {
                if item.order == order.rawValue {
                    return IndexPath(row: index, section: sectionIndex)
                }
            }
        }

        return IndexPath(row: order.rawValue, section: ReaderMenuSectionType.defaults.rawValue)
    }

    /// Get the indexPath of the specified tag
    ///
    /// - Parameters:
    ///     tag: The tag topic to find.
    ///
    /// - Returns: An NSIndexPath optional.
    ///
    @objc func indexPathOfTag(_ tag: ReaderTagTopic) -> IndexPath? {
        if let indexPath = tagsFetchedResultsController.indexPath(forObject: tag) {
            var row = indexPath.row
            if ReaderHelpers.isLoggedIn() {
                row += 1
            }
            return IndexPath(row: row, section: indexOfSectionWithType(.tags)!)
        }
        return nil
    }

    func indexPathOfTeam(withSlug slug: String) -> IndexPath? {
        guard let teams = teamsFetchedResultsController.fetchedObjects as? [ReaderTeamTopic],
            let section = indexOfSectionWithType(.teams) else {
            return nil
        }

        for (index, team) in teams.enumerated() {
            if team.slug == slug {
                return IndexPath(row: index, section: section)
            }
        }

        return nil
    }

    func indexPathOfSavedForLater() -> IndexPath? {
        if let sectionIndex = indexOfSectionWithType(.defaults) {
            for (index, item) in defaultSectionItems.enumerated() {
                if item.type == .savedPosts {
                    return IndexPath(row: index, section: sectionIndex)
                }
            }
        }

        return nil
    }
}


extension ReaderMenuViewModel: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        var section: Int?
        if controller == defaultsFetchedResultsController {
            // Rebuild the defaults section since its source content changed.
            buildDefaultSectionItems()
            if let index = indexOfSectionWithType(.defaults) {
                section = index
            }

        } else if controller == teamsFetchedResultsController {
            if let index = indexOfSectionWithType(.teams) {
                section = index
            }

        } else if controller == listsFetchedResultsController {
            if let index = indexOfSectionWithType(.lists) {
                section = index
            }

        } else if controller == tagsFetchedResultsController {
            if let index = indexOfSectionWithType(.tags) {
                section = index
            }
        }

        if let section = section {
            delegate?.menuSectionDidChangeContent(section)

        } else {
            // One of the results controllers updated its content but that controller is not currently
            // included in the list of sections.
            // We need to update our sections then notify the delegate that content was reloaded.
            setupSections()
            delegate?.menuDidReloadContent()
        }

    }

}
