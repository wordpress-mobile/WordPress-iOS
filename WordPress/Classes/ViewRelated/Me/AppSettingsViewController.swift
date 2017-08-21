import Foundation
import UIKit
import Gridicons
import WordPressShared
import SVProgressHUD

class AppSettingsViewController: UITableViewController {
    enum Sections: Int {
        case media
        case editor
        case other
    }

    fileprivate var handler: ImmuTableViewHandler!

    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("App Settings", comment: "App Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AppSettingsEditorFooterView.self,
                           forHeaderFooterViewReuseIdentifier: AppSettingsEditorFooterView.reuseIdentifier)

        ImmuTable.registerRows([
            DestructiveButtonRow.self,
            TextRow.self,
            ImageSizingRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMediaCacheSize()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")
        let imageSizingRow = ImageSizingRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: imageSizeChanged())
        
        let videoSizingRow = NavigationItemRow(
            title: NSLocalizedString("Max Video Upload Size", comment: "Title for the video size settings option."),
            action: pushVideoResolutionSettings())

        let mediaRemoveLocation = SwitchRow(
            title: NSLocalizedString("Remove Location From Media", comment: "Option to enable the removal of location information/gps from photos and videos"),
            value: Bool(MediaSettings().removeLocationSetting),
            onChange: mediaRemoveLocationChanged()
        )

        let mediaCacheRow = TextRow(title: NSLocalizedString("Media Cache Size", comment: "Label for size of media cache in the app."),
                                    value: mediaCacheRowDescription)

        let mediaClearCacheRow = DestructiveButtonRow(
            title: NSLocalizedString("Clear Media Cache", comment: "Label for button that clears all media cache."),
            action: { [weak self] row in
                self?.clearMediaCache()
            },
            accessibilityIdentifier: "mediaClearCacheButton")

        let editorSettings = EditorSettings()
        let editorHeader = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        var editorRows = [ImmuTableRow]()

        let editor = editorSettings.editor

        let textEditor = CheckmarkRow(
            title: NSLocalizedString("Plain Text", comment: "Option to enable the plain text (legacy) editor"),
            checked: (editor == .legacy),
            action: visualEditorChanged(editor: .legacy)
        )
        editorRows.append(textEditor)

        let visualEditor = CheckmarkRow(
            title: NSLocalizedString("Visual", comment: "Option to enable the hybrid visual editor"),
            checked: (editor == .hybrid),
            action: visualEditorChanged(editor: .hybrid)
        )
        editorRows.append(visualEditor)

        let nativeEditor = CheckmarkRow(
            title: NSLocalizedString("Beta", comment: "Option to enable the beta native editor (Aztec)"),
            checked: (editor == .aztec),
            action: visualEditorChanged(editor: .aztec)
        )
        editorRows.append(nativeEditor)

        let usageTrackingHeader = NSLocalizedString("Usage Statistics", comment: "App usage data settings section header")
        let usageTrackingRow = SwitchRow(
            title: NSLocalizedString("Send Statistics", comment: "Label for switch to turn on/off sending app usage data"),
            value: WPAppAnalytics.isTrackingUsage(),
            onChange: usageTrackingChanged())
        let usageTrackingFooter = NSLocalizedString("Automatically send usage statistics to help us improve WordPress for iOS", comment: "App usage data settings section footer describing what the setting does.")

        let otherHeader = NSLocalizedString("Other", comment: "Link to About section (contains info about the app)")
        let settingsRow = NavigationItemRow(
            title: NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for WordPress App"),
            action: openApplicationSettings()
        )

        let aboutRow = NavigationItemRow(
            title: NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS"),
            action: pushAbout()
        )

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: mediaHeader,
                rows: [
                    imageSizingRow,
                    videoSizingRow,
                    mediaRemoveLocation,
                    mediaCacheRow,
                    mediaClearCacheRow
                ],
                footerText: nil),
            ImmuTableSection(
                headerText: editorHeader,
                rows: editorRows,
                footerText: nil),
            ImmuTableSection(
                headerText: usageTrackingHeader,
                rows: [usageTrackingRow],
                footerText: usageTrackingFooter
            ),
            ImmuTableSection(
                headerText: otherHeader,
                rows: [
                    settingsRow,
                    aboutRow
                ],
                footerText: nil)
            ])
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if shouldShowEditorFooterForSection(section) {
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: AppSettingsEditorFooterView.reuseIdentifier) as! AppSettingsEditorFooterView

            view.tapBlock = { [weak self] in
                WPAppAnalytics.track(.editorAztecBetaLink)

                if let controller = self {
                    WPWebViewController.presentWhatsNewWebView(from: controller)
                }
            }

            return view
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if shouldShowEditorFooterForSection(section) {
            return AppSettingsEditorFooterView.height
        }

        return UITableViewAutomaticDimension
    }

    private func shouldShowEditorFooterForSection(_ section: Int) -> Bool {
        return section == Sections.editor.rawValue && EditorSettings().editor == .aztec
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
        MediaFileManager.calculateSizeOfMediaCacheDirectory { [weak self] (allocatedSize) in
            self?.setMediaCacheRowDescription(allocatedSize: allocatedSize)
        }
    }

    fileprivate func clearMediaCache() {
        setMediaCacheRowDescription(status: .clearingCache)
        MediaFileManager.clearAllMediaCacheFiles(onCompletion: { [weak self] in
            self?.updateMediaCacheSize()
            }, onError: { [weak self] (error) in
                self?.updateMediaCacheSize()
        })
    }

    // MARK: - Actions

    func imageSizeChanged() -> (Int) -> Void {
        return { value in
            MediaSettings().maxImageSizeSetting = value
            ShareExtensionService.configureShareExtensionMaximumMediaDimension(value)
        }
    }

    func pushVideoResolutionSettings() -> ImmuTableAction {
        return { [weak self] row in
            let values = [MediaSettings.VideoResolution.size640x480,
                          MediaSettings.VideoResolution.size1280x720,
                          MediaSettings.VideoResolution.size1920x1080,
                          MediaSettings.VideoResolution.size3840x2160,
                          MediaSettings.VideoResolution.sizeOriginal]

            let titles = values.map({ (settings: MediaSettings.VideoResolution) -> String in
                settings.description
            })

            let currentVideoResolution = MediaSettings().maxVideoSizeSetting

            let settingsSelectionConfiguration = [SettingsSelectionDefaultValueKey: currentVideoResolution,
                                                  SettingsSelectionTitleKey: NSLocalizedString("Resolution", comment: "The largest resolution allowed for uploading"),
                                                  SettingsSelectionTitlesKey: titles,
                                                  SettingsSelectionValuesKey: values] as [String : Any]

            let viewController = SettingsSelectionViewController(dictionary: settingsSelectionConfiguration)

            viewController?.onItemSelected = { (resolution: Any!) -> () in
                MediaSettings().maxVideoSizeSetting = resolution as! MediaSettings.VideoResolution
            }

            self?.navigationController?.pushViewController(viewController!, animated: true)
        }
    }

    func mediaRemoveLocationChanged() -> (Bool) -> Void {
        return { value in
            MediaSettings().removeLocationSetting = value
        }
    }

    func visualEditorChanged(editor: EditorSettings.Editor) -> ImmuTableAction {
        return { [weak self] row in
            let currentEditorIsAztec = EditorSettings().nativeEditorEnabled

            switch editor {
            case .legacy:
                EditorSettings().nativeEditorEnabled = false
                EditorSettings().visualEditorEnabled = false
                if currentEditorIsAztec {
                    WPAnalytics.track(.editorToggledOff)
                }
            case .hybrid:
                EditorSettings().nativeEditorEnabled = false
                EditorSettings().visualEditorEnabled = true
                if currentEditorIsAztec {
                    WPAnalytics.track(.editorToggledOff)
                }
            case .aztec:
                EditorSettings().visualEditorEnabled = true
                EditorSettings().nativeEditorEnabled = true
                if !currentEditorIsAztec {
                    WPAnalytics.track(.editorToggledOn)
                }
            }

            self?.reloadViewModel()
        }
    }

    func nativeEditorChanged() -> (Bool) -> Void {
        return { enabled in
            EditorSettings().nativeEditorEnabled = enabled
        }
    }

    func usageTrackingChanged() -> (Bool) -> Void {
        return { enabled in
            let appAnalytics = WordPressAppDelegate.sharedInstance().analytics
            appAnalytics?.setTrackingUsage(enabled)
        }
    }

    func pushAbout() -> ImmuTableAction {
        return { [weak self] row in
            let controller = AboutViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openApplicationSettings() -> ImmuTableAction {
        return { [weak self] row in
            if let targetURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(targetURL)

            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self?.tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}

fileprivate struct ImageSizingRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()
    static let customHeight: Float? = CellType.height

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

fileprivate struct VideoSizingRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()
    static let customHeight: Float? = CellType.height

    let title: String
    let value: MediaSettings.VideoResolution
    let onChange: (MediaSettings.VideoResolution) -> Void

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType
        cell.model = VideoSizeModel.default
        cell.title = title
        cell.value = value.intValue
        cell.onChange = { (value) in
            self.onChange(MediaSettings.VideoResolution.videoResolution(from: value))
        }
        cell.selectionStyle = .none

        cell.minValue = VideoSizeModel.default.minValue
        cell.maxValue = VideoSizeModel.default.maxValue
    }
}

struct VideoSizeModel: MediaSizeModel {
    var value: Int {
        didSet {
            if step > 1 {
                value = value
                    .round(UInt(step))
                    .clamp(min: minValue, max: maxValue)
            }
        }
    }
    var minValue: Int
    var maxValue: Int
    var step: Int

    var valueText: String {
        return MediaSettings.VideoResolution.videoResolution(from: value).description
    }

    var accessibleText: String {
        return MediaSettings.VideoResolution.videoResolution(from: value).description
    }

    var sliderValue: Float {
        return Float(value)
    }

    var sliderMinimumValue: Float {
        return Float(minValue)
    }

    var sliderMaximumValue: Float {
        return Float(maxValue)
    }

    static var `default`: VideoSizeModel {
        get {
            return VideoSizeModel(value: MediaSettings.VideoResolution.sizeOriginal.intValue,
                                  minValue: MediaSettings.VideoResolution.size640x480.intValue,
                                  maxValue: MediaSettings.VideoResolution.sizeOriginal.intValue,
                                  step: 1)
        }
    }
}


fileprivate class AppSettingsEditorFooterView: UITableViewHeaderFooterView {
    static let height: CGFloat = 38.0
    static let reuseIdentifier = "AppSettingsEditorFooterView"
    var tapBlock: (() -> Void)? = nil

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal

        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.text = NSLocalizedString("Editor beta release notes & bug reporting", comment: "Label for button linking to release notes and bug reporting help for the new beta Aztec editor")
        label.textColor = WPStyleGuide.greyDarken10()
        stackView.addArrangedSubview(label)

        let button = UIButton(type: .custom)
        button.setImage(Gridicon.iconOfType(.infoOutline), for: .normal)
        button.tintColor = WPStyleGuide.greyDarken10()
        button.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)

        contentView.addSubview(stackView)
        stackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction private func footerButtonTapped() {
        tapBlock?()
    }
}
