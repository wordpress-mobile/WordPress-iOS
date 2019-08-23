import UIKit
import WordPressShared

/// A circular 'play' icon for use on videos that should match the system
/// play button appearance in web views.
///
class PlayIconView: UIView {
    private static let defaultSize = CGSize(width: 71, height: 71)

    private let playLayer = CAShapeLayer()
    private let visualEffectsView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    @objc var isHighlighted: Bool {
        didSet {
            let iconColor: UIColor = isHighlighted ? .black : .neutral(.shade70)
            playLayer.strokeColor = iconColor.cgColor
            playLayer.fillColor = iconColor.cgColor
        }
    }

    convenience init() {
        self.init(frame: CGRect(x: 0,
                                y: 0,
                                width: type(of: self).defaultSize.width,
                                height: type(of: self).defaultSize.height))
    }

    override init(frame: CGRect) {
        isHighlighted = false

        super.init(frame: frame)

        addEffectsView()
        layer.addSublayer(playLayer)
        refreshRadius()
        updatePlayLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    override var frame: CGRect {
        didSet {
            refreshRadius()
            updatePlayLayer()
        }
    }

    private func addEffectsView() {
        visualEffectsView.frame = bounds

        addSubview(visualEffectsView)
    }

    fileprivate func refreshRadius() {
        let radius: CGFloat = frame.width / 2

        if visualEffectsView.layer.cornerRadius != radius {
            visualEffectsView.layer.cornerRadius = radius
        }

        visualEffectsView.layer.masksToBounds = true
        visualEffectsView.clipsToBounds = true
    }

    private func updatePlayLayer() {
        let lineWidth: CGFloat = 5
        let halfLineWidth: CGFloat = lineWidth / 2

        let halfBoundsWidth: CGFloat = bounds.width / 2
        let halfBoundsHeight: CGFloat = bounds.height / 2

        let size = CGSize(width: halfBoundsWidth - (lineWidth + halfLineWidth),
                          height: halfBoundsHeight - halfLineWidth)
        let halfSizeWidth: CGFloat = size.width / 2
        let halfSizeHeight: CGFloat = size.height / 2

        // Draw a triangle
        let path = UIBezierPath()
        path.move(to: CGPoint(x: size.width + halfLineWidth, y: halfSizeHeight + halfLineWidth))
        path.addLine(to: CGPoint(x: halfLineWidth, y: size.height + halfLineWidth))
        path.addLine(to: CGPoint(x: halfLineWidth, y: halfLineWidth))
        path.addLine(to: CGPoint(x: size.width + halfLineWidth, y: halfSizeHeight + halfLineWidth))
        path.close()

        // Set a rounded line style
        playLayer.path = path.cgPath
        playLayer.lineWidth = lineWidth
        playLayer.lineCap = CAShapeLayerLineCap.round
        playLayer.lineJoin = CAShapeLayerLineJoin.round

        let centerX = halfBoundsWidth - halfSizeWidth + halfLineWidth
        let centerY = halfBoundsHeight - halfSizeWidth - lineWidth

        playLayer.frame = CGRect(x: centerX, y: centerY, width: size.width, height: size.height)
    }
}
