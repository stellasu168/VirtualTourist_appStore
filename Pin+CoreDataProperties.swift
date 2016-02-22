//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/21/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var photos: NSSet?

}
