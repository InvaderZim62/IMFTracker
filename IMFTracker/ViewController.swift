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
    static let detectionRange: CGFloat = 30  // points: proximity of pulse to target to illuminate target - needs a little lead time to look good
    static let closeRange: CGFloat = 10  // points
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
    var targetClose = false
    var targetSimulating = false
    var targetAgePercent = 0.0

    private var globalData = GlobalData.sharedInstance
    private var simulationTimer = Timer()
    private var locationManager = CLLocationManager()
    private var barSimulationCount = 0
    
    @IBOutlet weak var dotsDialView: DotsDialView!
    @IBOutlet weak var pulseTargetView: PulseTargetView!
    @IBOutlet weak var barsView: BarsView!
    @IBOutlet var numberLabels: [UILabel]!
    
    override var prefersStatusBarHidden: Bool {  // also added "Status bar is initially hidden" = YES to Info.plist to hide during launch
        return true
    }
    
    // MARK: - Start of code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        // To use location services, add the following key-value pair to Info.plist...
        //   Key: Privacy - Location When In Use Usage Description
        //   Value: "This application requires location services to work"
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()  // start calls to locationManager(didUpdateLocations:)
            locationManager.startUpdatingHeading()   // start calls to locationManager(didUpdateLHeading:)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let firstDotRowDistanceFromTop = dotsDialView.bounds.height * Dots.firstRowDistanceFromTopFactor
        globalData.dotRowSpacing = (firstDotRowDistanceFromTop - 8) / CGFloat(Dots.numberOfRows - 1)  // top row 8 points from top of screen
        globalData.dialCenter = CGPoint(x: dotsDialView.bounds.midX, y: dotsDialView.bounds.height * Dial.centerFromTopFactor)
        globalData.dialOuterRadius = dotsDialView.bounds.width * Dial.outerRadiusFactor
        barsView.numberOfBars = Constants.numberOfBars
        numbersCenter.indices.forEach { numbersCenter[$0] = Double.random(in: 100..<100000) }
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
            (targetDetected, targetClose, targetRange, targetHeading) = trackerSensorModel()
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
            numbers.indices.forEach { numbers[$0] = numbersCenter[$0] + Double.random(in: -100..<1000) }  // random numbers, except next line
            numbers[3] = trackerHeading.degsDouble // put tracker heading in middle of right column
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
        numberLabels[4].text = String(format: "%.2f", numbers[3])  // tracker heading
        pulseTargetView.targetSimulating = targetSimulating
        pulseTargetView.targetRange = targetRange  // feet
        pulseTargetView.targetHeading = targetHeading  // radians
        pulseTargetView.targetAgePercent = targetAgePercent
        dotsDialView.targetClose = targetClose
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
    private func trackerSensorModel() -> (Bool, Bool, Double, Double) {
        let deltaPosition = targetPosition - trackerPosition
        let deltaNorth = deltaPosition.latitude * Conversion.degToFeet  // feet
        let deltaEast = deltaPosition.longitude * cos(trackerPosition.latitude.radsDouble) * Conversion.degToFeet
        let targetRange = sqrt(pow(deltaNorth, 2) + pow(deltaEast, 2))
        let bearingToTarget = atan2(deltaEast, deltaNorth)  // radians
        let targetHeading = (bearingToTarget - trackerHeading).wrapPi
        // test fixed target
//        targetRange = 30
//        targetHeading = -5.radsDouble
        let pointsPerFoot = globalData.dotRowSpacing / Target.feetPerRowOfDots
        let targetDetected = abs(CGFloat(targetRange) * pointsPerFoot - CGFloat(pulseTargetView.radiusFromPercent(pulsePercent))) < Constants.detectionRange && abs(targetHeading) < 45.radsDouble
        let targetClose = CGFloat(targetRange) * pointsPerFoot < globalData.dialOuterRadius
        return (targetDetected, targetClose, targetRange, targetHeading)  // bool, feet, radians
    }
    
    @objc func screenTapped(tap: UITapGestureRecognizer) {
        // place target at location of screen tap
        let tapPoint = tap.location(in: pulseTargetView)
        let targetX = tapPoint.x - globalData.dialCenter.x  // cartesian coordinates from dial center
        let targetY = -tapPoint.y + globalData.dialCenter.y
        let pointsPerFoot = globalData.dotRowSpacing / Target.feetPerRowOfDots
        let targetRange = Double(sqrt(pow(targetX, 2) + pow(targetY, 2)) / pointsPerFoot)  // feet
        let targetHeading = atan2(targetX, targetY)  // radians (heading relative to tracker centerline)
        let targetBearing = Double(targetHeading) + trackerHeading  // radians (bearing relative to North)
        let deltaNorth = targetRange * cos(targetBearing)
        let deltaEast = targetRange * sin(targetBearing)
        let deltaLatitude = deltaNorth / Conversion.degToFeet
        let deltaLongitude = deltaEast / cos(trackerPosition.latitude.radsDouble) / Conversion.degToFeet
        let targetLatitude = deltaLatitude + trackerPosition.latitude
        let targetLongitude = deltaLongitude + trackerPosition.longitude
        targetPosition = CLLocationCoordinate2D(latitude: targetLatitude, longitude: targetLongitude)
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location {
            if !once {
                // create fixed target position at a random delta from user position
                let deltaPosition = CLLocationCoordinate2D(latitude: 0.00008, longitude: 0.0)  // fix delta for now (0.00001 deg ~ 5 ft)
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
