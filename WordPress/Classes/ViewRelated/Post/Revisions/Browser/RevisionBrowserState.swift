class RevisionBrowserState {
    typealias RevisionSelectedBlock = (Revision) -> Void

    let revisions: [Revision]
    var currentIndex: Int
    var onRevisionSelected: RevisionSelectedBlock


    init(revisions: [Revision], currentIndex: Int, onRevisionSelected: @escaping RevisionSelectedBlock) {
        self.revisions = revisions
        self.currentIndex = currentIndex
        self.onRevisionSelected = onRevisionSelected
    }

    func currentRevision() -> Revision {
        return revisions[currentIndex]
    }

    func decreaseIndex() {
        currentIndex = max(currentIndex - 1, 0)
    }

    func increaseIndex() {
        currentIndex = min(currentIndex + 1, revisions.count)
    }
}
