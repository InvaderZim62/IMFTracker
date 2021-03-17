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
    static let originFromTopFactor: CGFloat = 1.1  // percent bounds height (origin of dot lines is below the screen)
    static let startRowFromTopFactor: CGFloat = 0.53  // percent bounds height
    static let color = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
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
    static let largeXColor = #colorLiteral(red: 0.7377259135, green: 0.7315381169, blue: 0.4689100981, alpha: 1)
}

class IMFTrackerView: UIView {

    override func draw(_ rect: CGRect) {
        drawField()
        drawDial()
    }
    
    private func drawField() {
        // about 14 rows of dots would fit between center of dial and top of screen (11 rows drawn)
        let rowSpacing = bounds.height * Dial.centerFromTopFactor / CGFloat(Dots.numberOfRows + 3)
        let startRowFromTop = bounds.height * Dots.startRowFromTopFactor
        let centerFromTop = bounds.height * Dots.originFromTopFactor
        let deltaAngle = asin(bounds.width / centerFromTop) / 5.9  // radians (~6 dots across top of screen)
        let startAngle = 270.0 * General.D2R - (CGFloat(Dots.numberOfRadials - 1) / 2.0) * deltaAngle
        let dotRadius = bounds.width * Dial.outerRadiusFactor / 32  // same as dial bead radius, below
        for col in 0..<Dots.numberOfRadials {
            for row in 0..<Dots.numberOfRows {
                let dotDistance = (centerFromTop - startRowFromTop) + CGFloat(row) * rowSpacing
                let dotAngle = startAngle + CGFloat(col) * deltaAngle
                let dotCenter = CGPoint(x: bounds.midX + dotDistance * cos(dotAngle) , y: centerFromTop + dotDistance * sin(dotAngle))
                let dot = UIBezierPath(arcCenter: dotCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                Dots.color.setFill()
                dot.fill()
            }
        }
        // lighter gray backgound
        let dialCenter = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)
        let wedge = UIBezierPath()
        wedge.move(to: dialCenter)
        wedge.addArc(withCenter: dialCenter, radius: bounds.width, startAngle: -45 * General.D2R, endAngle: -135 * General.D2R, clockwise: true)
        General.lighterBackgroundColor.setFill()
        wedge.fill()
    }
    
    private func drawDial() {
        let center = CGPoint(x: bounds.midX, y: bounds.height * Dial.centerFromTopFactor)
        let outerRadius = bounds.width * Dial.outerRadiusFactor
        let innerRadius = outerRadius * Dial.innerCircleFactor
        let innerRingWidth = innerRadius / 6
        let innerXWidth = innerRadius / 8
        let outerRingWidth = outerRadius / 8
        let outerWedgeWidth = outerRadius / 5
        
        let outerRing = UIBezierPath(arcCenter: center, radius: outerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
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
            line.move(to: CGPoint(x: center.x + lineInnerRadius * cos(angle) , y: center.y + lineInnerRadius * sin(angle)))
            line.addLine(to: CGPoint(x: center.x + lineOuterRadius * cos(angle) , y: center.y + lineOuterRadius * sin(angle)))
            UIColor.black.setStroke()
            line.lineWidth = outerRingWidth / 6
            line.stroke()
            
            let beadRadius = outerRingWidth / 4
            let beadDistance = outerRadius + outerRingWidth / 2 - beadRadius
            let beadCenter = CGPoint(x: center.x + beadDistance * cos(angle) , y: center.y + beadDistance * sin(angle))
            let bead = UIBezierPath(arcCenter: beadCenter, radius: beadRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            Dial.clockBeadColor.setFill()
            bead.fill()
            
            let deltaDotAngle = deltaAngle / 4
            for j in 0..<4 {
                let dotAngle = angle + CGFloat(j) * deltaDotAngle
                
                let dotRadius = outerRingWidth / 5
                let dotDistance = outerRadius + outerRingWidth / 2 + 2 * dotRadius
                let dotCenter = CGPoint(x: center.x + dotDistance * cos(dotAngle) , y: center.y + dotDistance * sin(dotAngle))
                let dot = UIBezierPath(arcCenter: dotCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                UIColor.gray.setFill()
                dot.fill()
            }
        }

        let outerRightSideWedge = UIBezierPath(arcCenter: center, radius: outerRadius - outerWedgeWidth / 2,
                                               startAngle: -45 * General.D2R, endAngle: 45 * General.D2R, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerRightSideWedge.lineWidth = outerWedgeWidth
        outerRightSideWedge.stroke()
        
        let outerLeftSideWedge = UIBezierPath(arcCenter: center, radius: outerRadius - outerWedgeWidth / 2,
                                              startAngle: 135 * General.D2R, endAngle: -135 * General.D2R, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerLeftSideWedge.lineWidth = outerWedgeWidth
        outerLeftSideWedge.stroke()
        
        let upperBrightWedgeRadius = outerRadius - 1.25 * outerRingWidth
        let upperBrightWedge = UIBezierPath(arcCenter: center, radius: upperBrightWedgeRadius,
                                            startAngle: -128 * General.D2R, endAngle: -52 * General.D2R, clockwise: true)
        Dial.upperBrightWedgeColor.setStroke()
        upperBrightWedge.lineWidth = outerRingWidth
        upperBrightWedge.stroke()

        // inner circles and X
        let innerCircle = UIBezierPath(arcCenter: center, radius: innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        Dial.innerCenterColor.setFill()
        innerCircle.fill()
        
        let innerRing = UIBezierPath(arcCenter: center, radius: 1.2 * innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        Dial.innerRingColor.setStroke()
        innerRing.lineWidth = innerRingWidth
        innerRing.stroke()
        
        // inner X
        let angleOffset = 1.5 * deltaAngle
        let lineDistance = 0.67 * outerRadius
        for i in 0..<4 {
            let angle = angleOffset + 3 * CGFloat(i) * deltaAngle
            
            let line = UIBezierPath()
            line.move(to: center)
            line.addLine(to: CGPoint(x: center.x + lineDistance * cos(angle) , y: center.y + lineDistance * sin(angle)))
            Dial.largeXColor.setStroke()
            line.lineWidth = innerXWidth
            line.stroke()
        }
    }
}
