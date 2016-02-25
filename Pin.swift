//
//  Pin.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/21/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
class Pin: NSManagedObject {
    
    
    // In Swift, superclass initializers are not available to subclasses, so it is necessary to include this initializer and call the superclass' implementation of it.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = lat
        self.longitude = long
        
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext

    }
}
