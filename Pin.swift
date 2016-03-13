//
//  Pin.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/21/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
class Pin: NSManagedObject {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // In Swift, superclass initializers are not available to subclasses, so it is necessary to include this initializer and call the superclass' implementation of it.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = lat
        self.longitude = long
        self.pageNumber = 0
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext

    }
}
