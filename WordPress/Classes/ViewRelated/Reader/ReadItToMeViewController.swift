import Foundation
import AVFoundation
import UIKit

public class ReadItToMeViewController: UIViewController {

    fileprivate lazy var synthesizer: AVSpeechSynthesizer = {
         let synth = AVSpeechSynthesizer()
        synth.delegate = self
         return synth
    }()

    private var text: String
    private var attributedText: NSAttributedString

    deinit {
        stop()
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        return textView
    }()

    init(text: String) {
        self.text = text
        self.attributedText = WPRichContentView.formattedAttributedStringForString(text)
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(post: ReaderPost) {
        let string = post.contentForDisplay() ?? ""
        let fullText = "<h2>\(post.postTitle!).</h2> <h3>by \(post.authorDisplayName!) on \(post.blogName!).</h3> \(string)"
        self.init(text: fullText)
    }

    public required init?(coder: NSCoder) {
        attributedText = NSAttributedString(string: "")
        text = ""
        super.init(coder: coder)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13, *) {
            attributedText = WPRichContentView.formattedAttributedString(for: text, style: self.traitCollection.userInterfaceStyle)
            textView.attributedText = attributedText
        }

    }

    override public func viewDidLoad() {

        guard let view = self.view else {
            return
        }

        if #available(iOS 13, *) {
            attributedText = WPRichContentView.formattedAttributedString(for: text, style: self.traitCollection.userInterfaceStyle)
        } else {
            attributedText = WPRichContentView.formattedAttributedStringForString(text)
        }
        textView.attributedText = attributedText
        textView.sizeToFit()
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
        ])
        view.setNeedsUpdateConstraints()
    }

    override public func viewDidAppear(_ animated: Bool) {
        speak(attributedString: attributedText)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        pause()
    }

    func speak(string: String) {
        let utterance = AVSpeechUtterance(string:string)
        start(utterance: utterance)
    }

    func speak(attributedString: NSAttributedString) {
        let utterance = AVSpeechUtterance(attributedString: attributedString)
        attributedText = utterance.attributedSpeechString
        print("Count text: \((utterance.speechString as NSString).length), attributed: \(utterance.attributedSpeechString.length) \n")
        start(utterance: utterance)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .word)
    }

    func start(utterance: AVSpeechUtterance) {
        checkPermissions { (allowed) in
            if allowed {
                self.synthesizer.speak(utterance)
            }
        }

    }

    func checkPermissions(and action:@escaping (Bool)->()) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: // The user has previously granted access to the camera.
                action(true)
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if granted {
                        action(true)
                    }
                }

            case .denied: // The user has previously denied access.
                action(false)
                return

            case .restricted: // The user can't grant access due to restrictions.
                action(false)
                return
            default:
                action(false)
        }
    }
}

extension ReadItToMeViewController: AVSpeechSynthesizerDelegate {

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let highlightedText = NSMutableAttributedString(attributedString: attributedText )
        highlightedText.addAttributes([.foregroundColor: UIColor.red], range: characterRange)
        textView.attributedText = highlightedText
        textView.scrollRangeToVisible(characterRange)
    }

}
