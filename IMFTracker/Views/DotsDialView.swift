//
//  DotsDialView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//
//  Fixed view - only called once.
//

import UIKit

struct Dots {
    static let deltaAngle = 5.0  // angle between radial lines (degrees)  Note: 5.2 looks like the movie display
    static let numberOfRows = 11
    static let originFromTopFactor: CGFloat = 1.1  // percent bounds height (origin of dot lines is below the screen - near home button)
    static let firstRowDistanceFromTopFactor: CGFloat = 0.53  // percent bounds height
    static let lighterBackgroundColor = #colorLiteral(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
    static let dotColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    static let blobColor = #colorLiteral(red: 0.0003377870016, green: 0.5450543761, blue: 0.949290216, alpha: 1)
}

struct Dial {
    static let centerFromTopFactor: CGFloat = 0.7  // percent bounds height
    static let outerRadiusFactor: CGFloat = 0.21  // percent bounds width
    static let innerCircleFactor: CGFloat = 0.3  // percent outer radius
    static let outerRingColor = #colorLiteral(red: 0.00627097534, green: 0.4420556426, blue: 0.6384952664, alpha: 1)
    static let clockBeadColor = #colorLiteral(red: 0.01647673175, green: 0.9682727456, blue: 0.4770763516, alpha: 1)
    static let upperBrightWedgeColor = #colorLiteral(red: 1, green: 0.9036917273, blue: 0.4067936073, alpha: 1)
    static let outerSideWedgeColor = #colorLiteral(red: 0.1338707209, green: 0.2045380473, blue: 0.2005188167, alpha: 1)
    static let innerRingColor = #colorLiteral(red: 0.3280324042, green: 0.336155057, blue: 0.07936634868, alpha: 1)
    static let innerCenterColor = #colorLiteral(red: 0.1362066269, green: 0.2441202402, blue: 0.07585870475, alpha: 1)
    static let largeXColor = #colorLiteral(red: 0.6209777594, green: 0.6121075153, blue: 0.4009537101, alpha: 1)
}

class DotsDialView: UIView {
    
    var targetClose = false { didSet { setNeedsDisplay() } }

    private var globalData = GlobalData.sharedInstance

    private lazy var firstDotRowDistanceFromTop = bounds.height * Dots.firstRowDistanceFromTopFactor
    private lazy var dotRadius = bounds.width * Dial.outerRadiusFactor / 32  // same size as dial bead radius, below
    private lazy var dotLinesOriginFromTop = bounds.height * Dots.originFromTopFactor
    private lazy var blobs = makeBlobs()

    override func draw(_ rect: CGRect) {
        drawDotsAndBlobs()
        drawDial()
    }

    private func drawDotsAndBlobs() {
        let dialCenter = globalData.dialCenter
        let numberOfRadials = Int(40.rads / Dots.deltaAngle.rads) + 3  // 40 degrees = +/-20 degrees from center (fits in display)
        let startAngle = 270.rads - (CGFloat(numberOfRadials - 1) / 2.0) * Dots.deltaAngle.rads  // zero to right, positive clockwise
        // draw dots
        for row in 0..<Dots.numberOfRows {
            let dotDistanceFromOrigin = (dotLinesOriginFromTop - firstDotRowDistanceFromTop) + CGFloat(row) * globalData.dotRowSpacing  // origin ~home button
            for radial in 0..<numberOfRadials {
                let dotAngle = startAngle + CGFloat(radial) * Dots.deltaAngle.rads  // zero to right, positive clockwise
                let dotCenter = CGPoint(x: bounds.midX + dotDistanceFromOrigin * cos(dotAngle) , y: dotLinesOriginFromTop + dotDistanceFromOrigin * sin(dotAngle))
                
                let dot = UIBezierPath(arcCenter: dotCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                Dots.dotColor.setFill()
                dot.fill()
            }
        }
        // draw blobs
        for blob in blobs {
            Dots.blobColor.setFill()
            blob.fill()
        }
        
        // lighter gray background
        let wedge = UIBezierPath()
        wedge.move(to: dialCenter)
        wedge.addArc(withCenter: dialCenter, radius: bounds.width, startAngle: -45.rads, endAngle: -135.rads, clockwise: true)
        Dots.lighterBackgroundColor.setFill()
        wedge.fill()
    }
    
    private func drawDial() {
        let dialCenter = globalData.dialCenter
        let outerRadius = globalData.dialOuterRadius
        let innerRadius = outerRadius * Dial.innerCircleFactor
        let innerRingWidth = innerRadius / 6
        let innerXWidth = innerRadius / 8
        let outerRingWidth = outerRadius / 8
        let outerWedgeWidth = outerRadius / 5
        
        let outerRing = UIBezierPath(arcCenter: dialCenter, radius: outerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        Dots.lighterBackgroundColor.setFill()
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
                                               startAngle: -45.rads, endAngle: 45.rads, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerRightSideWedge.lineWidth = outerWedgeWidth
        outerRightSideWedge.stroke()
        
        let outerLeftSideWedge = UIBezierPath(arcCenter: dialCenter, radius: outerRadius - outerWedgeWidth / 2,
                                              startAngle: 135.rads, endAngle: -135.rads, clockwise: true)
        Dial.outerSideWedgeColor.setStroke()
        outerLeftSideWedge.lineWidth = outerWedgeWidth
        outerLeftSideWedge.stroke()
        
        let upperBrightWedgeRadius = outerRadius - 1.25 * outerRingWidth
        let upperBrightWedge = UIBezierPath(arcCenter: dialCenter, radius: upperBrightWedgeRadius,
                                            startAngle: -128.rads, endAngle: -52.rads, clockwise: true)
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
            targetClose ? UIColor.red.setStroke() : Dial.largeXColor.setStroke()
            line.lineWidth = innerXWidth
            line.stroke()
        }
    }
    
    private func makeBlobs() -> [UIBezierPath] {
        var blobs = [UIBezierPath]()
        for row in 0..<Dots.numberOfRows {
            if row < Dots.numberOfRows - 1 {
                let blobCenter = CGPoint(x: bounds.midX, y: firstDotRowDistanceFromTop - (CGFloat(row) + 0.3) * globalData.dotRowSpacing)
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
}
