import UIKit
import SVProgressHUD

class SiteCreationThemeSelectionViewController: NUXCollectionViewController, UICollectionViewDelegateFlowLayout, WPContentSyncHelperDelegate {

    // MARK: - Properties

    var siteType: SiteType?
    private typealias Styles = WPStyleGuide.Themes

    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var themesSyncHelper: WPContentSyncHelper?

    private var themes: [Theme]?
    private var themeCount: NSInteger = 0

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        setupThemesSyncHelper()
        syncContent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, collectionView: collectionView)
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SiteCreationThemeSelectionHeaderView.reuseIdentifier, for: indexPath) as! SiteCreationThemeSelectionHeaderView
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SiteCreationThemeSelectionCell.reuseIdentifier, for: indexPath) as! SiteCreationThemeSelectionCell
        cell.displayTheme = themeAtIndexPath(indexPath)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Styles.cellSizeForFrameWidth(collectionView.frame.size.width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Styles.themeMargins
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        // To get the header to layout correctly for dynamic text,
        // calculate the header size based on what the labels will be.

        let stackViewWidthMargins: CGFloat = 40 // stack view total width constraints

        let stepLabel = UILabel(frame: CGRect(x: 0, y: 0,
                                              width: collectionView.frame.width - stackViewWidthMargins,
                                              height: view.frame.height))
        stepLabel.numberOfLines = 1
        stepLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        stepLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        stepLabel.text = SiteCreationThemeSelectionHeaderView.stepLabelText
        stepLabel.sizeToFit()

        let stepDescrLabel = UILabel(frame: CGRect(x: 0, y: 0,
                                                   width: collectionView.frame.width - stackViewWidthMargins,
                                                   height: view.frame.height))
        stepDescrLabel.numberOfLines = 0
        stepDescrLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        stepDescrLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        stepDescrLabel.text = SiteCreationThemeSelectionHeaderView.stepDescrLabelText
        stepDescrLabel.sizeToFit()

        let stackViewHeightMargins: CGFloat = 25 // stack view total height constraints
        let height = stepLabel.frame.height + stepDescrLabel.frame.height + stackViewHeightMargins

        return CGSize(width: 0, height: height)
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let selectedTheme = themeAtIndexPath(indexPath) else {
            return
        }

        SiteCreationFields.sharedInstance.theme = selectedTheme
        performSegue(withIdentifier: "showSiteDetails", sender: nil)
    }

    // MARK: - Theme Syncing

    private func setupThemesSyncHelper() {
        themesSyncHelper = WPContentSyncHelper()
        themesSyncHelper?.delegate = self
    }

    private func syncContent() {
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading themes", comment: "Shown while the app waits for the starting themes web service to return during the site creation process."))
        themesSyncHelper?.syncContent()
    }

    private func syncThemePage(page: NSInteger, success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {

        guard let siteType = siteType else {
            return
        }

        themeService.getStartingThemes(forCategory: siteType.rawValue,
                                       page: page,
                                       success: {[weak self](themes: [Theme]?, hasMore: Bool, themeCount: NSInteger) in
                                        self?.themes = themes
                                        self?.themeCount = themeCount
                                        SVProgressHUD.dismiss()
                                        self?.collectionView?.reloadData()
            },
                                       failure: { (error) in
                                        DDLogError("Error syncing themes: \(String(describing: error?.localizedDescription))")
                                        if let failure = failure,
                                            let error = error {
                                            failure(error as NSError)
                                        }
                                        SVProgressHUD.dismiss()
        })
    }

    // MARK: - WPContentSyncHelperDelegate

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {

        if syncHelper == themesSyncHelper {
            syncThemePage(page: 1, success: success, failure: failure)
        }
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        // Nothing to be done here. There will only be one page.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backButton = UIBarButtonItem()
        backButton.title = NSLocalizedString("Back", comment: "Back button title.")
        navigationItem.backBarButtonItem = backButton
    }

    // MARK: - Helpers

    private func themeAtIndexPath(_ indexPath: IndexPath) -> Theme? {
        return themes?[indexPath.row]
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
