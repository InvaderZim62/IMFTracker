//
//  BarView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/18/21.
//

import UIKit

class BarView: UIView {
    
    var maxLevel = 10
    var isRightAligned = true
    var level = 7 { didSet { setNeedsDisplay() } }
    
    init(frame: CGRect, maxLevel: Int, isRightAligned: Bool) {
        super.init(frame: frame)
        self.maxLevel = maxLevel
        self.isRightAligned = isRightAligned
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        // add solid bar
        let barLeft = isRightAligned ? CGFloat(maxLevel - level) / CGFloat(maxLevel) * bounds.width : 0
        let barWidth = CGFloat(level) / CGFloat(maxLevel) * bounds.width
        let bar = UIBezierPath(rect: CGRect(x: barLeft, y: 0, width: barWidth, height: bounds.height))
        Dial.outerRingColor.setFill()
        bar.fill()
        // add vertical lines to separate bar into segments
        for i in 0..<maxLevel {
            let segmentWidths = bounds.width / CGFloat(maxLevel)
            let line = UIBezierPath()
            line.move(to: CGPoint(x: segmentWidths * CGFloat(i), y: 0))
            line.addLine(to: CGPoint(x: segmentWidths * CGFloat(i), y: bounds.height))
            UIColor.black.setStroke()
            line.lineWidth = 1
            line.stroke()
        }
    }
}
