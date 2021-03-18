//
//  IMFTrackerView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//

import UIKit

struct General {
    static let D2R = CGFloat.pi / 180
    static let lighterBackgroundColor = #colorLiteral(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
}

struct Dots {
    static let numberOfRadials = 9
    static let numberOfRows = 11
    static let originFromTopFactor: CGFloat = 1.1  // percent bounds height (origin of dot lines is below the screen - near home button)
    static let firstRowDistanceFromTopFactor: CGFloat = 0.53  // percent bounds height
    static let color = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    static let blobColor = #colorLiteral(red: 0, green: 0.5769764185, blue: 1, alpha: 1)
}

struct Dial {
    static let centerFromTopFactor: CGFloat = 0.7  // percent bounds height
    static let outerRadiusFactor: CGFloat = 0.21  // percent bounds width
    static let innerCircleFactor: CGFloat = 0.3  // percent outer radius
    static let outerRingColor = #colorLiteral(red: 0.007069805637, green: 0.3669355512, blue: 0.9889140725, alpha: 1)
    static let clockBeadColor = #colorLiteral(red: 0.01647673175, green: 0.9682727456, blue: 0.4770763516, alpha: 1)
    static let upperBrightWedgeColor = #colorLiteral(red: 0.9179044366, green: 0.9080289602, blue: 0.5714150071, alpha: 1)
    static let outerSideWedgeColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
    static let innerRingColor = #colorLiteral(red: 0.3280324042, green: 0.336155057, blue: 0.07936634868, alpha: 1)
    static let innerCenterColor = #colorLiteral(red: 0.1362066269, green: 0.2441202402, blue: 0.07585870475, alpha: 1)
    static let largeXColor = #colorLiteral(red: 0.6209777594, green: 0.6121075153, blue: 0.4009537101, alpha: 1)
}

struct Pulse {
    static let primaryColor = #colorLiteral(red: 0, green: 0.7745906711, blue: 1, alpha: 1)
    static let secondaryColor = #colorLiteral(red: 0, green: 0.259739399, blue: 0.8598743081, alpha: 1)
    static let tertiaryColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
}

class IMFTrackerView: UIView {
    
    var pulsePercent: Double = 66 { didSet { setNeedsDisplay() } }
    
