//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/14/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//
//  Using the same file from the favoriteActors' app
//  ** Watch lession 4 - core data from scratch 


import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
    
    //--------------------------------------
    // MARK: - Shared Instance
    //--------------------------------------
    
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        return Static.instance
    }
    
    //--------------------------------------
    // MARK: - Core Data Stack
    //--------------------------------------
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            print("Failed to log persistent store: \(error)")
            abort()
        }
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    //--------------------------------------
    // MARK: - Saving Support
    //--------------------------------------
    
    func saveContext(completionHandler: (error: NSError?) -> Void) {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let error = error as NSError
                print("Encoutered error while saving: \(error.localizedDescription)")
                completionHandler(error: error)
            }
        }
    }
}


}
