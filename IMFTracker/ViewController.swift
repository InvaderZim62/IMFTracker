//
//  ViewController.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//

import UIKit

struct Constants {
    static let frameTime = 0.02  // seconds
    static let pulsePeriod = 1.4  // seconds per pulse
    static let barPeriod = 0.3  // seconds per change of target
    static let barRate = 8.0  // bars per sec movement towards target
    static let numberOfBars = 6
}

class ViewController: UIViewController {
    
    var pulsePercent = 0.0
    var barLevels = [Double](repeating: 10, count: Constants.numberOfBars)  // use Double to keep track of small changes for rate limiting
    var targetBarLevels = [Int](repeating: 10, count: Constants.numberOfBars)

    private var simulationTimer = Timer()
    private var barSimulationCount = 0

    @IBOutlet weak var pulseView: PulseView!
    @IBOutlet weak var digitalView: DigitalView!
    @IBOutlet var numberLabels: [UILabel]!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        digitalView.numberOfBars = Constants.numberOfBars
        startSimulation()
    }
    
    private func updateViewFromModel() {
        pulseView.pulsePercent = pulsePercent
        let intBarLevels = barLevels.map { Int($0) }
        digitalView.barLevels = intBarLevels
    }

    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: Constants.frameTime, target: self,
                                               selector: #selector(updateSimulation),
                                               userInfo: nil, repeats: true)
    }
    
    @objc func updateSimulation() {
        let deltaPercent = Constants.frameTime / Constants.pulsePeriod * 100
        pulsePercent = (pulsePercent + deltaPercent).truncatingRemainder(dividingBy: 100)
        
        if barSimulationCount == 0 {
            // update random target positions for bars at barPeriod rate
            targetBarLevels.indices.forEach { targetBarLevels[$0] = Int.random(in: 6...10) }
        }
        barSimulationCount = (barSimulationCount + 1) % Int(Constants.barPeriod / Constants.frameTime)
        moveLevelsToTargets()
        updateViewFromModel()
    }
    
    private func moveLevelsToTargets() {
        for (index, level) in barLevels.enumerated() {
            var deltaLevel = Double(targetBarLevels[index]) - level
            if abs(deltaLevel) > Constants.barRate * Constants.frameTime {
                // apply rate limit to levels
                deltaLevel = Constants.barRate * Constants.frameTime * (deltaLevel > 0 ? 1 : -1)
            }
            barLevels[index] += deltaLevel
        }
    }
}
