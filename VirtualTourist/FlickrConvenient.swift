//
//  FlickrConvenient.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/10/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit
import CoreData

extension FlickrClient {
    
    func downloadPhotosForPin(pin: Pin, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        // Init randomPage variable
        var randomPageNumber: Int = 1
        
        if let pageNumber = pin.pageNumber {
            
            let pageNumberInt = pageNumber as Int
            randomPageNumber = Int((arc4random_uniform(UInt32(pageNumberInt)))) + 1
            
        }
        
        //Parameters for request photos
        let parameters: [String : AnyObject] = [
            URLKeys.Method : Methods.Search,
            URLKeys.APIKey : Constants.APIKey,
            URLKeys.Format : URLValues.JSONFormat,
            URLKeys.NoJSONCallback : 1,
            URLKeys.Latitude : pin.latitude,
            URLKeys.Longitude : pin.longitude,
            URLKeys.Extras : URLValues.URLMediumPhoto,
            URLKeys.Page : randomPageNumber,
            URLKeys.PerPage : 21
        ]
        
        //Make GET request for get photos for pin
        taskForGETMethodWithParameters(parameters, completionHandler: {
            results, error in
            
            if let error = error {
                completionHandler(success: false, error: error)
            } else {
                
                //response dictionary
                if let photosDictionary = results.valueForKey(JSONResponseKeys.Photos) as? [String: AnyObject],
                    photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String : AnyObject]],
                    numberOfPhotoPages = photosDictionary[JSONResponseKeys.Pages]     as? Int {
                        
                        pin.pageNumber = numberOfPhotoPages
                        
                        //dictionary with photos
                        for photoDictionary in photosArray {
                            
                            let photoURLString = photoDictionary[URLValues.URLMediumPhoto] as! String
                            
                            //create Photo model
                            let newPhoto = Photos(photoURL: photoURLString, pin: pin, context: self.sharedContext)
                            
                            //download photo by url
                            self.downloadPhotoImage(newPhoto, completionHandler: {
                                success, error in
                                
                                print("\(success): \(error)")
                                
                                NSNotificationCenter.defaultCenter().postNotificationName("downloadPhotoImage.done", object: nil)
                                
                                //Save the context
                                dispatch_async(dispatch_get_main_queue(), {
                                    CoreDataStackManager.sharedInstance().saveContext()
                                })
                            })
                        }
                        
                        completionHandler(success: true, error: nil)
                } else {
                    
                    completionHandler(success: false, error: NSError(domain: "downloadPhotosForPin", code: 0, userInfo: nil))
                }
            }
        })
    }
    
    // download, save image and change file path for photo
    func downloadPhotoImage(photo: Photos, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let imageURLString = photo.url
        
        //Make GET request for download photo by url
        taskForGETMethod(imageURLString!, completionHandler: {
            result, error in
            
            //if error - set file path to error for show blank image
            if let error = error {
                
                photo.filePath = "error"
                
                completionHandler(success: false, error: error)
            } else {
                
                if let result = result {
                    
                    //get file name and file url
                    let fileName = (imageURLString! as NSString).lastPathComponent
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                    let pathArray = [dirPath, fileName]
                    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                    
                    //save file
                    NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
                    
                    //update the Photo model
                    photo.filePath = fileURL.path
                    
                    completionHandler(success: true, error: nil)
                }
            }
        })
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }


}
