//
//  ViewController.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/16/21.
//

import UIKit
import MapKit  // for heading

struct Constants {
    static let frameTime = 0.02  // seconds
    static let pulsePeriod = 1.4  // seconds per pulse
    static let barPeriod = 0.2  // seconds per change of target
    static let barRate = 6.0  // bars per sec movement towards target
    static let numberOfBars = 6
    static let detectionThreshold: CGFloat = 30//5  // proximity of pulse to target to illuminate target (points)
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var pulsePercent = 0.0
    var barLevels = [Double](repeating: 10, count: Constants.numberOfBars)  // use Double to keep track of small changes for rate limiting
    var targetBarLevels = [Int](repeating: 10, count: Constants.numberOfBars)
    var numbers = [Double](repeating: 10000, count: Constants.numberOfBars)
    var numbersCenter = [Double](repeating: 10000, count: Constants.numberOfBars)  // numbers randomly change about this center value
    
    var once = false
    var targetPosition = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var trackerPosition = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var trackerHeading = 0.0  // radians
    
    private var simulationTimer = Timer()
    private var locationManager = CLLocationManager()
    private var barSimulationCount = 0
    
    @IBOutlet weak var pulseView: PulseView!
    @IBOutlet weak var digitalView: DigitalView!
    @IBOutlet var numberLabels: [UILabel]!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    // MARK: - Start of code
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        digitalView.numberOfBars = Constants.numberOfBars
        numbersCenter.indices.forEach { numbersCenter[$0] = Double.random(in: 100..<100000) }
        // To use location services, add the following key-value pair to Info.plist...
        //   Key: Privacy - Location When In Use Usage Description
        //   Value: "This application requires location services to work"
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()  // start calls to locationManager(didUpdateLocations:)
            locationManager.startUpdatingHeading()   // start calls to locationManager(didUpdateLHeading:)
        }
        startSimulation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
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
            numbers.indices.forEach { numbers[$0] = numbersCenter[$0] + Double.random(in: -100..<1000) }
        }
        barSimulationCount = (barSimulationCount + 1) % Int(Constants.barPeriod / Constants.frameTime)
        moveLevelsToTargets()
        updateViewFromModel()
    }

    private func updateViewFromModel() {
        pulseView.pulsePercent = pulsePercent
        let intBarLevels = barLevels.map { Int($0) }
        digitalView.barLevels = intBarLevels
        numberLabels.indices.forEach { numberLabels[$0].text = String(format: "%.1f", numbers[$0]) }
        let (targetRange, targetHeading, targetDetected) = trackerSensorModel()
        pulseView.targetRange = targetRange  // feet
        pulseView.targetHeading = targetHeading  // radians
        pulseView.targetDetected = targetDetected
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
    
    private func trackerSensorModel() -> (Double, Double, Bool) {
        let deltaPosition = targetPosition - trackerPosition
        let deltaNorth = deltaPosition.latitude * Conversion.degToFeet  // feet
        let deltaEast = deltaPosition.longitude * cos(trackerPosition.latitude.radsDouble) * Conversion.degToFeet
        let targetRange = sqrt(pow(deltaNorth, 2) + pow(deltaEast, 2))
        let bearingToTarget = atan2(deltaEast, deltaNorth)  // radians
        let targetHeading = (bearingToTarget - trackerHeading).wrapPi
        let targetDetected = abs(CGFloat(targetRange) * Pulse.pointsPerFoot - CGFloat(pulseView.radiusFromPercent(pulsePercent))) < Constants.detectionThreshold && abs(targetHeading) < 45.radsDouble
//        print("target range: \(targetRange), target heading: \(targetHeading.degsDouble), tracker heading: \(trackerHeading.degsDouble)")
        return (targetRange, targetHeading, targetDetected)  // feet, radians, bool
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location {
            if !once {
                // create fixed target position at a random delta from user position
                let deltaPosition = CLLocationCoordinate2D(latitude: 0.00006, longitude: 0.00006)  // pws: fix delta for now (0.00001 deg ~ 5 ft)
                targetPosition = location.coordinate + deltaPosition
                once = true
            }
            trackerPosition = location.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let heading = manager.heading?.magneticHeading {
            trackerHeading = heading.radsDouble
        }
    }
}
