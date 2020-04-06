final class ShadowView: UIView {
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    private enum Appearance {
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.20
        static let shadowRadius: CGFloat = 8.0
        static let shadowOffset = CGSize(width: 0.0, height: 5.0)
    }

    func addShadow() {
        shadowLayer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: 0.0).cgPath
        shadowLayer.shadowColor = Appearance.shadowColor.cgColor
        shadowLayer.shadowOpacity = Appearance.shadowOpacity
        shadowLayer.shadowRadius = Appearance.shadowRadius
        shadowLayer.shadowOffset = Appearance.shadowOffset
        layer.insertSublayer(shadowLayer, at: 0)

        shadowMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        shadowLayer.mask = shadowMaskLayer

        updateShadowPath()
    }

    private func updateShadowPath() {
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 0.0).cgPath
        shadowLayer.shadowPath = shadowPath

        let maskPath = CGMutablePath()
        let topInset: CGFloat = 5.0
        maskPath.addRect(bounds.insetBy(dx: 0.0, dy: -topInset))
        maskPath.addPath(shadowPath)
        shadowMaskLayer.path = maskPath
    }

    func clearShadow() {
        shadowLayer.removeFromSuperlayer()
    }
}
