//
//  ViewController.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//

import UIKit

struct Constants {
    static let frameTime = 0.02
    static let pulseFrequency = 0.7  // pulses per second
}

class ViewController: UIViewController {
    
    var simulationTimer = Timer()
    var pulsePercent = 0.0

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
        digitalView.numberOfBars = 6
        digitalView.levels = [8, 9, 10, 9, 7, 6]
        startSimulation()
    }
    
    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: Constants.frameTime, target: self,
                                               selector: #selector(updateSimulation),
                                               userInfo: nil, repeats: true)
    }
    
    @objc func updateSimulation() {
        let deltaPercent = Constants.pulseFrequency * Constants.frameTime * 100
        pulsePercent = (pulsePercent + deltaPercent).truncatingRemainder(dividingBy: 100)
        trackerView.pulsePercent = pulsePercent
    }
}
