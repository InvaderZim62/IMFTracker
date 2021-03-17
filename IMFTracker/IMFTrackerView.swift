//
//  IMFTrackerView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//

import UIKit

struct zConst {
    static let D2R = CGFloat.pi / 180
    static let dialTopDistanceFactor: CGFloat = 0.7  // percent bounds height from top
    static let dialOuterRadiusFactor: CGFloat = 0.21  // percent bounds width
    static let dialInnerCircleFactor: CGFloat = 0.3  // percent outer radius
    static let dialInnerCenterColor = #colorLiteral(red: 0.1362066269, green: 0.2441202402, blue: 0.07585870475, alpha: 1)
    static let dialInnerRingColor = #colorLiteral(red: 0.3280324042, green: 0.336155057, blue: 0.07936634868, alpha: 1)
    static let dialOuterRingColor = #colorLiteral(red: 0.007069805637, green: 0.3669355512, blue: 0.9889140725, alpha: 1)
    static let upperBrightWedgeColor = #colorLiteral(red: 0.9179044366, green: 0.9080289602, blue: 0.5714150071, alpha: 1)
    static let innerXColor = #colorLiteral(red: 0.7377259135, green: 0.7315381169, blue: 0.4689100981, alpha: 1)
    static let dialOuterSideWedgeColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
    static let dialClockBeadColor = #colorLiteral(red: 0.01647673175, green: 0.9682727456, blue: 0.4770763516, alpha: 1)
}

class IMFTrackerView: UIView {

    override func draw(_ rect: CGRect) {
        drawDial()
    }
    
    private func drawDial() {
        let center = CGPoint(x: bounds.midX, y: bounds.height * zConst.dialTopDistanceFactor)
        let outerRadius = bounds.width * zConst.dialOuterRadiusFactor
        let innerRadius = outerRadius * zConst.dialInnerCircleFactor
        let innerRingWidth = innerRadius / 6
        let innerXWidth = innerRadius / 8
        let outerRingWidth = outerRadius / 8
        let outerWedgeWidth = outerRadius / 5

        let innerCircle = UIBezierPath(arcCenter: center, radius: innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        zConst.dialInnerCenterColor.setFill()
        innerCircle.fill()
        
        let innerRing = UIBezierPath(arcCenter: center, radius: 1.2 * innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        zConst.dialInnerRingColor.setStroke()
        innerRing.lineWidth = innerRingWidth
        innerRing.stroke()
        
        let outerRing = UIBezierPath(arcCenter: center, radius: outerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        zConst.dialOuterRingColor.setStroke()
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
            line.lineWidth = outerRingWidth / 8
            line.stroke()
            
            let beadRadius = outerRingWidth / 4
            let beadDistance = outerRadius + outerRingWidth / 2 - beadRadius
            let beadCenter = CGPoint(x: center.x + beadDistance * cos(angle) , y: center.y + beadDistance * sin(angle))
            let bead = UIBezierPath(arcCenter: beadCenter, radius: beadRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            zConst.dialClockBeadColor.setFill()
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
        
        // inner X
        let angleOffset = 1.5 * deltaAngle
        let lineDistance = 0.67 * outerRadius
        for i in 0..<4 {
            let angle = angleOffset + 3 * CGFloat(i) * deltaAngle
            
            let line = UIBezierPath()
            line.move(to: center)
            line.addLine(to: CGPoint(x: center.x + lineDistance * cos(angle) , y: center.y + lineDistance * sin(angle)))
            zConst.innerXColor.setStroke()
            line.lineWidth = innerXWidth
            line.stroke()
        }

        let outerRightSideWedge = UIBezierPath(arcCenter: center, radius: outerRadius - outerWedgeWidth / 2,
                                               startAngle: -45 * zConst.D2R, endAngle: 45 * zConst.D2R, clockwise: true)
        zConst.dialOuterSideWedgeColor.setStroke()
        outerRightSideWedge.lineWidth = outerWedgeWidth
        outerRightSideWedge.stroke()
        
        let outerLeftSideWedge = UIBezierPath(arcCenter: center, radius: outerRadius - outerWedgeWidth / 2,
                                              startAngle: 135 * zConst.D2R, endAngle: -135 * zConst.D2R, clockwise: true)
        zConst.dialOuterSideWedgeColor.setStroke()
        outerLeftSideWedge.lineWidth = outerWedgeWidth
        outerLeftSideWedge.stroke()
        
        let upperBrightWedgeRadius = outerRadius - 1.25 * outerRingWidth
        let upperBrightWedge = UIBezierPath(arcCenter: center, radius: upperBrightWedgeRadius,
                                            startAngle: -128 * zConst.D2R, endAngle: -52 * zConst.D2R, clockwise: true)
        zConst.upperBrightWedgeColor.setStroke()
        upperBrightWedge.lineWidth = outerRingWidth
        upperBrightWedge.stroke()
    }
}
