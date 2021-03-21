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
    static let barPeriod = 0.2  // seconds per change of bar target
    static let barVelocity = 6.0  // bars per sec movement towards bar target
    static let targetPeriod = 1.0  // seconds for target simulation to complete
    static let numberOfBars = 6  // number of blue bars along bottom of screen
    static let detectionRange: CGFloat = 30  // proximity of pulse to target to illuminate target (points) - needs a little lead time to look good
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
    
    var targetRange = 0.0  // feet
    var targetHeading = 0.0  // radians
    var targetDetected = false
    var targetSimulating = false
    var targetAgePercent = 0.0

    private var simulationTimer = Timer()
    private var locationManager = CLLocationManager()
    private var barSimulationCount = 0
    
    @IBOutlet weak var pulseTargetView: PulseTargetView!
    @IBOutlet weak var barsView: BarsView!
    @IBOutlet var numberLabels: [UILabel]!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    // MARK: - Start of code
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        barsView.numberOfBars = Constants.numberOfBars
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
        // pulse wave
        let deltaPercent = Constants.frameTime / Constants.pulsePeriod * 100
        pulsePercent = (pulsePercent + deltaPercent).truncatingRemainder(dividingBy: 100)
        
        if !targetSimulating {
            (targetDetected, targetRange, targetHeading) = trackerSensorModel()
        }
        
        // target
        if targetDetected || targetSimulating {
            targetSimulating = true  // latch, since targetDetected triggers momentarily as pulse sweeps target
            targetAgePercent += Constants.frameTime / Constants.targetPeriod * 100
            if targetAgePercent >= 100 {
                targetSimulating = false  // unlatch when target is done simulating
                targetAgePercent = 0
            }
        }
        
        // equalizer bars along the bottom
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
        pulseTargetView.pulsePercent = pulsePercent
        let intBarLevels = barLevels.map { Int($0) }
        barsView.barLevels = intBarLevels
        numberLabels.indices.forEach { numberLabels[$0].text = String(format: "%.1f", numbers[$0]) }
        pulseTargetView.targetSimulating = targetSimulating
        pulseTargetView.targetRange = targetRange  // feet
        pulseTargetView.targetHeading = targetHeading  // radians
        pulseTargetView.targetAgePercent = targetAgePercent
    }

    private func moveLevelsToTargets() {
        for (index, level) in barLevels.enumerated() {
            var deltaLevel = Double(targetBarLevels[index]) - level
            if abs(deltaLevel) > Constants.barVelocity * Constants.frameTime {
                // apply rate limit to levels
                deltaLevel = Constants.barVelocity * Constants.frameTime * (deltaLevel > 0 ? 1 : -1)
            }
            barLevels[index] += deltaLevel
        }
    }
    
    // compute target properties based on data from updateSimulation (pulsePercent) and locationManager (targetPosition, trackerPosition, trackerHeading)
    private func trackerSensorModel() -> (Bool, Double, Double) {
        let deltaPosition = targetPosition - trackerPosition
        let deltaNorth = deltaPosition.latitude * Conversion.degToFeet  // feet
        let deltaEast = deltaPosition.longitude * cos(trackerPosition.latitude.radsDouble) * Conversion.degToFeet
        let targetRange = sqrt(pow(deltaNorth, 2) + pow(deltaEast, 2))
        let bearingToTarget = atan2(deltaEast, deltaNorth)  // radians
        let targetHeading = (bearingToTarget - trackerHeading).wrapPi
        // test fixed target
//        targetRange = 50
//        targetHeading = -5.radsDouble
        let targetDetected = abs(CGFloat(targetRange) * Target.pointsPerFoot - CGFloat(pulseTargetView.radiusFromPercent(pulsePercent))) < Constants.detectionRange && abs(targetHeading) < 45.radsDouble
        return (targetDetected, targetRange, targetHeading)  // bool, feet, radians
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location {
            if !once {
                // create fixed target position at a random delta from user position
                let deltaPosition = CLLocationCoordinate2D(latitude: 0.0, longitude: -0.00006)  // pws: fix delta for now (0.00001 deg ~ 5 ft)
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
