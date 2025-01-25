//
//  OnScreenKey.swift
//  Moonlight-ZWM
//
//  Created by ZWM on 2024/8/4.
//  Copyright © 2024 Moonlight Game Streaming Project. All rights reserved.
//

import UIKit


@objc class OnScreenButtonView: UIView, InstanceProviderDelegate {
    // receiving the OnScreenControls instance from delegate
    @objc func getOnScreenControlsInstance(_ sender: Any) {
        if let controls = sender as? OnScreenControls {
            self.onScreenControls = controls
            print("ClassA received OnScreenControls instance: \(controls)")
        } else {
            print("ClassA received an unknown sender")
        }
    }
    
    @objc static public var editMode: Bool = false
    @objc static public var timestampOfButtonBeingDragged: TimeInterval = 0
    private let appWindow: UIView
    
    @objc public var keyLabel: String
    @objc public var keyString: String
    @objc public var timestamp: TimeInterval
    @objc public var pressed: Bool
    @objc public var widthFactor: CGFloat
    @objc public var heightFactor: CGFloat
    @objc public var backgroundAlpha: CGFloat
    @objc public var latestTouchLocation: CGPoint
    @objc public var deltaX: CGFloat
    @objc public var deltaY: CGFloat
    @objc public var offSetX: CGFloat
    @objc public var offSetY: CGFloat

    private var quickDoubleTapDetected: Bool
    private var touchTapTimeInterval: TimeInterval
    private var touchTapTimeStamp: TimeInterval
    private let QUICK_TAP_TIME_INTERVAL = 0.2
    
