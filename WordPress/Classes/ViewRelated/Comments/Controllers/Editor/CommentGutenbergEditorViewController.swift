import UIKit
import GutenbergKit
import WordPressUI
import Combine

protocol CommentGutenbergEditorViewControllerDelegate: AnyObject {
    func commentGutenbergEditorViewController(_ viewController: CommentGutenbergEditorViewController, didChangeText text: String)
}

final class CommentGutenbergEditorViewController: UIViewController {
    private var editorVC: GutenbergKit.EditorViewController?

    weak var delegate: CommentGutenbergEditorViewControllerDelegate?

    var initialContent: String?

    var text: String {
        get async {
            guard let editorVC else {
                wpAssertionFailure("editor missing")
                return ""
            }
            do {
                return try await editorVC.getContent()
            } catch {
                wpAssertionFailure("failed to refresh content", userInfo: ["error": "\(error)"])
                return ""
            }
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
            .sink { [weak self] in self?.refresh() }
            .store(in: &cancellables)
    }

    private func refresh() {
        Task { @MainActor in
            let text = await self.text
            self.delegate?.commentGutenbergEditorViewController(self, didChangeText: text)
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
