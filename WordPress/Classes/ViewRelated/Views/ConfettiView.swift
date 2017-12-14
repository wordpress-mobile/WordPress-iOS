import UIKit


/// Displays a small shower of confetti, raining down from the top of the view
/// Designed to work with FancyAlertViewController, so may currently have
/// visual issues working with larger views.
///
class ConfettiView: UIView {
    @objc let colors: [UIColor]

    /// - parameter: colors An array of colors to use for the confetti particles
    ///
    @objc init(colors: [UIColor]) {
        self.colors = colors

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Starts the confetti effect
    /// - parameter duration: Optional time interval after which the confetti
    ///                       effect will automatically finish
    ///
    func start(duration: TimeInterval? = nil) {
        let cells = colors.map({ makeEmitterCell(with: $0) })
        makeEmitter(with: cells)

        if let duration = duration, duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                self.stop()
            }
        }
    }

    /// Stop the confetti effect
    ///
    @objc func stop() {
        emitterLayer?.birthRate = 0
    }

    // MARK: - Emitter creation

    private var emitterLayer: CAEmitterLayer? = nil

    private func makeEmitter(with cells: [CAEmitterCell]) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.beginTime = CACurrentMediaTime()

        emitterLayer.emitterShape = kCAEmitterLayerRectangle
        emitterLayer.emitterCells = cells

        layer.addSublayer(emitterLayer)

        self.emitterLayer = emitterLayer

        updateEmitterSize()
    }

    private func updateEmitterSize() {
        let emitterHeight = bounds.height / 4

        emitterLayer?.emitterSize = CGSize(width: bounds.width, height: emitterHeight)
        emitterLayer?.emitterPosition = CGPoint(x: bounds.midX, y: 0)
    }

    /// Creates the cells used for each color in the confetti.
    /// Values
    ///
    private func makeEmitterCell(with color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.color = color.cgColor
        cell.contents = UIImage(named: "confetti")?.cgImage

        cell.birthRate = 3.0

        cell.lifetime = 15.0
        cell.lifetimeRange = 5.0

        cell.emissionLongitude = CGFloat.pi / 2
        cell.emissionRange = CGFloat.pi / 4

        cell.scale = 0.7
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05

        cell.velocity = 60.0
        cell.velocityRange = 50.0

        cell.spinRange = CGFloat.pi / 4

        return cell
    }
}