    private var onScreenControls: OnScreenControls
    private let label: UILabel
    // private let originalBackgroundColor: UIColor
    private var touchBeganLocation: CGPoint = .zero
    private var storedLocation: CGPoint = .zero
    private let minimumBorderAlpha: CGFloat = 0.19
    private var defaultBorderColor: CGColor = UIColor(white: 0.2, alpha: 0.3).cgColor
    private let moonlightPurple: CGColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.86).cgColor
    private let crossMarkColor: CGColor = UIColor(white: 1, alpha: 0.7).cgColor
    private let stickBallColor: CGColor = UIColor(white: 1, alpha: 0.75).cgColor
    private var stickInputScale: CGFloat = 30
    
    private let borderLayer = CAShapeLayer()
    
    private var upIndicator = CAShapeLayer()
    private var downIndicator = CAShapeLayer()
    private var leftIndicator = CAShapeLayer()
    private var rightIndicator = CAShapeLayer()
    
    private var l3r3Indicator = CAShapeLayer()
    private var crossMarkLayer = CAShapeLayer()
    private var stickBallLayer = CAShapeLayer()
    private var lrudIndicatorBall = CAShapeLayer()
    @objc public var stickIndicatorXOffset: CGFloat = 120
    
    @objc init(keyString: String, keyLabel: String) {
        self.keyString = keyString
        self.keyLabel = keyLabel
        self.label = UILabel()
        // self.originalBackgroundColor = UIColor(white: 0.2, alpha: 0.7)
        self.timestamp = 0
        self.pressed = false
        self.widthFactor = 1.0
        self.heightFactor = 1.0
        self.backgroundAlpha = 0.5
        self.latestTouchLocation = CGPoint(x: 0, y: 0)
        self.deltaX = 0
        self.deltaY = 0
        self.offSetX = 0
        self.offSetY = 0
        self.onScreenControls = OnScreenControls()
        self.appWindow = UIApplication.shared.windows.first!
        self.quickDoubleTapDetected = false
        self.touchTapTimeInterval = 100
        self.touchTapTimeStamp = 100
        super.init(frame: .zero)
        
        upIndicator = createLrudDirectionLayer()
        upIndicator.anchorPoint = CGPoint(x: 0.5, y: 1)
        downIndicator = createLrudDirectionLayer()
        downIndicator.anchorPoint = CGPoint(x: 0.5, y: 0)
        leftIndicator = createLrudDirectionLayer()
        leftIndicator.anchorPoint = CGPoint(x: 1, y: 0.5)
        rightIndicator = createLrudDirectionLayer()
        rightIndicator.anchorPoint = CGPoint(x: 0, y: 0.5)

        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func setLocation(xOffset:CGFloat, yOffset:CGFloat) {
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: self.superview!.leadingAnchor, constant: xOffset),
            self.topAnchor.constraint(equalTo: self.superview!.topAnchor, constant: yOffset),
        ])
        storedLocation = CGPointMake(xOffset, yOffset)
    }
    
    @objc public func enableRelocationMode(enabled: Bool){
        OnScreenButtonView.editMode = enabled
    }
    
    @objc public func adjustButtonTransparency(alpha: CGFloat){
        if alpha != 0 {
            self.backgroundAlpha = alpha
        }
        else{
            self.backgroundAlpha = 0.5
        }
        
        // setup default border from self.backgroundAlpha
        var borderAlpha = 1.15 * self.backgroundAlpha
        if borderAlpha < minimumBorderAlpha {
            borderAlpha = minimumBorderAlpha
        }
        defaultBorderColor = UIColor(white: 0.2, alpha: borderAlpha).cgColor
        self.layer.borderColor = defaultBorderColor
        
        if CommandManager.touchPadCmds.contains(self.keyString){
            self.backgroundColor = UIColor.clear // make touchPad transparent
            self.layer.borderColor = UIColor(white: 0.2, alpha: borderAlpha - 0.2).cgColor // reduce border alpha for touchPad
        }
        else{ // backgroundColor works for buttons other than touch pad
            self.backgroundColor = UIColor(white: 0.2, alpha: self.backgroundAlpha - 0.18) // offset to be consistent with onScreen controller layer opacity
        }
    }
    
    @objc public func resizeButtonView(){
        guard let superview = superview else { return }
        
        
        // Deactivate existing constraints if necessary
        NSLayoutConstraint.deactivate(self.constraints)
        
        // To resize the button, we must set this to false temporarily
        translatesAutoresizingMaskIntoConstraints = false
        
        
        // replace invalid factor values
        if self.widthFactor == 0 {self.widthFactor = 1.0}
        if self.heightFactor == 0 {self.heightFactor = 1.0}
        
        // Constraints for resizing
        let newWidthConstraint = self.widthAnchor.constraint(equalToConstant: 70 * self.widthFactor)
        let newHeightConstraint = self.heightAnchor.constraint(equalToConstant: 65 * self.heightFactor)
        
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 70 * self.widthFactor),
            self.heightAnchor.constraint(equalToConstant: 65 * self.heightFactor),
        ])
        
        
        // Trigger layout update
        superview.layoutIfNeeded()
        
        // Re-setup buttonView style
        setupView()
    }
    
    
    
    @objc public func setupView() {
        label.text = self.keyLabel
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1  // Adjust the scale factor as needed
        
        label.textColor = UIColor(white: 1.0, alpha: 0.82)
        label.textAlignment = .center
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.translatesAutoresizingMaskIntoConstraints = false // enable auto alignment for the label
        
        self.translatesAutoresizingMaskIntoConstraints = true // this is mandatory to prevent unexpected key view location change
        
        // reset to default border
        self.layer.borderWidth = 1
        var borderAlpha = 1.15 * self.backgroundAlpha
        if borderAlpha < minimumBorderAlpha {
            borderAlpha = minimumBorderAlpha
        }
        defaultBorderColor = UIColor(white: 0.2, alpha: borderAlpha).cgColor
        self.borderLayer.borderColor = defaultBorderColor
        
        self.layer.cornerRadius = 15
        
        if CommandManager.touchPadCmds.contains(self.keyString){
            self.backgroundColor = UIColor.clear // make touchPad transparent
            self.layer.borderColor = UIColor(white: 0.2, alpha: borderAlpha - 0.2).cgColor // reduce border alpha for touchPad
            label.text = "" // make touchPad display no text
        }
        else{ // backgroundColor works for buttons other than touch pad
            self.backgroundColor = UIColor(white: 0.2, alpha: self.backgroundAlpha - 0.18) // offset to be consistent with onScreen controller layer opacity
        }
        // self.layer.shadowColor = UIColor.clear.cgColor
        // self.layer.shadowRadius = 8
        // self.layer.shadowOpacity = 0.5
        
        addSubview(label)
        
        NSLayoutConstraint.activate([
            //self.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.088),
            //self.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.1),
            self.widthAnchor.constraint(equalToConstant: 70 * self.widthFactor),
            self.heightAnchor.constraint(equalToConstant: 65 * self.widthFactor),
        ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10), // set up label size contrain within UIView
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            //label.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        setupBorderLayer();
    }
    
    private func createAndShowl3r3Indicator() -> CAShapeLayer{
        let indicatorFrame = CAShapeLayer();
        let indicatorBorder = CAShapeLayer();
        
        indicatorFrame.frame = CGRectMake(0, 0, 80, 80)
        indicatorFrame.cornerRadius = 9
        indicatorBorder.borderWidth = 9
        indicatorBorder.frame = indicatorFrame.bounds.insetBy(dx: -indicatorBorder.borderWidth, dy: -indicatorBorder.borderWidth) // Adjust the inset as needed
        indicatorBorder.borderColor = UIColor.clear.cgColor
        
        indicatorBorder.cornerRadius = indicatorFrame.cornerRadius + indicatorBorder.borderWidth
        indicatorBorder.backgroundColor = UIColor.clear.cgColor
        indicatorBorder.fillColor = UIColor.clear.cgColor
        let path = UIBezierPath(roundedRect: indicatorBorder.bounds, cornerRadius: indicatorBorder.cornerRadius)
        indicatorBorder.path = path.cgPath
        indicatorBorder.borderColor = moonlightPurple
        
        self.layer.superlayer?.addSublayer(indicatorBorder)
        indicatorBorder.position = CGPointMake(CGRectGetMinX(self.frame)+touchBeganLocation.x, CGRectGetMinY(self.frame)+touchBeganLocation.y)
        
        return indicatorBorder
    }

    
    
    
    
    //================================================================================================
    //Indicator overlay for on-screen game controller left or right sticks (non-velocity mode)
    
    // create stick indicator: the crossMark & stickBall:
    private func showStickIndicator(){
        // tell if the self button is located on the left or right
        if(self.storedLocation.x + self.frame.width/2 > self.appWindow.frame.width*0.5){
            self.stickIndicatorXOffset = -abs(self.stickIndicatorXOffset)
        }
        else{
            self.stickIndicatorXOffset = abs(self.stickIndicatorXOffset)
        }
        
        let stickMarkerRelativeLocation = CGPointMake(touchBeganLocation.x + self.stickIndicatorXOffset, touchBeganLocation.y)
        self.crossMarkLayer = createAndShowCrossMarkOnTouchPoint(at: stickMarkerRelativeLocation)
        self.stickBallLayer = createAndShowStickBall(at: stickMarkerRelativeLocation)
    }
    
    // cross mark for left & right gamePad
    private func createAndShowCrossMarkOnTouchPoint(at point: CGPoint) -> CAShapeLayer {
        let crossLayer = CAShapeLayer()
        let path = UIBezierPath()
        let crossSize = 45.0
        
        path.move(to: CGPoint(x: point.x - crossSize / 2, y: point.y))
        path.addLine(to: CGPoint(x: point.x + crossSize / 2, y: point.y))
        
        // 竖线
        path.move(to: CGPoint(x: point.x, y: point.y - crossSize / 2))
        path.addLine(to: CGPoint(x: point.x, y: point.y + crossSize / 2))
        
        crossLayer.path = path.cgPath
        crossLayer.strokeColor = crossMarkColor
        crossLayer.lineWidth = 1
        crossLayer.fillColor = crossMarkColor
        
        self.layer.superlayer?.addSublayer(crossLayer)
        crossLayer.position = CGPointMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame))
        // crossLayer.shadowRadius = 1
        crossLayer.shadowColor = UIColor.black.cgColor
        crossLayer.shadowOffset = CGSize(width: 1, height: 1)
        crossLayer.shadowRadius = 0;
        crossLayer.shadowOpacity = 0.8
        
        return crossLayer
    }
    
    private func createAndShowStickBall(at center: CGPoint) -> CAShapeLayer {
        // Create a circular path using UIBezierPath
        let path = UIBezierPath(arcCenter: center, radius: 10, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // Create a CAShapeLayer
        let stickBallLayer = CAShapeLayer()
        stickBallLayer.path = path.cgPath  // Assign the circular path to the shape layer
        self.layer.superlayer?.addSublayer(stickBallLayer)
        stickBallLayer.position = CGPointMake(CGRectGetMidX(self.crossMarkLayer.frame), CGRectGetMinY(self.crossMarkLayer.frame))
        
        // stickBallLayer.position = CG
        
        // Set the stroke color and width (border of the circle)
        stickBallLayer.strokeColor = stickBallColor
        stickBallLayer.lineWidth = 0
        stickBallLayer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        stickBallLayer.shadowRadius = 0;
        stickBallLayer.shadowOpacity = 0.8
        
        // Set the fill color (inside of the circle)
        stickBallLayer.fillColor = stickBallColor  // Light fill with some transparency
        
        return stickBallLayer
    }
    
    private func updateStickBallPosition(){
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.stickBallLayer.removeAllAnimations()
        self.stickBallLayer.position = CGPointMake(CGRectGetMidX(self.crossMarkLayer.frame) + touchInputToStickBallCoord(input: offSetX), CGRectGetMinY(self.crossMarkLayer.frame) + touchInputToStickBallCoord(input: offSetY))
        CATransaction.commit()
    }
    
    //================================================================================================
    
    
    
    
    
    
    
    //=====LRUD(left right up & down buttons) touchPad touch =========================================
    
    private func createAndShowLrudBall(at point: CGPoint) -> CAShapeLayer {
        // Create a circular path using UIBezierPath
        let path = UIBezierPath(arcCenter: point, radius: 10, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // Create a CAShapeLayer
        let ballLayer = CAShapeLayer()
        ballLayer.path = path.cgPath  // Assign the circular path to the shape layer
        self.layer.superlayer?.addSublayer(ballLayer)
        
        ballLayer.position = CGPointMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame))
        
        // Set the stroke color and width (border of the circle)
        ballLayer.strokeColor = stickBallColor
        ballLayer.lineWidth = 0
        ballLayer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        ballLayer.shadowRadius = 0;
        ballLayer.shadowOpacity = 0.8
        
        // Set the fill color (inside of the circle)
        ballLayer.fillColor = stickBallColor  // Light fill with some transparency
        return ballLayer
    }
    
    private func createLrudDirectionLayer() -> CAShapeLayer {
        let indicatorFrame = CAShapeLayer();
        let indicatorBorder = CAShapeLayer();
        
        indicatorFrame.frame = CGRectMake(0, 0, 80, 80)
        indicatorFrame.cornerRadius = 9
        indicatorBorder.borderWidth = 6
        indicatorBorder.frame = indicatorFrame.bounds.insetBy(dx: -indicatorBorder.borderWidth, dy: -indicatorBorder.borderWidth) // Adjust the inset as needed
        indicatorBorder.borderColor = UIColor.clear.cgColor
        
        indicatorBorder.cornerRadius = indicatorFrame.cornerRadius + indicatorBorder.borderWidth
        indicatorBorder.backgroundColor = UIColor.clear.cgColor
        indicatorBorder.fillColor = UIColor.clear.cgColor
        let path = UIBezierPath(roundedRect: indicatorBorder.bounds, cornerRadius: indicatorBorder.cornerRadius)
        indicatorBorder.path = path.cgPath
        indicatorBorder.borderColor = moonlightPurple
        
        return indicatorBorder
    }
    
    private func showLrudDirectionIndicator(with indicatorLayer:CAShapeLayer){
        // Add the border layer below the super layer
        self.layer.superlayer?.insertSublayer(indicatorLayer, below: self.layer)
        
        // show the indicator based on the touchBeganLocation
        indicatorLayer.position = CGPointMake(CGRectGetMinX(self.frame)+touchBeganLocation.x, CGRectGetMinY(self.frame)+touchBeganLocation.y)
    }
    
    private func handleLrudTouchMove(){
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let triggeringAngle = 67.5
        let radians  = atan2(-offSetY,offSetX)
        let degrees = radians * 180 / .pi
        enum Direction: Int {
            case right = 1
            case up = 2
            case left = 4
            case down = 8
        }
        
        let nearZeroPoint = abs(offSetX)<28 && abs(offSetY)<28
        
        NSLog("deltaX: %f, detalY: %f", deltaX, deltaY)
        
        var buttonPressed = 0;
        if abs(degrees) < triggeringAngle {
            // NSLog("button pressed: right")
            buttonPressed = buttonPressed | Direction.right.rawValue
        }
        if 180.0 - abs(degrees) < triggeringAngle {
            // NSLog("button pressed: left")
            buttonPressed = buttonPressed | Direction.left.rawValue
        }
        if abs(90.0 - degrees) < triggeringAngle {
            // NSLog("button pressed: up")
            buttonPressed = buttonPressed | Direction.up.rawValue
        }
        if abs(-90.0 - degrees) < triggeringAngle {
            // NSLog("button pressed: down")
            buttonPressed = buttonPressed | Direction.down.rawValue
        }
        if nearZeroPoint {buttonPressed = 0}
        
        if(buttonPressed & Direction.up.rawValue == Direction.up.rawValue){
            showLrudDirectionIndicator(with: upIndicator)
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["W"]!,Int8(KEY_ACTION_DOWN), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["UP_ARROW"]!,Int8(KEY_ACTION_DOWN), 0)
            case "DPAD": break
            default: break
            }
        }
        else{
            self.upIndicator.removeFromSuperlayer()
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["W"]!,Int8(KEY_ACTION_UP), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["UP_ARROW"]!,Int8(KEY_ACTION_UP), 0)
            case "DPAD": break
            default: break
            }
        }
        if(buttonPressed & Direction.down.rawValue == Direction.down.rawValue){
            showLrudDirectionIndicator(with: downIndicator)
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["S"]!,Int8(KEY_ACTION_DOWN), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["DOWN_ARROW"]!,Int8(KEY_ACTION_DOWN), 0)
            case "DPAD": break
            default: break
            }
        }
        else{
            self.downIndicator.removeFromSuperlayer()
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["S"]!,Int8(KEY_ACTION_UP), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["DOWN_ARROW"]!,Int8(KEY_ACTION_UP), 0)
            case "DPAD": break
            default: break
            }
        }
        if(buttonPressed & Direction.left.rawValue == Direction.left.rawValue){
            showLrudDirectionIndicator(with: leftIndicator)
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["A"]!,Int8(KEY_ACTION_DOWN), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["LEFT_ARROW"]!,Int8(KEY_ACTION_DOWN), 0)
            case "DPAD": break
            default: break
            }
        }
        else{
            self.leftIndicator.removeFromSuperlayer()
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["A"]!,Int8(KEY_ACTION_UP), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["LEFT_ARROW"]!,Int8(KEY_ACTION_UP), 0)
            case "DPAD": break
            default: break
            }
        }
        if(buttonPressed & Direction.right.rawValue == Direction.right.rawValue){
            showLrudDirectionIndicator(with: rightIndicator)
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["D"]!,Int8(KEY_ACTION_DOWN), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["RIGHT_ARROW"]!,Int8(KEY_ACTION_DOWN), 0)
            case "DPAD": break
            default: break
            }
        }
        else{
            self.rightIndicator.removeFromSuperlayer()
            switch keyString {
            case "WASDPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["D"]!,Int8(KEY_ACTION_UP), 0)
            case "ARROWPAD": LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["RIGHT_ARROW"]!,Int8(KEY_ACTION_UP), 0)
            case "DPAD": break
            default: break
            }
        }
        
        CATransaction.commit()
    }
    //================================================================================================
    
    
    
    
    //==== wholeButtonPress visual effect=============================================
    private func buttonDownVisualEffect() {
        // setupBorderLayer()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // self.layer.borderWidth = 0
        borderLayer.borderWidth = 8.6
        borderLayer.borderColor = moonlightPurple
        CATransaction.commit()
    }
    
    private func buttonUpVisualEffect() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // self.layer.borderWidth = 1
        borderLayer.borderWidth = 0
        borderLayer.borderColor = defaultBorderColor
        CATransaction.commit()
    }
    
    
    private func setupBorderLayer() {
        // Create a shape layer for the border
        
        // Set the frame to be larger than the view to expand outward
        borderLayer.borderWidth = 0
        borderLayer.frame = self.bounds.insetBy(dx: -8.6, dy: -8.6) // Adjust the inset as needed
        borderLayer.cornerRadius = self.layer.cornerRadius + 8.6
        borderLayer.backgroundColor = UIColor.clear.cgColor;
        borderLayer.fillColor = UIColor.clear.cgColor;
        
        // Create a path for the border
        let path = UIBezierPath(roundedRect: borderLayer.bounds, cornerRadius: borderLayer.cornerRadius)
        borderLayer.path = path.cgPath
        
        // Add the border layer below the main view layer
        self.layer.superlayer?.insertSublayer(borderLayer, below: self.layer)
        
        // Retrieve the current frame to account for transformations, this will update the coords for new position CGPointMake
        borderLayer.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
    }
    //==========================================================================================================
    
    
    //=========================================send on screen controller stick events
    private func touchInputToStickInput(input: CGFloat) -> CGFloat{
        var target = 0x7FFE * input / stickInputScale
        if target > 0x7FFE {target = 0x7FFE}
        if target < -0x7FFE {target = -0x7FFE}
        return target
    }
    
    private func touchInputToStickBallCoord(input: CGFloat) -> CGFloat {
        if input > stickInputScale {return 18}
        if input < -stickInputScale {return -18}
        return input * (18/stickInputScale)
    }
    
    private func sendRightStickTouchPadEvent(inputX: CGFloat, inputY: CGFloat){
        let targetX = self.touchInputToStickInput(input: inputX)
        let targetY = -self.touchInputToStickInput(input: inputY)
 // vertical input must be inverted
        self.onScreenControls.sendRightStickTouchPadEvent(targetX, targetY)
    }
    
    private func sendLeftStickTouchPadEvent(inputX: CGFloat, inputY: CGFloat){
        let targetX = self.touchInputToStickInput(input: inputX)
        let targetY = -self.touchInputToStickInput(input: inputY)
        self.onScreenControls.sendLeftStickTouchPadEvent(targetX, targetY)
    }
    //==========================================================================================================

    
    
    
    
    
    
    // Touch event handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // print("touchDown: %f", CACurrentMediaTime())
        
        if touches.count == 1 {
            
            let currentTime = CACurrentMediaTime()
            touchTapTimeInterval = currentTime - touchTapTimeStamp
            touchTapTimeStamp = currentTime
            quickDoubleTapDetected = touchTapTimeInterval < QUICK_TAP_TIME_INTERVAL
            
            let touch = touches.first
            self.touchBeganLocation = touch!.location(in: self)
            self.latestTouchLocation = touchBeganLocation
        }
        
        self.pressed = true
        super.touchesBegan(touches, with: event)
        //self.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.7)
        
        // OnScreenControls.testMethod();
        // RelativeTouchHandler.testMethod();
        
        if !OnScreenButtonView.editMode {
            if CommandManager.touchPadCmds.contains(self.keyString) && touches.count == 1{
                switch self.keyString {
                case "LSPAD":
                    self.showStickIndicator()
                    if quickDoubleTapDetected {
                        self.l3r3Indicator = self.createAndShowl3r3Indicator()
                        self.onScreenControls.pressDownL3()}
                    break
                case "RSPAD":
                    self.showStickIndicator()
                    if quickDoubleTapDetected {
                        self.l3r3Indicator = self.createAndShowl3r3Indicator()
                        self.onScreenControls.pressDownR3()}
                    break
                case "LSVPAD":
                    if quickDoubleTapDetected {
                        self.l3r3Indicator = self.createAndShowl3r3Indicator()
                        self.onScreenControls.pressDownL3()}
                    break
                case "RSVPAD":
                    if quickDoubleTapDetected {
                        self.l3r3Indicator = self.createAndShowl3r3Indicator()
                        self.onScreenControls.pressDownR3()}
                    break
                case "DPAD", "WASDPAD", "ARROWPAD":
                    self.lrudIndicatorBall = createAndShowLrudBall(at: touchBeganLocation)
                    break
                default:
                    break
                }
            }
            
            if !CommandManager.touchPadCmds.contains(self.keyString) {
                self.buttonDownVisualEffect()
            }
            // if the command(keystring contains "+", it's a multi-key command or a quick triggering key, rather than a physical button
            if self.keyString.contains("+"){
                let keyboardCmdStrings = CommandManager.shared.extractKeyStrings(from: self.keyString)!
                CommandManager.shared.sendKeyDownEventWithDelay(keyboardCmdStrings: keyboardCmdStrings) // send multi-key command
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { // reset shadow color immediately 50ms later
                    self.buttonUpVisualEffect()
                }
            }
            // if there's no "+" in the keystring, treat it as a regular button:
            if CommandManager.keyboardButtonMappings.keys.contains(self.keyString) {
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings[self.keyString]!,Int8(KEY_ACTION_DOWN), 0)
            }
            if CommandManager.mouseButtonMappings.keys.contains(self.keyString) {
                LiSendMouseButtonEvent(CChar(BUTTON_ACTION_PRESS), Int32(CommandManager.mouseButtonMappings[self.keyString]!))
            }
        }
        // here is in edit mode:
        else{
            NotificationCenter.default.post(name: Notification.Name("OnScreenButtonViewSelected"),object: self) // inform layout tool controller to fetch button size factors. self will be passed as the object of the notification
            if let touch = touches.first {
                let touchLocation = touch.location(in: superview)
                storedLocation = touchLocation
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        OnScreenButtonView.timestampOfButtonBeingDragged = self.timestamp
        
        if !OnScreenButtonView.editMode {
            if CommandManager.touchPadCmds.contains(self.keyString){
                handleTouchPadMoveEvent(touches: touches)
            }
        }
        
        // Move the buttonView based on touch movement in relocation mode
        if OnScreenButtonView.editMode {
            if let touch = touches.first {
                let currentLocation = touch.location(in: superview)
                let offsetX = currentLocation.x - storedLocation.x
                let offsetY = currentLocation.y - storedLocation.y
                
                center = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
                //NSLog("x coord: %f, y coord: %f", self.frame.origin.x, self.frame.origin.y)
                storedLocation = currentLocation // Update initial center for next movement
            }
        }
        
    }
    
    private func handleTouchPadMoveEvent (touches: Set<UITouch>){
        if touches.count == 1{
            let currentTouchLocation: CGPoint = (touches.first?.location(in: self))!
            
            self.deltaX = currentTouchLocation.x - self.latestTouchLocation.x
            self.deltaY = currentTouchLocation.y - self.latestTouchLocation.y
            self.offSetX = currentTouchLocation.x - self.touchBeganLocation.x
            self.offSetY = currentTouchLocation.y - self.touchBeganLocation.y
            self.latestTouchLocation = currentTouchLocation
            
            switch self.keyString{
            case "LSPAD":
                self.sendLeftStickTouchPadEvent(inputX: offSetX, inputY: offSetY)
                updateStickBallPosition()
                break
            case "RSPAD":
                self.sendRightStickTouchPadEvent(inputX: offSetX, inputY: offSetY);
                updateStickBallPosition()
                break
            case "LSVPAD":
                self.sendLeftStickTouchPadEvent(inputX: deltaX, inputY: deltaY)
                break
            case "RSVPAD":
                self.sendRightStickTouchPadEvent(inputX: deltaX, inputY: deltaY);
                break
            case "DPAD", "WASDPAD", "ARROWPAD":
                handleLrudTouchMove()
                break
            default:
                break
            }

        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // self.pressed = false // will be reset outside the class
        super.touchesEnded(touches, with: event)
        quickDoubleTapDetected = false
        if !OnScreenButtonView.editMode && CommandManager.touchPadCmds.contains(self.keyString) && touches.count == 1 {
            switch self.keyString{
            case "LSPAD":
                self.onScreenControls.clearLeftStickTouchPadFlag()
                self.crossMarkLayer.removeFromSuperlayer()
                self.stickBallLayer.removeFromSuperlayer()
                break
            case "RSPAD":
                self.onScreenControls.clearRightStickTouchPadFlag()
                self.crossMarkLayer.removeFromSuperlayer()
                self.stickBallLayer.removeFromSuperlayer()
                break
            case "LSVPAD":
                self.onScreenControls.clearLeftStickTouchPadFlag()
                break
            case "RSVPAD":
                self.onScreenControls.clearRightStickTouchPadFlag()
                break
            case "WASDPAD":
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["W"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["A"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["S"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["D"]!,Int8(KEY_ACTION_UP), 0)
            case "ARROWPAD":
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["LEFT_ARROW"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["RIGHT_ARROW"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["UP_ARROW"]!,Int8(KEY_ACTION_UP), 0)
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings["DOWN_ARROW"]!,Int8(KEY_ACTION_UP), 0)
            case "DPAD": break
            default:
                break
            }
        }
        
        self.buttonUpVisualEffect()
        self.l3r3Indicator.removeFromSuperlayer()
        self.upIndicator.removeFromSuperlayer()
        self.downIndicator.removeFromSuperlayer()
        self.leftIndicator.removeFromSuperlayer()
        self.rightIndicator.removeFromSuperlayer()
        self.lrudIndicatorBall.removeFromSuperlayer()
                        
        if !OnScreenButtonView.editMode && !self.keyString.contains("+") { // if the command(keystring contains "+", it's a multi-key command rather than a single key button
            
            if CommandManager.mouseButtonMappings.keys.contains(self.keyString){
                LiSendMouseButtonEvent(CChar(BUTTON_ACTION_RELEASE), Int32(CommandManager.mouseButtonMappings[self.keyString]!))
            }
            if CommandManager.keyboardButtonMappings.keys.contains(self.keyString) {
                LiSendKeyboardEvent(CommandManager.keyboardButtonMappings[self.keyString]!,Int8(KEY_ACTION_UP), 0)
            }
        }
        
        if OnScreenButtonView.editMode {
            guard let superview = superview else { return }
            
            // Deactivate existing constraints if necessary
            NSLayoutConstraint.deactivate(self.constraints)
            
            // Add new constraints based on the current center position
            translatesAutoresizingMaskIntoConstraints = true
            
            // Create new constraints
            let newLeadingConstraint = self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: self.frame.origin.x)
            let newTopConstraint = self.topAnchor.constraint(equalTo: superview.topAnchor, constant: self.frame.origin.y)
            
            // Activate the new location constraints
            NSLayoutConstraint.activate([newLeadingConstraint, newTopConstraint])
            
            // Trigger layout update
            superview.layoutIfNeeded()
            
            setupView(); //re-setup buttonView style
        }
    }
}

