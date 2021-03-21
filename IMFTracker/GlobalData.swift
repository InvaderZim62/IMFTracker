//
//  GlobalData.swift
//  IMFTracker
//
//  Created by Phil Stern on 3/21/21.
//
//  (see Mastermind for another example of GlobalData)
//

import UIKit

class GlobalData: NSObject {
    static let sharedInstance = GlobalData()
    private override init() {}  // private to prevent: let myInstance = GlobalData() (a non-shared instance)
    
    var dotRowSpacing: CGFloat = 0
    var dialCenter: CGPoint = .zero
}
