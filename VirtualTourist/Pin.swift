//
//  Pin.swift
//  VirtualTourist
//
//  Created by Stella Su on 1/27/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//
import UIKit
import MapKit
import CoreData

class Pin: NSManagedObject {
    
    // MARK: - Pin model properties
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
//    @NSManaged var photos: NSMutableOrderedSet
//    @NSManaged var pageNumber: Int
    
    var coordinate: CLLocationCoordinate2D {
        
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    
    // MARK: - Init model
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        // Entity of core data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
//        self.photos = NSMutableOrderedSet()
//        self.pageNumber = 1
    }
}
