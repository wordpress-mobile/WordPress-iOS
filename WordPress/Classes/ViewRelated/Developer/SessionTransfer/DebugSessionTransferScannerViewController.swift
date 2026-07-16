import Foundation
import UIKit
import WordPressShared
import WordPressUI

/// Full-screen camera scanner for the sender side of session transfer: it reads the receiver's QR —
/// its per-transfer X25519 public key — off the receiver's screen and hands the raw key back via
/// `onScan`.
///
/// Reuses the magic-login camera stack (`QRLoginCameraSession`). Scanning the key off the screen,
/// rather than trusting a key from the network, is the whole security point — see the note on
/// `DebugSessionTransferReceiver`.
final class DebugSessionTransferScannerViewController: UIViewController {
    private let deviceName: String
    private let onScan: (Data) -> Void
    private let onCancel: () -> Void

    // `var` (not `let`): `QRCodeScanningSession` isn't class-constrained, so setting its
    // `scanningDelegate` requires a mutable binding.
    private var cameraSession: QRCodeScanningSession
    private let permissions: CameraPermissionsHandler
    private var previewLayer: CALayer?
    private var hasScanned = false

    init(
        deviceName: String,
        cameraSession: QRCodeScanningSession = QRLoginCameraSession(),
        permissions: CameraPermissionsHandler = QRLoginCameraPermissionsHandler(),
        onScan: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.deviceName = deviceName
        self.cameraSession = cameraSession
        self.permissions = permissions
        self.onScan = onScan
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cameraSession.scanningDelegate = self
        setUpChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanningIfPermitted()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraSession.stop()
    }

    // MARK: - Camera

    private func startScanningIfPermitted() {
        guard permissions.needsCameraAccess() else {
            beginCamera()
            return
        }
        permissions.requestCameraAccess { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.beginCamera()
                } else {
                    self.permissions.showNeedAccessAlert(from: self)
                }
            }
        }
    }

    private func beginCamera() {
        guard previewLayer == nil else {
            cameraSession.start()
            return
        }
        cameraSession.configure()
        if let layer = cameraSession.previewLayer {
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
        }
        cameraSession.start()
    }

    // MARK: - Chrome

    private func setUpChrome() {
        let title = UILabel()
        title.text = String(format: Strings.title, deviceName)
        title.font = .preferredFont(forTextStyle: .title2).bold()
        title.textColor = .white
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = Strings.subtitle
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .white.withAlphaComponent(0.8)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let cancel = UIButton(type: .system)
        cancel.setTitle(SharedStrings.Button.cancel, for: .normal)
        cancel.setTitleColor(.white, for: .normal)
        cancel.titleLabel?.font = .preferredFont(forTextStyle: .body)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cancel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    @objc private func cancelTapped() {
        onCancel()
    }
}

extension DebugSessionTransferScannerViewController: QRCodeScanningDelegate {
    /// Accept only a QR that decodes to a 32-byte X25519 public key, so random QR codes are ignored.
    func validLink(_ stringValue: String) -> Bool {
        DebugSessionTransferCrypto.decodePublicKey(stringValue)?.count == 32
    }

    func didScanURLString(_ urlString: String) {
        guard !hasScanned, let publicKey = DebugSessionTransferCrypto.decodePublicKey(urlString), publicKey.count == 32
        else {
            return
        }
        hasScanned = true
        cameraSession.stop()
        onScan(publicKey)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "debugMenu.sessionTransfer.scanner.title",
        value: "Scan “%@”",
        comment: "Title of the QR scanner; %@ is the name of the device being signed in"
    )
    static let subtitle = NSLocalizedString(
        "debugMenu.sessionTransfer.scanner.subtitle",
        value: "Point at the code on the other device's screen.",
        comment: "Instruction shown on the QR scanner"
    )
}
