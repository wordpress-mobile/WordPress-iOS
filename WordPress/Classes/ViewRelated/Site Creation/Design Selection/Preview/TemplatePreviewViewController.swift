
import Foundation

protocol TemplatePreviewViewDelegate: AnyObject {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice
    func deviceButtonTapped(_ previewDevice: PreviewDevice)
    func deviceModeChanged(_ previewDevice: PreviewDevice)
    func previewError(_ error: Error)
    func previewViewed()
    func previewLoading()
    func previewLoaded()
    func templatePicked()
}

class TemplatePreviewViewController: UIViewController, NoResultsViewHost, UIPopoverPresentationControllerDelegate {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!

    internal weak var delegate: TemplatePreviewViewDelegate?
    private let demoURL: String
    private var estimatedProgressObserver: NSKeyValueObservation?
    internal var selectedPreviewDevice: PreviewDevice {
        didSet {
            if selectedPreviewDevice != oldValue {
                UIView.animate(withDuration: 0.2, animations: {
                    self.webView.alpha = 0
                }, completion: { _ in
                    self.progressBar.animatableSetIsHidden(false)
                    self.webView.reload()
                })
            }
        }
    }
    private var onDismissWithDeviceSelected: ((PreviewDevice) -> ())?

    private var accentColor: UIColor {
        return UIColor { (traitCollection: UITraitCollection) -> UIColor in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.muriel(color: .primary, .shade40)
            } else {
                return UIColor.muriel(color: .primary, .shade50)
            }
        }
    }

    init(demoURL: String, selectedPreviewDevice: PreviewDevice?, onDismissWithDeviceSelected: ((PreviewDevice) -> ())?) {
        self.demoURL = demoURL
        self.selectedPreviewDevice = selectedPreviewDevice ?? PreviewDevice.default
        self.onDismissWithDeviceSelected = onDismissWithDeviceSelected
        super.init(nibName: "\(TemplatePreviewViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeProgressObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        styleButtons()
        webView.scrollView.contentInset.bottom = footerView.frame.height
        webView.navigationDelegate = self
        webView.backgroundColor = .basicBackground
        delegate?.previewViewed()
        observeProgressEstimations()
        configurePreviewDeviceButton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismissWithDeviceSelected?(selectedPreviewDevice)
    }

    @IBAction func actionButtonSelected(_ sender: Any) {
        dismiss(animated: true)
        delegate?.templatePicked()
    }

    private func configureWebView() {
        webView.alpha = 0
        guard let demoURL = URL(string: demoURL) else { return }
        let request = URLRequest(url: demoURL)
        webView.customUserAgent = WPUserAgent.wordPress()
        webView.load(request)
    }

    private func styleButtons() {
        primaryActionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        primaryActionButton.backgroundColor = accentColor
        primaryActionButton.layer.cornerRadius = 8
        primaryActionButton.setTitle(NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design"), for: .normal)
    }

    private func configurePreviewDeviceButton() {
        let button = UIBarButtonItem(image: UIImage(named: "icon-devices"), style: .plain, target: self, action: #selector(previewDeviceButtonTapped))
        navigationItem.rightBarButtonItem = button
    }

    private func observeProgressEstimations() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] (webView, _) in
            self?.progressBar.progress = Float(webView.estimatedProgress)
        }
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func previewDeviceButtonTapped() {
        delegate?.deviceButtonTapped(selectedPreviewDevice)
        let popoverContentController = PreviewDeviceSelectionViewController()
        popoverContentController.selectedOption = selectedPreviewDevice
        popoverContentController.onDeviceChange = { [weak self] device in
            guard let self = self else { return }
            self.delegate?.deviceModeChanged(device)
            self.selectedPreviewDevice = device
        }

        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.popoverPresentationController?.delegate = self
        self.present(popoverContentController, animated: true, completion: nil)
    }

    private func removeProgressObserver() {
        estimatedProgressObserver?.invalidate()
        estimatedProgressObserver = nil
    }

    private func handleError(_ error: Error) {
        delegate?.previewError(error)
        configureAndDisplayNoResults(on: webView,
                                     title: NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed because the device wasn't able to establish a network connection."))
        progressBar.animatableSetIsHidden(true)
    }
}

// MARK: WKNavigationDelegate
extension TemplatePreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.previewLoading()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.evaluateJavaScript(selectedPreviewDevice.viewportScript)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.2) {
            self.webView.alpha = 1
        }

        delegate?.previewLoaded()
        progressBar.animatableSetIsHidden(true)
    }
}

// MARK: UIPopoverPresentationDelegate
extension TemplatePreviewViewController {

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        guard popoverPresentationController.presentedViewController is PreviewDeviceSelectionViewController else {
            return
        }

        popoverPresentationController.permittedArrowDirections = .up
        popoverPresentationController.barButtonItem = navigationItem.rightBarButtonItem
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let popoverPresentationController = presentedViewController?.presentationController as? UIPopoverPresentationController else {
                return
        }

        prepareForPopoverPresentation(popoverPresentationController)
    }
}
