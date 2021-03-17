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

    @IBOutlet weak var imfTrackerView: IMFTrackerView!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        imfTrackerView.pulsePercent = pulsePercent
    }
}
