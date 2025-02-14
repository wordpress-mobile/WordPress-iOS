import UIKit
import GutenbergKit
import WordPressUI
import Combine

final class CommentGutenbergEditorViewController: UIViewController, CommentEditor {
    private var editorVC: GutenbergKit.EditorViewController?

    weak var delegate: CommentEditorDelegate?

    var initialContent: String?

    var text: String {
        set {
            wpAssertionFailure("not supported")
        }
        get {
            currentText
        }
    }

    private var currentText = ""

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

        let editorVC = GutenbergKit.EditorViewController(
            content: initialContent ?? "",
            service: EditorService(client: EmptyNetworkClient())
        )
        editorVC.delegate = self

        view.addSubview(editorVC.view)
        editorVC.view.pinEdges(to: view.safeAreaLayoutGuide)
        self.editorVC = editorVC

        editorDidUpdate
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.refreshText() }
            .store(in: &cancellables)
    }

    private func refreshText() {
        guard let editorVC else { return }
        Task { @MainActor in
            do {
                let text = try await editorVC.getContent()
                if text != self.currentText {
                    self.currentText = text
                    self.delegate?.commentEditor(self, didUpateText: text)
                }
            } catch {
                // TODO: handle errors
            }
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

private final class EmptyNetworkClient: GutenbergKit.EditorNetworkingClient {
    func send(_ request: EditorNetworkRequest) async throws -> EditorNetworkResponse {
        throw URLError(.unknown)
    }
}
