//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/14/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit
import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
    
    // Shared Instance
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        return Static.instance
    }
    

}
