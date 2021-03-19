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
    static let digitalPeriod = 1.4  // seconds per change (numbers and bars)
    static let numberOfBars = 6
}

class ViewController: UIViewController {
    
    var pulsePercent = 0.0
    var levels = [Int](repeating: 10, count: Constants.numberOfBars)
    
    private var simulationTimer = Timer()
    private var simulationCount = 0

    @IBOutlet weak var trackerView: TrackerView!
    @IBOutlet weak var digitalView: DigitalView!
    @IBOutlet var numberLabels: [UILabel]!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        trackerView.backgroundColor = .black
        view.setNeedsLayout()
        view.layoutIfNeeded()
        digitalView.numberOfBars = Constants.numberOfBars
        digitalView.levels = [8, 9, 10, 9, 7, 6]
        startSimulation()
    }
    
    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: Constants.frameTime, target: self,
                                               selector: #selector(updateSimulation),
                                               userInfo: nil, repeats: true)
    }
    
    @objc func updateSimulation() {
        let deltaPercent = Constants.frameTime / Constants.pulsePeriod * 100
        pulsePercent = (pulsePercent + deltaPercent).truncatingRemainder(dividingBy: 100)
        if simulationCount == 0 {
            levels.indices.forEach { levels[$0] = Int.random(in: 6...10) }
            digitalView.levels = levels
        }
        simulationCount = (simulationCount + 1) % Int(Constants.digitalPeriod / Constants.frameTime)
        trackerView.pulsePercent = pulsePercent
    }
}
