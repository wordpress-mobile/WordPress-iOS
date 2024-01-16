import Foundation
import UIKit
import SwiftUI
import Gridicons
import WordPressShared
import SVProgressHUD
import WordPressFlux
import DesignSystem

class AppSettingsViewController: UITableViewController {
    fileprivate var handler: ImmuTableViewHandler!

    // MARK: - Dependencies

    private let privacySettingsAnalyticsTracker = PrivacySettingsAnalyticsTracker()

    // MARK: - Initialization

    override init(style: UITableView.Style) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("App Settings", comment: "App Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .insetGrouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            BrandedNavigationRow.self,
            DestructiveButtonRow.self,
            TextRow.self,
            ImageSizingRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        addAccountSettingsChangedObserver()

        tableView.accessibilityIdentifier = "appSettingsTable"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMediaCacheSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerUserActivity()
    }

    private func addAccountSettingsChangedObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountSettingsDidChange(_:)), name: NSNotification.Name.AccountSettingsChanged, object: nil)
    }

    @objc
    private func accountSettingsDidChange(_ notification: Notification) {
        reloadViewModel()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let tableSections = [
            mediaTableSection(),
            privacyTableSection(),
            otherTableSection()
        ]
        return ImmuTable(optionalSections: tableSections)
    }

    // MARK: - Media cache methods

    fileprivate enum MediaCacheSettingsStatus {
        case calculatingSize
        case clearingCache
        case unknown
        case empty
    }

    fileprivate var mediaCacheRowDescription = "" {
        didSet {
            reloadViewModel()
        }
    }

    fileprivate func setMediaCacheRowDescription(allocatedSize: Int64?) {
        guard let allocatedSize = allocatedSize else {
            setMediaCacheRowDescription(status: .unknown)
            return
        }
        if allocatedSize == 0 {
            setMediaCacheRowDescription(status: .empty)
            return
        }
        mediaCacheRowDescription = ByteCountFormatter.string(fromByteCount: allocatedSize, countStyle: ByteCountFormatter.CountStyle.file)
    }

    fileprivate func setMediaCacheRowDescription(status: MediaCacheSettingsStatus) {
        switch status {
        case .clearingCache:
            mediaCacheRowDescription = NSLocalizedString("Clearing...", comment: "Label for size of media while it's being cleared.")
        case .calculatingSize:
            mediaCacheRowDescription = NSLocalizedString("Calculating...", comment: "Label for size of media while it's being calculated.")
        case .unknown:
            mediaCacheRowDescription = NSLocalizedString("Unknown", comment: "Label for size of media when it's not possible to calculate it.")
        case .empty:
            mediaCacheRowDescription = NSLocalizedString("Empty", comment: "Label for size of media when the cache is empty.")
        }
    }

    fileprivate func updateMediaCacheSize() {
        setMediaCacheRowDescription(status: .calculatingSize)
        MediaFileManager.calculateSizeOfMediaDirectories { [weak self] (allocatedSize) in
            self?.setMediaCacheRowDescription(allocatedSize: allocatedSize)
        }
    }

    // MARK: - Navigation

    func navigateToPrivacySettings(animated: Bool = true, completion: ((PrivacySettingsViewController) -> Void)? = nil) {
        let destination = PrivacySettingsViewController(style: .insetGrouped)
        CATransaction.perform {
            self.navigationController?.pushViewController(destination, animated: animated)
            self.privacySettingsAnalyticsTracker.track(.privacySettingsOpened)
        } completion: {
            completion?(destination)
        }
    }

    // MARK: - Actions

    @objc func imageSizeChanged() -> (Int) -> Void {
        return { value in
            MediaSettings().maxImageSizeSetting = value
            ShareExtensionService.configureShareExtensionMaximumMediaDimension(value)

            self.debounce(#selector(self.trackImageSizeChanged), afterDelay: 0.5)
        }
    }

    @objc func trackImageSizeChanged() {
        let value = MediaSettings().maxImageSizeSetting
        WPAnalytics.track(.appSettingsMaxImageSizeChanged, properties: ["size": value])
    }

    func pushVideoResolutionSettings() -> ImmuTableAction {
        return { [weak self] row in
            let values = [MediaSettings.VideoResolution.size640x480,
                          MediaSettings.VideoResolution.size1280x720,
                          MediaSettings.VideoResolution.size1920x1080,
                          MediaSettings.VideoResolution.size3840x2160,
                          MediaSettings.VideoResolution.sizeOriginal]

            let titles = values.map { $0.description }
            let currentVideoResolution = MediaSettings().maxVideoSizeSetting

            let settingsSelectionConfiguration = [SettingsSelectionDefaultValueKey: currentVideoResolution,
                                                  SettingsSelectionTitleKey: NSLocalizedString("Resolution", comment: "The largest resolution allowed for uploading"),
                                                  SettingsSelectionTitlesKey: titles,
                                                  SettingsSelectionValuesKey: values] as [String: Any]

            let viewController = SettingsSelectionViewController(dictionary: settingsSelectionConfiguration)

            viewController?.onItemSelected = { (resolution: Any!) -> () in
                let newResolution = resolution as! MediaSettings.VideoResolution
                MediaSettings().maxVideoSizeSetting = newResolution

                var properties = [String: AnyObject]()
                properties["enabled"] = (newResolution != MediaSettings.VideoResolution.sizeOriginal) as AnyObject
                properties["value"] = newResolution.description as AnyObject
                WPAnalytics.track(.appSettingsVideoOptimizationChanged, withProperties: properties)
            }

            self?.navigationController?.pushViewController(viewController!, animated: true)
        }
    }

    func pushImageQualitySettings() -> ImmuTableAction {
        return { [weak self] row in
            let values = [MediaSettings.ImageQuality.low,
                          MediaSettings.ImageQuality.medium,
                          MediaSettings.ImageQuality.high,
                          MediaSettings.ImageQuality.maximum]

            let titles = values.map { $0.description }
            let currentImageQuality = MediaSettings().imageQualitySetting
            let title = NSLocalizedString("appSettings.media.imageQuality.title", value: "Quality", comment: "The quality of image used when uploading")

            let settingsSelectionConfiguration = [SettingsSelectionDefaultValueKey: currentImageQuality,
                                                         SettingsSelectionTitleKey: title,
                                                        SettingsSelectionTitlesKey: titles,
                                                        SettingsSelectionValuesKey: values] as [String: Any]

            let viewController = SettingsSelectionViewController(dictionary: settingsSelectionConfiguration)

            viewController?.onItemSelected = { quality in
                let newQuality = quality as! MediaSettings.ImageQuality
                MediaSettings().imageQualitySetting = newQuality

                // Track setting changes
                WPAnalytics.track(.appSettingsImageQualityChanged, properties: ["quality": newQuality.description])
            }

            self?.navigationController?.pushViewController(viewController!, animated: true)
        }
    }

    func openMediaCacheSettings() -> ImmuTableAction {
        return { [weak self] _ in
            let controller = MediaCacheSettingsViewController(style: .insetGrouped)
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc func mediaRemoveLocationChanged() -> (Bool) -> Void {
        return { value in
            MediaSettings().removeLocationSetting = value
            WPAnalytics.track(.appSettingsMediaRemoveLocationChanged, withProperties: ["enabled": value as AnyObject])
        }
    }

    func imageOptimizationChanged() -> (Bool) -> Void {
        return { [weak self] value in
            MediaSettings().imageOptimizationEnabled = value

            // Track setting changes
            WPAnalytics.track(.appSettingsOptimizeImagesChanged, properties: ["enabled": value])

            // Show/hide image optimization settings
            guard let self, let tableView else {
                return
            }
            tableView.performBatchUpdates {
                let originalAutomaticallyReloadTableView = self.handler.automaticallyReloadTableView
                self.handler.automaticallyReloadTableView = false
                self.reloadViewModel()
                self.handler.automaticallyReloadTableView = originalAutomaticallyReloadTableView

                tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }
        }
    }

    func pushAppearanceSettings() -> ImmuTableAction {
        return { [weak self] row in
            let values = UIUserInterfaceStyle.allStyles

            let rawValues = values.map({ $0.rawValue })
            let titles = values.map({ $0.appearanceDescription })

            let currentStyle = AppAppearance.current

            let settingsSelectionConfiguration = [SettingsSelectionDefaultValueKey: AppAppearance.default.rawValue,
                                                  SettingsSelectionCurrentValueKey: currentStyle.rawValue,
                                                  SettingsSelectionTitleKey: NSLocalizedString("Appearance", comment: "The title of the app appearance settings screen"),
                                                  SettingsSelectionTitlesKey: titles,
                                                  SettingsSelectionValuesKey: rawValues] as [String: Any]

            let viewController = SettingsSelectionViewController(dictionary: settingsSelectionConfiguration)

            viewController?.onItemSelected = { [weak self] (style: Any!) -> () in
                guard let style = style as? Int,
                    let newStyle = UIUserInterfaceStyle(rawValue: style) else {
                        return
                }

                self?.overrideAppAppearance(with: newStyle)
            }

            self?.navigationController?.pushViewController(viewController!, animated: true)
        }
    }

    private func overrideAppAppearance(with style: UIUserInterfaceStyle) {
        let transitionView: UIView = WordPressAppDelegate.shared?.window ?? view
        UIView.transition(with: transitionView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {
                            AppAppearance.overrideAppearance(with: style)
        })
    }

    func pushDebugMenu() -> ImmuTableAction {
        return { [weak self] row in
            let controller = DebugMenuViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushDesignSystemGallery() -> ImmuTableAction {
        return { [weak self] row in
            let controller = UIHostingController(rootView: DesignSystemGallery())
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushAppIconSwitcher() -> ImmuTableAction {
        return { [weak self] row in
            let controller = AppIconViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openPrivacySettings() -> ImmuTableAction {
        return { [weak self] _ in
            self?.navigateToPrivacySettings(animated: true)
        }
    }

    func openApplicationSettings() -> ImmuTableAction {
        return { [weak self] row in
            WPAnalytics.track(.appSettingsOpenDeviceSettingsTapped)

            if let targetURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(targetURL)

            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self?.tableView.deselectSelectedRowWithAnimation(true)
        }
    }

    func clearSiriActivityDonations() -> ImmuTableAction {
        return { [tableView] _ in
            WPAnalytics.track(.appSettingsClearSiriSuggestionsTapped)

            tableView?.deselectSelectedRowWithAnimation(true)

            NSUserActivity.deleteAllSavedUserActivities {}

            let notice = Notice(title: NSLocalizedString("Siri Reset Confirmation", value: "Successfully cleared Siri Shortcut Suggestions", comment: "Notice displayed to the user after clearing the Siri activity donations."), feedbackType: .success)
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }

    func clearSpotlightCache() -> ImmuTableAction {
        return { [weak self] row in
            WPAnalytics.track(.appSettingsClearSpotlightIndexTapped)

            self?.tableView.deselectSelectedRowWithAnimation(true)
            SearchManager.shared.deleteAllSearchableItems()
            let notice = Notice(title: NSLocalizedString("Successfully cleared spotlight index", comment: "Notice displayed to the user after clearing the spotlight index in app settings."),
                                feedbackType: .success)
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }

    func presentWhatIsNew() -> ImmuTableAction {
        return { [weak self] row in
            guard let self = self else {
                return
            }
            self.tableView.deselectSelectedRowWithAnimation(true)
            RootViewCoordinator.shared.presentWhatIsNew(on: self)
        }
    }
}

// MARK: - SearchableActivity Conformance

extension AppSettingsViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.appSettings.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("App Settings", comment: "Title of the 'App Settings' screen within the 'Me' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, me, app settings, settings, cache, media, about, upload, usage, statistics",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Me' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}

// MARK: - Private ImmuTableRow Definitions

fileprivate struct ImageSizingRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let title: String
    let value: Int
    let onChange: (Int) -> Void

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.title = title
        cell.value = value
        cell.onChange = onChange
        cell.selectionStyle = .none

        (cell.minValue, cell.maxValue) = MediaSettings().allowedImageSizeRange
    }
}

// MARK: - Table Sections Private Extension
private extension AppSettingsViewController {
    func mediaTableSection() -> ImmuTableSection {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")

        let imageOptimizationValue = MediaSettings().imageOptimizationEnabled
        let imageOptimization = SwitchRow(
            title: NSLocalizedString("appSettings.media.imageOptimizationRow", value: "Optimize Images", comment: "Option to enable the optimization of images when uploading."),
            value: imageOptimizationValue,
            onChange: imageOptimizationChanged(),
            accessibilityIdentifier: "imageOptimizationSwitch"
        )

        let imageSizingRow = ImageSizingRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: imageSizeChanged())

        let imageQualityRow = NavigationItemRow(
            title: NSLocalizedString("appSettings.media.imageQualityRow", value: "Image Quality", comment: "Title for the image quality settings option."),
            detail: MediaSettings().imageQualitySetting.description,
            action: pushImageQualitySettings())

        let videoSizingRow = NavigationItemRow(
            title: NSLocalizedString("Max Video Upload Size", comment: "Title for the video size settings option."),
            detail: MediaSettings().maxVideoSizeSetting.description,
            action: pushVideoResolutionSettings())

        let mediaCacheRow = NavigationItemRow(
            title: NSLocalizedString("Media Cache", comment: "Label for the media cache navigation row in the app."),
            detail: mediaCacheRowDescription,
            action: openMediaCacheSettings())

        let rows: [ImmuTableRow] = imageOptimizationValue ? [
            imageOptimization,
            imageSizingRow,
            imageQualityRow,
            videoSizingRow,
            mediaCacheRow
        ] : [
            imageOptimization,
            videoSizingRow,
            mediaCacheRow
        ]

        return ImmuTableSection(
            headerText: mediaHeader,
            rows: rows,
            footerText: NSLocalizedString("Free up storage space on this device by deleting temporary media files. This will not affect the media on your site.",
                                          comment: "Explanatory text for clearing device media cache.")
        )
    }

    func privacyTableSection() -> ImmuTableSection {
        let privacyHeader = NSLocalizedString("Privacy", comment: "Privacy settings section header")

        let mediaRemoveLocation = SwitchRow(
            title: NSLocalizedString("Remove Location From Media", comment: "Option to enable the removal of location information/gps from photos and videos"),
            value: Bool(MediaSettings().removeLocationSetting),
            onChange: mediaRemoveLocationChanged()
        )

        let privacySettings = NavigationItemRow(
            title: NSLocalizedString("Privacy Settings", comment: "Link to privacy settings page"),
            action: openPrivacySettings()
        )

        let spotlightClearCacheRow = BrandedNavigationRow(
            title: NSLocalizedString("Clear Spotlight Index", comment: "Label for button that clears the spotlight index on device."),
            action: clearSpotlightCache(),
            accessibilityIdentifier: "spotlightClearCacheButton")

        var tableRows: [ImmuTableRow] = [
            privacySettings,
            spotlightClearCacheRow
        ]

        let siriClearCacheRow = BrandedNavigationRow(
            title: NSLocalizedString("Siri Reset Prompt", value: "Clear Siri Shortcut Suggestions", comment: "Label for button that clears user activities donated to Siri."),
            action: clearSiriActivityDonations(),
            accessibilityIdentifier: "spotlightClearCacheButton")

        tableRows.append(siriClearCacheRow)

        tableRows.append(mediaRemoveLocation)
        let removeLocationFooterText = NSLocalizedString("Removes location metadata from photos before uploading them to your site.", comment: "Explanatory text for removing the location from uploaded media.")

        return ImmuTableSection(
            headerText: privacyHeader,
            rows: tableRows,
            footerText: removeLocationFooterText
        )
    }

    func otherTableSection() -> ImmuTableSection {
        let otherHeader = NSLocalizedString("Other", comment: "Link to About section (contains info about the app)")

        let debugRow = NavigationItemRow(
            title: NSLocalizedString("Debug", comment: "Navigates to debug menu only available in development builds"),
            icon: .gridicon(.bug),
            action: pushDebugMenu()
        )

        let designSystem = NavigationItemRow(
            title: NSLocalizedString("Design System", comment: "Navigates to design system gallery only available in development builds"),
            icon: UIImage(systemName: "paintpalette"),
            action: pushDesignSystemGallery()
        )

        let iconRow = NavigationItemRow(
            title: NSLocalizedString("App Icon", comment: "Navigates to picker screen to change the app's icon"),
            action: pushAppIconSwitcher()
        )

        let settingsRow = NavigationItemRow(
            title: NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for WordPress App"),
            action: openApplicationSettings()
        )

        var rows: [ImmuTableRow] = [settingsRow]

        if AppConfiguration.allowsCustomAppIcons && UIApplication.shared.supportsAlternateIcons {
            // We don't show custom icons for Jetpack
            rows.insert(iconRow, at: 0)
        }

        if FeatureFlag.debugMenu.enabled {
            rows.append(debugRow)
            rows.append(designSystem)
        }

        if let presenter = RootViewCoordinator.shared.whatIsNewScenePresenter as? WhatIsNewScenePresenter,
            presenter.versionHasAnnouncements,
            AppConfiguration.showsWhatIsNew {
            let whatIsNewRow = NavigationItemRow(title: AppConstants.Settings.whatIsNewTitle,
                                                 action: presentWhatIsNew())
            rows.append(whatIsNewRow)
        }

        let appearanceRow = NavigationItemRow(title: NSLocalizedString("Appearance", comment: "The title of the app appearance settings screen"), detail: AppAppearance.current.appearanceDescription, action: pushAppearanceSettings())

        rows.insert(appearanceRow, at: 0)

        return ImmuTableSection(
            headerText: otherHeader,
            rows: rows,
            footerText: nil)
    }
}

// MARK: - Jetpack powered badge
extension AppSettingsViewController {

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == handler.viewModel.sections.count - 1,
              JetpackBrandingVisibility.all.enabled else {
            return nil
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.appSettings)
        let jetpackButton = JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                                        target: self,
                                                        selector: #selector(jetpackButtonTapped))

        return jetpackButton
    }

    @objc private func jetpackButtonTapped() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .appSettings)
    }
}
