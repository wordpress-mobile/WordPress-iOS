import Foundation
import Gridicons


/// Enum of the sections shown in the reader.
///
enum ReaderMenuSectionType: Int {
    case Defaults
    case Lists
    case Tags
}


/// Enum of the types of row items shown in the reader.
///
enum ReaderMenuItemType: Int {
    case Topic
    case Search
    case Recommended
    case AddItem
}


/// Represents a section in the Reader's menu.
///
struct ReaderMenuSection {
    let title: String
    let type: ReaderMenuSectionType
}


/// Represents an row, or menu item in a reader menu section.
///
struct ReaderMenuItem
{
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


/// Protocol allowing a reader menu view model to notify content changes.
///
protocol ReaderMenuViewModelDelegate
{

    /// Notifies the delegate that the menu did reload its content.
    ///
    func menuDidReloadContent()


    /// Notifies the delegate that the content of the specified section has changed.
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    func menuSectionDidChangeContent(index: Int)
}


/// Defines the preferred order of items in the default section.
///
enum ReaderDefaultMenuItemOrder: Int {
    case Followed
    case Discover
    case Search
    case Recommendations
    case Likes
    case Other
}


/// The view model used by the reader.
///
@objc class ReaderMenuViewModel: NSObject
{
    var defaultsFetchedResultsController: NSFetchedResultsController!
    var listsFetchedResultsController: NSFetchedResultsController!
    var tagsFetchedResultsController: NSFetchedResultsController!

    var sections = [ReaderMenuSection]()
    var defaultSectionItems = [ReaderMenuItem]()
    var delegate: ReaderMenuViewModelDelegate?


    // MARK: - Lifecycle Methods


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override init() {
        super.init()
        listenForWordPressAccountChanged()
        setupResultsControllers()
        setupSections()
    }


