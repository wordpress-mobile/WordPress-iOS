class FilterSheetViewController: UIViewController {

    private let filters: [FilterProvider]
    private let changedFilter: (ReaderAbstractTopic) -> Void

    //TODO: Make changedFilter generic
    init(filters: [FilterProvider], changedFilter: @escaping (ReaderAbstractTopic) -> Void) {
        self.filters = filters
        self.changedFilter = changedFilter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = FilterSheetView(filters: filters, presentationController: self, changedFilter: changedFilter)
    }
}

extension FilterSheetViewController: DrawerPresentable {
    var scrollableView: UIScrollView? {
        return (view as? FilterSheetView)?.tableView
    }

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        } else {
            return .contentHeight(0)
        }
    }
}
