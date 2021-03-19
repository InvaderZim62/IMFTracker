//
//  DigitalView.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/18/21.
//

import UIKit

struct Bars {
    static let distanceFromCenterFactor: CGFloat = 0.05  // percent of bounds.width
    static let widthFactor: CGFloat = 0.14  // percent of bounds.width
    static let maxLevel = 10
}

class DigitalView: UIView {
    
    var numberOfBars = 0 { didSet { createBars() } }  // numberOfBars must be set before levels
    var levels = [Int]() { didSet { setBarViewLevels() } }
    
    private var barViews = [BarView]()
    
    private func createBars() {
        let barWidth = Bars.widthFactor * bounds.width
        let barHeight = bounds.height / 11  // 11 = 2 space + 1 bar + 2 space + 1 bar + 2 space + 1 bar + 2 space
        let distanceFromCenter = Bars.distanceFromCenterFactor * bounds.width
        for i in 0..<numberOfBars {
            var leftEdge: CGFloat = 0
            var topEdge: CGFloat = 0
            var isRightAligned = true
            if i % 2 == 0 {
                // left-side bar
                leftEdge = bounds.midX - distanceFromCenter - barWidth
                topEdge = CGFloat(2 + 3 * i / 2) * barHeight
                isRightAligned = true
            } else {
                // right-side bar
                leftEdge = bounds.midX + distanceFromCenter
                topEdge = CGFloat(2 + 3 * (i - 1) / 2) * barHeight
                isRightAligned = false
            }
            let frame = CGRect(x: leftEdge, y: topEdge, width: barWidth, height: barHeight)
            let barView = BarView(frame: frame, maxLevel: Bars.maxLevel, isRightAligned: isRightAligned)
            addSubview(barView)
            barViews.append(barView)
        }
    }
    
    private func setBarViewLevels() {
        precondition(levels.count == barViews.count, "(DigitalView.setBarViewLevel) Number of levels must match number of bars")
        barViews.indices.forEach { barViews[$0].level = levels[$0] }
    }
}
