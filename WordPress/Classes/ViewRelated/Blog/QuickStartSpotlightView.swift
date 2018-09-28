
//  Exported from Kite Compositor for Mac 1.9.4
import UIKit

@objc
class QuickStartSpotlightView: UIView
{

    // MARK: - Initialization

    init()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 26, height: 26))
        self.setupLayers()
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setupLayers()
    }

    // MARK: - Setup Layers

    private func setupLayers()
    {
        // Colors
        //
        let backgroundColor = UIColor(red: 0.096, green: 0.44875, blue: 0.64, alpha: 1)
        let borderColor = UIColor(red: 0.126, green: 0.588984, blue: 0.84, alpha: 1)
        let backgroundColor1 = UIColor(red: 0.243137, green: 0.517647, blue: 0.682353, alpha: 1)

        // Layer
        //
        let layerLayer = CALayer()
        layerLayer.name = "Layer"
        layerLayer.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        layerLayer.position = CGPoint(x: 13, y: 13)
        layerLayer.contentsGravity = kCAGravityCenter
        layerLayer.backgroundColor = backgroundColor.cgColor
        layerLayer.cornerRadius = 6
        layerLayer.borderColor = borderColor.cgColor
        layerLayer.shadowOffset = CGSize(width: 0, height: 1)
        layerLayer.fillMode = kCAFillModeForwards
        layerLayer.sublayerTransform = CATransform3D( m11: -5, m12: -0, m13: -0, m14: -0,
                                                      m21: -0, m22: 5, m23: -0, m24: -0,
                                                      m31: -0, m32: -0, m33: 1, m34: -0,
                                                      m41: 0, m42: 0, m43: 0, m44: 1 )

        // Layer Animations
        //

        // transform.scale.xy
        //
        let transformScaleXyAnimation = CABasicAnimation()
        transformScaleXyAnimation.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.000001
        transformScaleXyAnimation.duration = 0.497999
        transformScaleXyAnimation.fillMode = kCAFillModeForwards
        transformScaleXyAnimation.isRemovedOnCompletion = false
        transformScaleXyAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transformScaleXyAnimation.keyPath = "transform.scale.xy"
        transformScaleXyAnimation.toValue = 1
        transformScaleXyAnimation.fromValue = 0

        layerLayer.add(transformScaleXyAnimation, forKey: "transformScaleXyAnimation")

        // opacity
        //
        let opacityAnimation = CAKeyframeAnimation()
        opacityAnimation.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.498
        opacityAnimation.duration = 2.002
        opacityAnimation.repeatCount = 99999
        opacityAnimation.fillMode = kCAFillModeForwards
        opacityAnimation.isRemovedOnCompletion = false
        opacityAnimation.keyPath = "opacity"
        opacityAnimation.values = [ 1, 1, 0, 0, 1 ]
        opacityAnimation.keyTimes = [ 0, 0.252831, 0.750944, 0.7385, 1 ]
        opacityAnimation.calculationMode = kCAAnimationLinear

        layerLayer.add(opacityAnimation, forKey: "opacityAnimation")

        // transform.scale.xy
        //
        let transformScaleXyAnimation1 = CAKeyframeAnimation()
        transformScaleXyAnimation1.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.498
        transformScaleXyAnimation1.duration = 2.002
        transformScaleXyAnimation1.repeatCount = 99999
        transformScaleXyAnimation1.fillMode = kCAFillModeForwards
        transformScaleXyAnimation1.isRemovedOnCompletion = false
        transformScaleXyAnimation1.keyPath = "transform.scale.xy"
        transformScaleXyAnimation1.values = [ 1, 1, 2, 0, 1 ]
        transformScaleXyAnimation1.keyTimes = [ 0, 0.252831, 0.7385, 0.750943, 1 ]
        transformScaleXyAnimation1.calculationMode = kCAAnimationLinear

        layerLayer.add(transformScaleXyAnimation1, forKey: "transformScaleXyAnimation1")

        self.layer.addSublayer(layerLayer)

        // Layer
        //
        let layerLayer1 = CALayer()
        layerLayer1.name = "Layer"
        layerLayer1.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        layerLayer1.position = CGPoint(x: 13, y: 13)
        layerLayer1.contentsGravity = kCAGravityCenter
        layerLayer1.backgroundColor = backgroundColor1.cgColor
        layerLayer1.cornerRadius = 6
        layerLayer1.borderColor = borderColor.cgColor
        layerLayer1.shadowOffset = CGSize(width: 0, height: 1)
        layerLayer1.fillMode = kCAFillModeForwards
        layerLayer1.sublayerTransform = CATransform3D( m11: -5, m12: -0, m13: -0, m14: -0,
                                                       m21: -0, m22: 5, m23: -0, m24: -0,
                                                       m31: -0, m32: -0, m33: 1, m34: -0,
                                                       m41: 0, m42: 0, m43: 0, m44: 1 )

        // Layer Animations
        //

        // transform.scale.xy
        //
        let transformScaleXyAnimation2 = CAKeyframeAnimation()
        transformScaleXyAnimation2.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.998684
        transformScaleXyAnimation2.duration = 2.001316
        transformScaleXyAnimation2.repeatCount = 99999
        transformScaleXyAnimation2.fillMode = kCAFillModeForwards
        transformScaleXyAnimation2.isRemovedOnCompletion = false
        transformScaleXyAnimation2.keyPath = "transform.scale.xy"
        transformScaleXyAnimation2.values = [ 0, 1, 1, 2, 0 ]
        transformScaleXyAnimation2.keyTimes = [ 0, 0.251187, 0.501023, 0.9858, 1 ]
        transformScaleXyAnimation2.calculationMode = kCAAnimationLinear

        layerLayer1.add(transformScaleXyAnimation2, forKey: "transformScaleXyAnimation2")

        // transform.scale.xy
        //
        let transformScaleXyAnimation3 = CABasicAnimation()
        transformScaleXyAnimation3.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.000001
        transformScaleXyAnimation3.duration = 0.998683
        transformScaleXyAnimation3.fillMode = kCAFillModeForwards
        transformScaleXyAnimation3.isRemovedOnCompletion = false
        transformScaleXyAnimation3.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transformScaleXyAnimation3.keyPath = "transform.scale.xy"
        transformScaleXyAnimation3.toValue = 0
        transformScaleXyAnimation3.fromValue = 0

        layerLayer1.add(transformScaleXyAnimation3, forKey: "transformScaleXyAnimation3")

        // opacity
        //
        let opacityAnimation1 = CAKeyframeAnimation()
        opacityAnimation1.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.998684
        opacityAnimation1.duration = 2.001316
        opacityAnimation1.repeatCount = 99999
        opacityAnimation1.fillMode = kCAFillModeForwards
        opacityAnimation1.isRemovedOnCompletion = false
        opacityAnimation1.keyPath = "opacity"
        opacityAnimation1.values = [ 1, 1, 0, 0 ]
        opacityAnimation1.keyTimes = [ 0, 0.501023, 0.9846, 1 ]
        opacityAnimation1.calculationMode = kCAAnimationLinear

        layerLayer1.add(opacityAnimation1, forKey: "opacityAnimation1")

        self.layer.addSublayer(layerLayer1)

    }

    // MARK: - Responder

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let location = touches.first?.location(in: self.superview),
            let hitLayer = self.layer.presentation()?.hitTest(location) else { return }

        print("Layer \(hitLayer.name ?? String(describing: hitLayer)) was tapped.")
    }
}