    private lazy var dialCenter = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)
    private lazy var dotRowSpacing = bounds.height * Dial.centerFromTopFactor / CGFloat(Dots.numberOfRows + 3)
    private lazy var firstDotRowDistanceFromTop = bounds.height * Dots.firstRowDistanceFromTopFactor
    private lazy var dotLinesOriginFromTop = bounds.height * Dots.originFromTopFactor
    private lazy var blobs = makeBlobs()

    override func draw(_ rect: CGRect) {
        drawDotsAndBlobs()
        drawDial()
        drawPulse()
        drawBottomSection()
    }
    
    private func makeBlobs() -> [UIBezierPath] {
        var blobs = [UIBezierPath]()
        for row in 0..<Dots.numberOfRows {
            if row < Dots.numberOfRows - 1 {
                let blobCenter = CGPoint(x: bounds.midX, y: firstDotRowDistanceFromTop - (CGFloat(row) + 0.3) * dotRowSpacing)
                let blobSize = CGSize(width: min(5 + row, 8), height: min(2 + row, 4))
                blobs.append(makeBlob(center: blobCenter, size: blobSize))
            }
        }
        return blobs
    }
    
    private func makeBlob(center: CGPoint, size: CGSize) -> UIBezierPath {
        let blob = UIBezierPath()
        for _ in 0..<15 {
            let randomCenter = normalRandom(center: center, size: size)
            let randomRadius = CGFloat.random(in: min(size.height - 1, 2)..<size.height)
            blob.move(to: randomCenter)
            blob.addArc(withCenter: randomCenter, radius: randomRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        }
        return blob
    }
    
    private func normalRandom(center: CGPoint, size: CGSize) -> CGPoint {
        let uniformRandom = CGPoint(x: CGFloat(arc4random()) / CGFloat(UINT32_MAX),
                                    y: CGFloat(arc4random()) / CGFloat(UINT32_MAX))
        let temp = CGPoint(x: sqrt(-2 * log(uniformRandom.x)), y: 2 * CGFloat.pi * uniformRandom.y)
        let normalRandom = CGPoint(x: temp.x * cos(temp.y), y: temp.x * sin(temp.y))
        return CGPoint(x: center.x + normalRandom.x * size.width / 2 * (Bool.random() ? 1 : -1),
                       y: center.y + normalRandom.y * size.height / 2 * (Bool.random() ? 1 : -1))
    }

    private func drawDotsAndBlobs() {
        // about 14 rows of dots would fit between center of dial and top of screen (11 rows drawn)
        let deltaAngle = asin(bounds.width / dotLinesOriginFromTop) / 5.9  // radians (~6 dots across top of screen)
        let startAngle = 270.0 * General.D2R - (CGFloat(Dots.numberOfRadials - 1) / 2.0) * deltaAngle
        let dotRadius = bounds.width * Dial.outerRadiusFactor / 32  // same as dial bead radius, below
        for radial in 0..<Dots.numberOfRadials {
            for row in 0..<Dots.numberOfRows {
                let dotDistanceFromOrigin = (dotLinesOriginFromTop - firstDotRowDistanceFromTop) + CGFloat(row) * dotRowSpacing  // distance from home button
                let dotAngle = startAngle + CGFloat(radial) * deltaAngle
                let dotCenter = CGPoint(x: bounds.midX + dotDistanceFromOrigin * cos(dotAngle) , y: dotLinesOriginFromTop + dotDistanceFromOrigin * sin(dotAngle))
                let dot = UIBezierPath(arcCenter: dotCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                Dots.color.setFill()
                dot.fill()
            }
        }
        for blob in blobs {
            Dots.blobColor.setFill()
            blob.fill()
        }
        
        // lighter gray backgound
        let wedge = UIBezierPath()
        wedge.move(to: dialCenter)
        wedge.addArc(withCenter: dialCenter, radius: bounds.width, startAngle: -45 * General.D2R, endAngle: -135 * General.D2R, clockwise: true)
        General.lighterBackgroundColor.setFill()
        wedge.fill()
    }

    private func drawDial() {
        let outerRadius = bounds.width * Dial.outerRadiusFactor
        let innerRadius = outerRadius * Dial.innerCircleFactor
        let innerRingWidth = innerRadius / 6
        let innerXWidth = innerRadius / 8
        let outerRingWidth = outerRadius / 8
        let outerWedgeWidth = outerRadius / 5
        
        let outerRing = UIBezierPath(arcCenter: dialCenter, radius: outerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        General.lighterBackgroundColor.setFill()
        outerRing.fill()
        Dial.outerRingColor.setStroke()
        outerRing.lineWidth = outerRingWidth
        outerRing.stroke()
        
        // lines, beads, and dots around outer ring
        let deltaAngle = 2 * CGFloat.pi / 12
        let lineInnerRadius = outerRadius - outerRingWidth / 2
        let lineOuterRadius = outerRadius + outerRingWidth / 2
        for i in 0..<12 {
            let angle = CGFloat(i) * deltaAngle
            
            let line = UIBezierPath()
            line.move(to: CGPoint(x: dialCenter.x + lineInnerRadius * cos(angle) , y: dialCenter.y + lineInnerRadius * sin(angle)))
            line.addLine(to: CGPoint(x: dialCenter.x + lineOuterRadius * cos(angle) , y: dialCenter.y + lineOuterRadius * sin(angle)))
            UIColor.black.setStroke()
            line.lineWidth = outerRingWidth / 6
            line.stroke()
            
            let beadRadius = outerRingWidth / 4
            let beadDistance = outerRadius + outerRingWidth / 2 - beadRadius
            let beadCenter = CGPoint(x: dialCenter.x + beadDistance * cos(angle) , y: dialCenter.y + beadDistance * sin(angle))
            let bead = UIBezierPath(arcCenter: beadCenter, radius: beadRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            Dial.clockBeadColor.setFill()
            bead.fill()
            
            let deltaDotAngle = deltaAngle / 4
            for j in 0..<4 {
                let dotAngle = angle + CGFloat(j) * deltaDotAngle
                
                let dotRadius = outerRingWidth / 5
                let dotDistance = outerRadius + outerRingWidth / 2 + 2 * dotRadius
                let dotCenter = CGPoint(x: dialCenter.x + dotDistance * cos(dotAngle) , y: dialCenter.y + dotDistance * sin(dotAngle))
                let dot = UIBezierPath(arcCenter: dotCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                UIColor.gray.setFill()
                dot.fill()
            }
        }

        let outerRightSideWedge = UIBezierPath(arcCenter: dialCenter, radius: outerRadius - outerWedgeWidth / 2,
                                               startAngle: -45 * General.D2R, endAngle: 45 * General.D2R, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerRightSideWedge.lineWidth = outerWedgeWidth
        outerRightSideWedge.stroke()
        
        let outerLeftSideWedge = UIBezierPath(arcCenter: dialCenter, radius: outerRadius - outerWedgeWidth / 2,
                                              startAngle: 135 * General.D2R, endAngle: -135 * General.D2R, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerLeftSideWedge.lineWidth = outerWedgeWidth
        outerLeftSideWedge.stroke()
        
        let upperBrightWedgeRadius = outerRadius - 1.25 * outerRingWidth
        let upperBrightWedge = UIBezierPath(arcCenter: dialCenter, radius: upperBrightWedgeRadius,
                                            startAngle: -128 * General.D2R, endAngle: -52 * General.D2R, clockwise: true)
        Dial.upperBrightWedgeColor.setStroke()
        upperBrightWedge.lineWidth = outerRingWidth
        upperBrightWedge.stroke()

        // inner circles and X
        let innerCircle = UIBezierPath(arcCenter: dialCenter, radius: innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        Dial.innerCenterColor.setFill()
        innerCircle.fill()
        
        let innerRing = UIBezierPath(arcCenter: dialCenter, radius: 1.2 * innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        Dial.innerRingColor.setStroke()
        innerRing.lineWidth = innerRingWidth
        innerRing.stroke()
        
        // inner X
        let angleOffset = 1.5 * deltaAngle
        let lineDistance = 0.67 * outerRadius
        for i in 0..<4 {
            let angle = angleOffset + 3 * CGFloat(i) * deltaAngle
            
            let line = UIBezierPath()
            line.move(to: dialCenter)
            line.addLine(to: CGPoint(x: dialCenter.x + lineDistance * cos(angle) , y: dialCenter.y + lineDistance * sin(angle)))
            Dial.largeXColor.setStroke()
            line.lineWidth = innerXWidth
            line.stroke()
        }
    }
    
    private func drawPulse() {
        let primaryRadius = 1.3 * bounds.height * Dial.centerFromTopFactor * CGFloat(pulsePercent) / 100
        let secondaryRadius = primaryRadius + max(12 * CGFloat(sin(pulsePercent / 4)), 0)  // one-sided sine wave
        let tertiaryRadius = primaryRadius - (pulsePercent > 20 ? 0.04 * (primaryRadius - 20) : 0)  // begins to separate after 20%
        
        let tertiaryPulse = UIBezierPath(arcCenter: dialCenter, radius: tertiaryRadius, startAngle: -135 * General.D2R, endAngle: -45 * General.D2R, clockwise: true)
        Pulse.tertiaryColor.setStroke()
        tertiaryPulse.lineWidth = 2
        tertiaryPulse.stroke()

        let secondaryPulse = UIBezierPath(arcCenter: dialCenter, radius: secondaryRadius, startAngle: -135 * General.D2R, endAngle: -45 * General.D2R, clockwise: true)
        Pulse.secondaryColor.setStroke()
        secondaryPulse.lineWidth = 8
        secondaryPulse.stroke()

        let primaryPulse = UIBezierPath(arcCenter: dialCenter, radius: primaryRadius, startAngle: -135 * General.D2R, endAngle: -45 * General.D2R, clockwise: true)
        Pulse.primaryColor.setStroke()
        primaryPulse.lineWidth = 8
        primaryPulse.stroke()
    }
    
    private func drawBottomSection() {
        
    }
}
