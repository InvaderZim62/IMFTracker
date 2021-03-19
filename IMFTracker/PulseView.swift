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
}

class PulseView: UIView {
    
    var pulsePercent: Double = 66 { didSet { setNeedsDisplay() } }
    
    private lazy var dialCenter = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)

    override func draw(_ rect: CGRect) {
        drawPulse()
    }

    private func drawPulse() {
        let primaryRadius = 1.3 * bounds.height * Dial.centerFromTopFactor * CGFloat(pulsePercent) / 100
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
}
