#if canImport(UIKit)
import UIKit

class SkinThumbstickView: UIView {

    let item: SkinItem
    private let knobImageView = UIImageView()
    private let bridge: SkinInputBridge

    // Knob can travel this fraction of the frame's half-width from centre
    private let maxDisplacementRatio: CGFloat = 0.35
    private let deadZone: CGFloat = 0.15

    private var isLeft: Bool {
        let map = item.inputs.directionalMap
        return map.values.contains(where: { $0.hasPrefix("left") })
    }

    init(item: SkinItem, knobImage: UIImage?, bridge: SkinInputBridge) {
        self.item = item
        self.bridge = bridge
        super.init(frame: .zero)

        isMultipleTouchEnabled = false
        isExclusiveTouch = false

        knobImageView.image = knobImage
        knobImageView.contentMode = .scaleAspectFit
        knobImageView.isUserInteractionEnabled = false
        addSubview(knobImageView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Size the knob from the thumbstick asset dimensions, scaled to frame
        if let ts = item.thumbstick {
            let knobW = CGFloat(ts.width) / CGFloat(item.frame.width) * bounds.width
            let knobH = CGFloat(ts.height) / CGFloat(item.frame.height) * bounds.height
            knobImageView.bounds = CGRect(x: 0, y: 0, width: knobW, height: knobH)
        } else {
            knobImageView.bounds = CGRect(x: 0, y: 0, width: bounds.width * 0.8, height: bounds.height * 0.8)
        }
        knobImageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateStick(for: touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateStick(for: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        returnToCenter()
        reportStick(x: 0, y: 0)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        returnToCenter()
        reportStick(x: 0, y: 0)
    }

    // MARK: - Stick Logic

    private func updateStick(for touch: UITouch) {
        let location = touch.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let maxDisplacement = bounds.width * 0.5 * maxDisplacementRatio

        var dx = (location.x - center.x) / maxDisplacement
        var dy = (location.y - center.y) / maxDisplacement

        // Clamp to unit circle
        let magnitude = sqrt(dx * dx + dy * dy)
        if magnitude > 1.0 {
            dx /= magnitude
            dy /= magnitude
        }

        // Apply dead zone
        if magnitude < deadZone {
            dx = 0
            dy = 0
        }

        // Move knob visual
        knobImageView.center = CGPoint(
            x: center.x + dx * maxDisplacement,
            y: center.y + dy * maxDisplacement
        )

        // Report (Y inverted: screen-down = gamepad-negative-Y)
        reportStick(x: Float(dx), y: Float(-dy))
    }

    private func reportStick(x: Float, y: Float) {
        if isLeft {
            bridge.updateLeftStick(x: x, y: y)
        } else {
            bridge.updateRightStick(x: x, y: y)
        }
    }

    private func returnToCenter() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.knobImageView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
    }
}

#endif
