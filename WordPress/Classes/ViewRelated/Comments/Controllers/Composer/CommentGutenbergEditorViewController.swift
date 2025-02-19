import UIKit
import GutenbergKit
import WordPressUI
import Combine

final class CommentGutenbergEditorViewController: UIViewController, CommentEditor {
    private var editorVC: GutenbergKit.EditorViewController?

    weak var delegate: CommentEditorDelegate?

    var initialContent: String?

    private(set) var text = ""

    var isEnabled: Bool = true {
        didSet {
            // TODO: implement
//            if !isEnabled {
//                textView.resignFirstResponder()
//            }
            editorVC?.view.alpha = isEnabled ? 1.0 : 0.5
            editorVC?.view.isUserInteractionEnabled = isEnabled
        }
    }

    var placeholder: String? {
        didSet {
            // TODO: implement placeholder
        }
    }

    private let editorDidUpdate = PassthroughSubject<Void, Never>()
    private var cancellables: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        var configuration = EditorConfiguration(content: initialContent ?? "")
        configuration.hideTitle = true

        let editorVC = GutenbergKit.EditorViewController(configuration: configuration)
        editorVC.delegate = self

        view.addSubview(editorVC.view)
        editorVC.view.pinEdges(to: view.safeAreaLayoutGuide)
        self.editorVC = editorVC

        editorDidUpdate
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    func refresh() async {
        do {
            guard let editorVC else { return }
            let text = try await editorVC.getContent()
            if text != self.text {
                self.text = text
                self.delegate?.commentEditor(self, didUpateText: text)
            }
        } catch {
            wpAssertionFailure("failed to refresh content", userInfo: ["error": "\(error)"])
        }
    }
}

extension CommentGutenbergEditorViewController: GutenbergKit.EditorViewControllerDelegate {
    func editorDidLoad(_ viewContoller: GutenbergKit.EditorViewController) {
        // Do nothing
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didDisplayInitialContent content: String) {
        // Do nothing
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didEncounterCriticalError error: any Error) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateContentWithState state: GutenbergKit.EditorState) {
        editorDidUpdate.send(())
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: GutenbergKit.EditorState) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException error: GutenbergKit.GutenbergJSException) {
        // Do nothing
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didRequestMediaFromSiteMediaLibrary config: GutenbergKit.OpenMediaLibraryAction) {
        // Do nothing
    }
}
