//
//  PulseTargetView.swift
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
    static let pointsPerFoot: CGFloat = 6  // screen points per foot of target range from dialCenter
    static let targetRadius: CGFloat = 16
}

class PulseTargetView: UIView {
    
    var pulsePercent: Double = 0 { didSet { setNeedsDisplay() } }  // pulse wave position: 0 is at dialCenter, 100 is above top of screen
    var targetSimulating = false
    var targetRange = 0.0 { didSet { setNeedsDisplay() } }  // feet
    var targetHeading = 0.0 { didSet { setNeedsDisplay() } }  // radians: +/-pi/4 (ie. +/-45 degrees) is in view
    var targetAgePercent = 0.0  // target life cycle: 0 is point, 100 is ring fully grown and faded away

    private let targetAgePercents:       [CGFloat] = [  0,  10,  20,  30,  40,  50,  60,  70,  80,  90, 100]
    private let targetCenterAlphas:      [CGFloat] = [0.0, 0.5, 1.0, 1.0, 1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0]
    private let targetRingAlphas:        [CGFloat] = [0.0, 0.5, 1.0, 1.0, 1.0, 1.0, 0.8, 0.6, 0.4, 0.2, 0.0]
    private let targetRingRadiusFactors: [CGFloat] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0]  // times targetRadius
    private let interpolate = Interpolate<CGFloat>()

    private lazy var dialCenter = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)

    override func draw(_ rect: CGRect) {
        if targetSimulating { drawTarget() }
        drawPulse()
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
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()  // need to save and restore context after drawing target, so clipping doesn't apply to pulse
            
            let indexAndRatio = interpolate.getIndexAndRatio(value: CGFloat(targetAgePercent), array: targetAgePercents)
            let targetCenterAlpha = interpolate.getResult(from: targetCenterAlphas, using: indexAndRatio)
            let targetRingAlpha = interpolate.getResult(from: targetRingAlphas, using: indexAndRatio)
            //        let targetRingRadius = interpolate.getResult(from: targetRingRadiusFactors, using: indexAndRatio) * Pulse.targetRadius
            let targetRingRadius = (1 + 0.05 * CGFloat(targetAgePercent)) * Pulse.targetRadius
            
            let targetX = CGFloat(targetRange * sin(targetHeading)) * Pulse.pointsPerFoot
            let targetY = -CGFloat(targetRange * cos(targetHeading)) * Pulse.pointsPerFoot
            let center = CGPoint(x: dialCenter.x + targetX, y: dialCenter.y + targetY)
            
            // clip target drawing to sensor area
            let dialOuterRadius = 1.1 * bounds.width * Dial.outerRadiusFactor
            let wedge = UIBezierPath()
            wedge.move(to: dialCenter)
            wedge.addArc(withCenter: dialCenter, radius: bounds.height, startAngle: -135.rads, endAngle: -45.rads, clockwise: true)
            wedge.addArc(withCenter: dialCenter, radius: dialOuterRadius, startAngle: -45.rads, endAngle: -135.rads, clockwise: false)
            wedge.addClip()
            
            let targetCenter = UIBezierPath(arcCenter: center, radius: Pulse.targetRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            let centerColor = UIColor(red: 1, green: 0, blue: 0, alpha: targetCenterAlpha)
            centerColor.setFill()
            targetCenter.fill()
            
            let targetRing = UIBezierPath(arcCenter: center, radius: targetRingRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            let ringColor = UIColor(red: 1, green: 0, blue: 0, alpha: targetRingAlpha)
            ringColor.setStroke()
            targetRing.lineWidth = 4
            targetRing.stroke()
            
            context.restoreGState()
        }
    }
}
