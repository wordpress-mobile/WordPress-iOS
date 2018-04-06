// Empty state for Stock Photos
final class StockPhotosPlaceholder: WPNoResultsView {
    init() {
        super.init(frame: .zero)
        populate()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func populate() {
        configureImage()
        titleText = "Search to find free photos to add to your Media Library!"
        messageText = "Photos provided by Pexels"
    }

    private func configureImage() {
        accessoryView = UIImageView(image: UIImage(named: "media-free-photos-no-results"))
    }
}
