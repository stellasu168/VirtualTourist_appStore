//
//  Photos.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/20/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit


@objc(Photos)
class Photos: NSManagedObject {
    
    var image: UIImage? {
        
        if let filePath = filePath {
            
            // Check to see if there's an error downloading the images for each Pin
            if filePath == "error" {
                return UIImage(named: "404.jpg")
            }
            
            // Get the file path
            let fileName = (filePath as NSString).lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil

        
    }

    // MARK: - Init model
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(photoURL: String, pin: Pin, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Photos", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.url = photoURL
        self.pin = pin
        print("init from Photos.swift\(url)")
        
    }
    

    
    

}
