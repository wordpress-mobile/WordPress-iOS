/// Encapsulates logic related to content migration from WordPress to Jetpack.
///
@objc class ContentMigrationCoordinator: NSObject {

    @objc static var shared: ContentMigrationCoordinator = {
        .init()
    }()

    var storedExportErrorDescription: String? {
        sharedPersistentRepository?.string(forKey: .exportErrorSharedKey)
    }

    // MARK: Dependencies

    private let coreDataStack: CoreDataStack
    private let dataMigrator: ContentDataMigrating
    private let notificationCenter: NotificationCenter
    private let userPersistentRepository: UserPersistentRepository
    private let sharedPersistentRepository: UserPersistentRepository?
    private let eligibilityProvider: ContentMigrationEligibilityProvider
    private let tracker: MigrationAnalyticsTracker

    init(coreDataStack: CoreDataStack = ContextManager.shared,
         dataMigrator: ContentDataMigrating = DataMigrator(),
         notificationCenter: NotificationCenter = .default,
         userPersistentRepository: UserPersistentRepository = UserDefaults.standard,
         sharedPersistentRepository: UserPersistentRepository? = UserDefaults(suiteName: WPAppGroupName),
         eligibilityProvider: ContentMigrationEligibilityProvider = AppConfiguration(),
         tracker: MigrationAnalyticsTracker = .init()) {
        self.coreDataStack = coreDataStack
        self.dataMigrator = dataMigrator
        self.notificationCenter = notificationCenter
        self.userPersistentRepository = userPersistentRepository
        self.sharedPersistentRepository = sharedPersistentRepository
        self.eligibilityProvider = eligibilityProvider
        self.tracker = tracker

        super.init()

        // register for account change notification.
        ensureBackupDataDeletedOnLogout()
    }

    enum ContentMigrationCoordinatorError: LocalizedError {
        case ineligible
        case exportFailure
        case localDraftsNotSynced

        var errorDescription: String? {
            switch self {
            case .ineligible: return "Content export is ineligible"
            case .exportFailure: return "Content export failed"
            case .localDraftsNotSynced: return "Local drafts not synced"
            }
        }
    }

    // MARK: Methods

    /// Starts the content migration process of exporting app data to the shared location
    /// that will be accessible by the Jetpack app.
    ///
    /// The completion block is intentionally called regardless of whether the export process
    /// succeeds or fails. Since the export process consists of local file operations, we should
    /// just let the user continue with the original intent in case of failure.
    ///
    /// - Parameter completion: Closure called after the export process completes.
    func startAndDo(completion: ((Result<Void, ContentMigrationCoordinatorError>) -> Void)? = nil) {
        guard eligibilityProvider.isEligibleForMigration else {
            tracker.trackContentExportEligibility(eligible: false)
            processResult(.failure(.ineligible), completion: completion)
            return
        }

        guard isLocalPostsSynced() else {
            let error = ContentMigrationCoordinatorError.localDraftsNotSynced
            tracker.trackContentExportFailed(reason: error.localizedDescription)
            processResult(.failure(error), completion: completion)
            return
        }

        dataMigrator.exportData { [weak self] result in
            switch result {
            case .success:
                self?.tracker.trackContentExportSucceeded()
                self?.processResult(.success(()), completion: completion)

            case .failure(let error):
                DDLogError("[Jetpack Migration] Error exporting data: \(error)")
                self?.tracker.trackContentExportFailed(reason: error.localizedDescription)
                self?.processResult(.failure(.exportFailure), completion: completion)
            }
        }
    }

    /// Starts the content migration process from WordPress to Jetpack.
    /// This method ensures that the migration will only be executed once per installation,
    /// and only performed when all the conditions are fulfilled.
    ///
    /// Note: If the conditions are not fulfilled, this method will attempt to migrate
    /// again on the next call.
    ///
    func startOnceIfNeeded(completion: (() -> Void)? = nil) {
        if userPersistentRepository.bool(forKey: .oneOffMigrationKey) {
            completion?()
            return
        }

        startAndDo { [weak self] result in
            if case .success = result {
                self?.userPersistentRepository.set(true, forKey: .oneOffMigrationKey)
            }

            completion?()
        }
    }

    /// Attempts to clean up the exported data by re-exporting user content if they're still eligible, or deleting them otherwise.
    /// Re-exporting user content ensures that the exported data will match the latest state of Account and Blogs.
    ///
    @objc func cleanupExportedDataIfNeeded() {
        // try to re-export the user content if they're still eligible.
        startAndDo { [weak self] result in
            switch result {
            case .failure(let error) where error == .ineligible:
                // if the user is no longer eligible, ensure that any exported contents are deleted.
                self?.dataMigrator.deleteExportedData()
            default:
                break
            }
        }
    }
}

// MARK: - Private Helpers

private extension ContentMigrationCoordinator {

    func isLocalPostsSynced() -> Bool {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = NSPredicate(format: "remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@",
                                             NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.failed.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.local.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
        guard let count = try? coreDataStack.mainContext.count(for: fetchRequest) else {
            return false
        }

        return count == 0
    }

    /// When the user logs out, ensure that any exported data is deleted if it exists at the backup location.
    /// This prevents the user from entering the migration flow and immediately gets shown with a login pop-up (since we couldn't migrate the authToken anymore).
    ///
    func ensureBackupDataDeletedOnLogout() {
        notificationCenter.addObserver(forName: .WPAccountDefaultWordPressComAccountChanged, object: nil, queue: nil) { [weak self] notification in
            // nil notification object means it's a logout event.
            guard let self,
                  notification.object == nil else {
                return
            }

            self.cleanupExportedDataIfNeeded()
        }
    }

    /// A "middleware" logic that attempts to record (or clear) any migration error to the App Group space
    /// before calling the completion block.
    ///
    /// - Parameters:
    ///   - result: The `Result` object from the export process.
    ///   - completion: Closure that'll be executed after the process completes.
    func processResult(_ result: Result<Void, ContentMigrationCoordinatorError>, completion: ((Result<Void, ContentMigrationCoordinatorError>) -> Void)?) {
        switch result {
        case .success:
            sharedPersistentRepository?.removeObject(forKey: .exportErrorSharedKey)

        case .failure(let error):
            guard let description = error.errorDescription else {
                break
            }
            sharedPersistentRepository?.set(description, forKey: .exportErrorSharedKey)
        }

        completion?(result)
    }
}

// MARK: - Content Migration Eligibility Provider

protocol ContentMigrationEligibilityProvider {
    /// Determines if we should export user's content data in the current app state.
    var isEligibleForMigration: Bool { get }
}

extension AppConfiguration: ContentMigrationEligibilityProvider {
    var isEligibleForMigration: Bool {
        FeatureFlag.contentMigration.enabled && Self.isWordPress && AccountHelper.isLoggedIn && AccountHelper.hasBlogs
    }
}

// MARK: - Constants

private extension String {
    static let oneOffMigrationKey = "wordpress_one_off_export"
    static let exportErrorSharedKey = "wordpress_shared_export_error"
}
