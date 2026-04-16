import Foundation

// Moonlight button flag constants (from moonlight-common-c Limelight.h)
let BUTTON_A:        Int32 = 0x1000
let BUTTON_B:        Int32 = 0x2000
let BUTTON_X:        Int32 = 0x4000
let BUTTON_Y:        Int32 = 0x8000
let BUTTON_UP:       Int32 = 0x0001
let BUTTON_DOWN:     Int32 = 0x0002
let BUTTON_LEFT:     Int32 = 0x0004
let BUTTON_RIGHT:    Int32 = 0x0008
let BUTTON_LB:       Int32 = 0x0100
let BUTTON_RB:       Int32 = 0x0200
let BUTTON_LS_CLK:   Int32 = 0x0040
let BUTTON_RS_CLK:   Int32 = 0x0080
let BUTTON_START:    Int32 = 0x0010
let BUTTON_BACK:     Int32 = 0x0020
let BUTTON_SPECIAL:  Int32 = 0x0400

class SkinInputBridge {

    private var buttonFlags: Int32 = 0
    private var leftTrigger: UInt8 = 0
    private var rightTrigger: UInt8 = 0
    private var leftStickX: Int16 = 0
    private var leftStickY: Int16 = 0
    private var rightStickX: Int16 = 0
    private var rightStickY: Int16 = 0

    // Manic-Emu skins label face buttons by their position in the Nintendo/PS
    // convention (east=a, south=b, north=x, west=y). Moonlight uses the Xbox
    // convention (south=A, east=B, west=X, north=Y), so translate here.
    private static let flagMap: [String: Int32] = [
        "a": BUTTON_B,  // east  (PS circle)   → Xbox B
        "b": BUTTON_A,  // south (PS cross)    → Xbox A
        "x": BUTTON_Y,  // north (PS triangle) → Xbox Y
        "y": BUTTON_X,  // west  (PS square)   → Xbox X
        "up": BUTTON_UP,
        "down": BUTTON_DOWN,
        "left": BUTTON_LEFT,
        "right": BUTTON_RIGHT,
        "l1": BUTTON_LB,
        "r1": BUTTON_RB,
        "l3": BUTTON_LS_CLK,
        "r3": BUTTON_RS_CLK,
        "start": BUTTON_START,
        "select": BUTTON_BACK,
        "menu": BUTTON_SPECIAL,
    ]

    func activate(input: String, value: Double = 1.0) {
        if let flag = Self.flagMap[input] {
            buttonFlags |= flag
        } else if input == "l2" {
            leftTrigger = UInt8(clamping: Int(value * 255.0))
        } else if input == "r2" {
            rightTrigger = UInt8(clamping: Int(value * 255.0))
        }
        sendState()
    }

    func deactivate(input: String) {
        if let flag = Self.flagMap[input] {
            buttonFlags &= ~flag
        } else if input == "l2" {
            leftTrigger = 0
        } else if input == "r2" {
            rightTrigger = 0
        }
        sendState()
    }

    func updateLeftStick(x: Float, y: Float) {
        leftStickX = Int16(clamping: Int(x * 32767.0))
        leftStickY = Int16(clamping: Int(y * 32767.0))
        sendState()
    }

    func updateRightStick(x: Float, y: Float) {
        rightStickX = Int16(clamping: Int(x * 32767.0))
        rightStickY = Int16(clamping: Int(y * 32767.0))
        sendState()
    }

    private func sendState() {
        #if canImport(UIKit)
        LiSendMultiControllerEvent(
            0,      // controllerNumber
            0x01,   // activeGamepadMask
            buttonFlags,
            leftTrigger,
            rightTrigger,
            leftStickX,
            leftStickY,
            rightStickX,
            rightStickY
        )
        #endif
    }
}