    func listenForWordPressAccountChanged() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReaderMenuViewModel.handleWordPressComAccountChanged(_:)), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
    }


    // MARK: - Setup


    /// Sets up the results controllers.
    ///
    func setupResultsControllers() {
        setupDefaultResultsController()
        setupListResultsController()
        setupTagsResultsController()
    }


    /// Sets up the sections. This should be called only once during init, or when
    /// the user signs in / out of wpcom.
    /// Call the section setup methods in the order the sections should appear
    /// in the menu.
    ///
    func setupSections() {
        // Clear anything that's cached.
        sections.removeAll()

        // Rebuild!
        setupDefaultsSection()

        if ReaderHelpers.isLoggedIn() {
            setupListsSection()
        }

        setupTagsSection()
    }


    // MARK: - Default Section


    /// Sets up the default fetched results controller.
    ///
    func setupDefaultResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "ReaderDefaultTopic")
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
            DDLogSwift.logError("There was a problem fetching default topics for the menu.")
            assertionFailure("There was a problem fetching default topics.")
        }
    }


    /// Sets up the defaults section and its corresponding NSFetchedResultsController.
    ///
    func setupDefaultsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Streams", comment:"Section title of the default reader items."), type: .Defaults)
        sections.append(section)

        buildDefaultSectionItems()
    }


    /// Builds (or rebuilds) the items for the default menu section.
    /// Since the default section shows items representing things other than topics,
    /// we construct and cache menu items in an array with the desired item order.
    ///
    func buildDefaultSectionItems() {
        defaultSectionItems.removeAll()

        // Create menu items from the fetched results
        if let fetchedObjects = defaultsFetchedResultsController.fetchedObjects {
            for topic in fetchedObjects {
                guard let abstractTopic = topic as? ReaderAbstractTopic else {
                    continue
                }

                var item = ReaderMenuItem(title: topic.title, type: .Topic, icon: nil, topic: abstractTopic)
                if ReaderHelpers.topicIsFollowing(abstractTopic) {
                    item.order = ReaderDefaultMenuItemOrder.Followed.rawValue
                    item.icon = Gridicon.iconOfType(.CheckmarkCircle)
                } else if ReaderHelpers.topicIsDiscover(abstractTopic) {
                    item.order = ReaderDefaultMenuItemOrder.Discover.rawValue
                    item.icon = Gridicon.iconOfType(.MySites)
                } else if ReaderHelpers.topicIsLiked(abstractTopic) {
                    item.order = ReaderDefaultMenuItemOrder.Likes.rawValue
                    item.icon = Gridicon.iconOfType(.Star)
                } else {
                    item.order = ReaderDefaultMenuItemOrder.Other.rawValue
                }
                defaultSectionItems.append(item)
            }
        }

        // Create a menu item for search
        var searchItem = searchMenuItem()
        searchItem.order = ReaderDefaultMenuItemOrder.Search.rawValue
        searchItem.icon = Gridicon.iconOfType(.Search)
        defaultSectionItems.append(searchItem)

        // Sort the items into the desired order.
        defaultSectionItems.sortInPlace { (menuItem1, menuItem2) -> Bool in
            if menuItem1.order < menuItem2.order {
                return true
            }

            if menuItem1.order > menuItem2.order {
                return false
            }

            if menuItem1.title < menuItem2.title {
                return true
            }

            return false
        }
    }


    /// Returns the menu item to use for the reader search
    ///
    func searchMenuItem() -> ReaderMenuItem {
        let title = NSLocalizedString("Search", comment: "Title of the reader's Search menu item.")
        return ReaderMenuItem(title: title, type: .Search)
    }


    /// Returns the number of items for the default section.
    ///
    /// - Returns: The number of items in the section.
    ///
    func itemCountForDefaultSection() -> Int {
        return defaultSectionItems.count
    }


    /// Returns the menu item from the default section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForDefaultAtIndex(index: Int) -> ReaderMenuItem? {
        return defaultSectionItems[index]
    }


    // MARK: - List Section


    /// Sets up the list fetched results controller
    ///
    func setupListResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "ReaderListTopic")
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
    func updateAndPerformListsFetchRequest() {
        listsFetchedResultsController.fetchRequest.predicate = predicateForRequests()
        do {
            let _ = try listsFetchedResultsController.performFetch()
        } catch {
            DDLogSwift.logError("There was a problem fetching list topics for the menu.")
            assertionFailure("There was a problem fetching list topics.")
        }
    }


    /// Sets up the lists section and its corresponding NSFetchedResultsController.
    ///
    func setupListsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Lists", comment:"Section title of the lists reader section."), type: .Lists)
        sections.append(section)
    }


    /// Returns the number of items for the lists section.
    ///
    /// - Returns: The number of items in the section.
    ///
    func itemCountForListSection() -> Int {
        return listsFetchedResultsController.fetchedObjects?.count ?? 0
    }


    /// Returns the menu item from the lists section at the specified index.
    ///
    /// - Parameters:
    ///     - index: The index of the item.
    ///
    /// - Returns: The requested menu item or nil.
    ///
    func menuItemForListAtIndex(index: Int) -> ReaderMenuItem? {
        guard let topic = listsFetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? ReaderAbstractTopic else {
            return nil
        }
        return ReaderMenuItem(title: topic.title, type: .Topic, icon: nil, topic: topic)
    }


    // MARK: - Tags Section


    /// Sets up the tags fetched results controller
    ///
    func setupTagsResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "ReaderTagTopic")
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
            DDLogSwift.logError("There was a problem fetching tag topics for the menu.")
            assertionFailure("There was a problem fetching tag topics.")
        }
    }


    /// Updates the lists results controller's fetch request predicate and performs a new fetch
    ///
    func updateAndPerformTagsFetchRequest() {
        tagsFetchedResultsController.fetchRequest.predicate = predicateForRequests()
        do {
            let _ = try tagsFetchedResultsController.performFetch()
        } catch {
            DDLogSwift.logError("There was a problem fetching tag topics for the menu.")
            assertionFailure("There was a problem fetching tag topics.")
        }
    }


    /// Sets up the tags section and its corresponding NSFetchedResultsController.
    ///
    func setupTagsSection() {
        let section = ReaderMenuSection(title: NSLocalizedString("Tags", comment:"Section title of the tags reader section."), type: .Tags)
        sections.append(section)
    }


    /// Returns the number of items for the tags section.
    ///
    /// - Returns: The number of items in the section.
    ///
    func itemCountForTagSection() -> Int {
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
    func menuItemForTagAtIndex(index: Int) -> ReaderMenuItem? {
        var fetchedIndex = index
        if ReaderHelpers.isLoggedIn() {
            if fetchedIndex == 0 {
                let title = NSLocalizedString("Add a Tag", comment: "Title. Lets the user know that they can use this feature to subscribe to new tags.")
                return ReaderMenuItem(title: title, type: .AddItem)
            } else {
                // Adjust the index by one to account for AddItem
                fetchedIndex -= 1
            }
        }

        guard let topic = tagsFetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: fetchedIndex, inSection: 0)) as? ReaderAbstractTopic else {
            return nil
        }
        return ReaderMenuItem(title: topic.title, type: .Topic, icon: nil, topic: topic)
    }


    // MARK: - Helper Methods


    /// Returns the predicate for tag and list fetch requests.
    ///
    /// - Returns: An NSPredicate
    ///
    func predicateForRequests() -> NSPredicate {
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
    func handleWordPressComAccountChanged(notification: NSNotification) {
        // TODO: We need to ensure we have no stale topics in core data prior to reloading content.

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
    func numberOfSectionsInMenu() -> Int {
        return sections.count
    }


    /// Retuns the index of the section with the specified type.
    ///
    /// - Paramters:
    ///     - type: The type of the section.
    ///
    /// - Return: The index of the section or nil if it was not found.
    ///
    func indexOfSectionWithType(type: ReaderMenuSectionType) -> Int? {
        for (index, section) in sections.enumerate() {
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
    func numberOfItemsInSection(index: Int) -> Int {
        let section = sections[index]

        switch section.type {
        case .Defaults:
            return itemCountForDefaultSection()

        case .Lists:
            return itemCountForListSection()

        case .Tags:
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
    func titleForSection(index: Int) -> String {
        return sections[index].title
    }


    /// Returns the type for the specified section
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The type of the section.
    ///
    func typeOfSection(index: Int) -> ReaderMenuSectionType {
        return sections[index].type
    }


    /// Returns the section info for the specified section
    ///
    /// - Parameters:
    ///     - index: The index of the section.
    ///
    /// - Returns: The section info.
    ///
    func sectionInfoAtIndex(index: Int) -> ReaderMenuSection {
        return sections[index]
    }


    /// Returns the menu item for the specified section and row
    ///
    /// - Parameters:
    ///     - index: The indexPath of the item.
    ///
    /// - Returns: The menu item for the specified index path.
    ///
    func menuItemAtIndexPath(indexPath: NSIndexPath) -> ReaderMenuItem? {
        let section = sections[indexPath.section]

        switch section.type {
        case .Defaults:
            return menuItemForDefaultAtIndex(indexPath.row)

        case .Lists:
            return menuItemForListAtIndex(indexPath.row)

        case .Tags:
            return menuItemForTagAtIndex(indexPath.row)
        }
    }


    /// Get the indexPath of the specified tag
    ///
    /// - Parameters:
    ///     tag: The tag topic to find.
    ///
    /// - Returns: An NSIndexPath optional.
    ///
    func indexPathOfTag(tag: ReaderTagTopic) -> NSIndexPath? {
        if let indexPath = tagsFetchedResultsController.indexPathForObject(tag) {
            var row = indexPath.row
            if ReaderHelpers.isLoggedIn() {
                row += 1
            }
            return NSIndexPath(forRow: row, inSection: indexOfSectionWithType(.Tags)!)
        }
        return nil
    }
}


extension ReaderMenuViewModel: NSFetchedResultsControllerDelegate
{

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        var section: Int = 0
        if controller == defaultsFetchedResultsController {
            // Rebuild the defaults section since its source content changed.
            buildDefaultSectionItems()
            if let index = indexOfSectionWithType(.Defaults) {
                section = index
            }

        } else if controller == listsFetchedResultsController {
            if let index = indexOfSectionWithType(.Lists) {
                section = index
            }

        } else if controller == tagsFetchedResultsController {
            if let index = indexOfSectionWithType(.Tags) {
                section = index
            }
        }

        delegate?.menuSectionDidChangeContent(section)
    }

}
