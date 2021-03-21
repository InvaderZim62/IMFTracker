//
//  Utilities.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/17/21.
//

import UIKit
import MapKit

struct Conversion {
    static let nmiToFeet = 6076.12
    static let degToFeet = 60.0 * nmiToFeet  // approx. 1 deg latitude = 60 nmi
}

class Interpolate<T: Comparable & FloatingPoint> {
    func getIndexAndRatio(value: T, array: [T]) -> (index: Int, ratio: T) {
        var index = 0
        for i in 0..<array.count - 1 {
            if array[i] < value {
                index = i
            } else {
                break
            }
        }
        let ratio = (value - array[index]) / (array[index + 1] - array[index])
        return (index, ratio)
    }

    func getResult(from array: [T], using indexAndRatio: (index: Int, ratio: T)) -> T {
        return array[indexAndRatio.index] + indexAndRatio.ratio * (array[indexAndRatio.index + 1] - array[indexAndRatio.index])
    }
}

extension Double {
    var rads: CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0
    }
    
    var degs: CGFloat {
        return CGFloat(self) * 180.0 / CGFloat.pi
    }

    var radsDouble: Double {
        return self * Double.pi / 180.0
    }

    var degsDouble: Double {
        return self * 180.0 / Double.pi
    }
    
    // converts angle from +/-360 to +/-180
    var wrap180: Double {
        var wrappedAngle = self
        if self > 180.0 {
            wrappedAngle -= 360.0
        } else if self < -180.0 {
            wrappedAngle += 360.0
        }
        return wrappedAngle
    }
    
    // converts angle from +/-2 pi to +/-pi
    var wrapPi: Double {
        var wrappedAngle = self
        if self > Double.pi {
            wrappedAngle -= 2 * Double.pi
        } else if self < -Double.pi {
            wrappedAngle += 2 * Double.pi
        }
        return wrappedAngle
    }
}

extension CLLocationCoordinate2D {
    
    static func +(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lhs.latitude + rhs.latitude , longitude: lhs.longitude + rhs.longitude)
    }
    
    static func -(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lhs.latitude - rhs.latitude , longitude: lhs.longitude - rhs.longitude)
    }

    // return bearing from 0 to 360 deg, where 0 is North (assumes flat Earth)
    func bearing(to: CLLocationCoordinate2D) -> Double {
        let deltaLat = to.latitude - self.latitude
        let deltaLon = to.longitude - self.longitude
        return fmod(atan2(deltaLon, deltaLat).degsDouble + 360.0, 360.0)
    }
    
    // return range in feet (assumes flat Earth)
    func range(to: CLLocationCoordinate2D) -> Double {
        let deltaLat = to.latitude - self.latitude
        let deltaLon = to.longitude - self.longitude
        let deltaNorth = deltaLat * Conversion.degToFeet
        let deltaEast = deltaLon * cos(self.latitude.radsDouble) * Conversion.degToFeet
        return sqrt(pow(deltaNorth, 2) + pow(deltaEast, 2))
    }
}
