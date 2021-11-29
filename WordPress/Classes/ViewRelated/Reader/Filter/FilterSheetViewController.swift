class FilterSheetViewController: UIViewController {

    private let viewTitle: String
    private let filters: [FilterProvider]
    private let changedFilter: (ReaderAbstractTopic) -> Void

    init(viewTitle: String,
         filters: [FilterProvider],
         changedFilter: @escaping (ReaderAbstractTopic) -> Void) {
        self.viewTitle = viewTitle
        self.filters = filters
        self.changedFilter = changedFilter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = FilterSheetView(viewTitle: viewTitle,
                               filters: filters,
                               presentationController: self,
                               changedFilter: changedFilter)
    }
}

extension FilterSheetViewController: DrawerPresentable {
    func handleDismiss() {
        WPAnalytics.track(.readerFilterSheetDismissed)
    }

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
