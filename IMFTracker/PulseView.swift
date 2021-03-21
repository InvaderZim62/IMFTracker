//
//  PulseView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/19/21.
//

import UIKit

struct Pulse {
    static let primaryColor = #colorLiteral(red: 0, green: 0.7745906711, blue: 1, alpha: 1)
    static let secondaryColor = #colorLiteral(red: 0, green: 0.259739399, blue: 0.8598743081, alpha: 1)
    static let tertiaryColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
    static let screenOvershoot: CGFloat = 1.3  // pulsePercent = 100 is 30% past top of screen (to cause slight delay before next pulse starts)
    static let pointsPerFoot: CGFloat = 6  // screen points per foot of target range
}

class PulseView: UIView {
    
    var pulsePercent: Double = 66 { didSet { setNeedsDisplay() } }
    var targetDetected = false
    var targetRange = 0.0 { didSet { setNeedsDisplay() } }  // feet
    var targetHeading = 0.0 { didSet { setNeedsDisplay() } }  // radians

    private lazy var dialCenter = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)

    override func draw(_ rect: CGRect) {
        drawPulse()
        if targetDetected { drawTarget() }
    }
    
    func radiusFromPercent(_ percent: Double) -> Double {
        return Double(Pulse.screenOvershoot * bounds.height * Dial.centerFromTopFactor) * pulsePercent / 100
    }

    private func drawPulse() {
        let primaryRadius = CGFloat(radiusFromPercent(pulsePercent))
        let secondaryRadius = primaryRadius + max(12 * CGFloat(sin(pulsePercent / 4)), 0)  // one-sided sine wave
        let tertiaryRadius = primaryRadius - (pulsePercent > 20 ? 0.04 * (primaryRadius - 20) : 0)  // begins to separate after 20%
        
        let tertiaryPulse = UIBezierPath(arcCenter: dialCenter, radius: tertiaryRadius, startAngle: -135.rads, endAngle: -45.rads, clockwise: true)
        Pulse.tertiaryColor.setStroke()
        tertiaryPulse.lineWidth = 2
        tertiaryPulse.stroke()

        let secondaryPulse = UIBezierPath(arcCenter: dialCenter, radius: secondaryRadius, startAngle: -135.rads, endAngle: -45.rads, clockwise: true)
        Pulse.secondaryColor.setStroke()
        secondaryPulse.lineWidth = 8
        secondaryPulse.stroke()

        let primaryPulse = UIBezierPath(arcCenter: dialCenter, radius: primaryRadius, startAngle: -135.rads, endAngle: -45.rads, clockwise: true)
        Pulse.primaryColor.setStroke()
        primaryPulse.lineWidth = 8
        primaryPulse.stroke()
    }
    
    private func drawTarget() {
        let targetX = CGFloat(targetRange * sin(targetHeading)) * Pulse.pointsPerFoot
        let targetY = -CGFloat(targetRange * cos(targetHeading)) * Pulse.pointsPerFoot
        let center = CGPoint(x: dialCenter.x + targetX, y: dialCenter.y + targetY)
        let circle = UIBezierPath(arcCenter: center, radius: 10, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        UIColor.red.setStroke()
        circle.stroke()
    }
}
