//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/7/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    // Array of IndexPath - keeping track of index of selected cells
    var selectedIndexofCollectionViewCells = [NSIndexPath]()
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    // Lazily computed property pointing to the Photos entity objects, sorted by title, predicated on the pin.
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request for photos which match the sent Pin.
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        
        // Limit the fetch request to just those photos related to the Pin.
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        
        // Sort the fetch request by title, ascending.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        // Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newCollectionButton.hidden = false
        noImagesLabel.hidden = true
        
        mapView.delegate = self
        
        // Load the map
        loadMapView()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("\(error)")
        }
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        // Subscirbe to notification so photos can be reloaded
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "photoReload:", name: "downloadPhotoImage.done", object: nil)
    }

    // Inserting dispatch_async to ensure the closure always runs in the main thread
    func photoReload(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
        })
    }
    
    private func reFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
    
    
    // Note: "new' images might overlap with previous collections of images
    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        
        // If the button changed to "Delete all", delete the photo
        if newCollectionButton.titleLabel!.text == "Delete all"
        {
            // Removing the photo that user selected one by one
            for indexPath in selectedIndexofCollectionViewCells {
            
                // Get photo associated with the indexPath.
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
            
                // Remove the photo
                sharedContext.deleteObject(photo)
                
            }
            
            // Empty the array of indexPath after deletion
            selectedIndexofCollectionViewCells.removeAll()
            
            // Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Update cells
            reFetch()
            collectionView.reloadData()
            
            // Change the button to say 'New Collection' after deletion
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)

            return
            
        } else if newCollectionButton.titleLabel!.text == "New Collection" {
            
            // 1. Empty the photo album
            for photo in fetchedResultsController.fetchedObjects as! [Photos]{
                sharedContext.deleteObject(photo)
            }
            
            // 2. Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
        
            // 3. Download a new set of photos with the current pin
            FlickrClient.sharedInstance().downloadPhotosForPin(pin!, completionHandler: {
                success, error in
            
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.newCollectionButton.hidden = false
                })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                    print("error downloading a new set of photos")
                    self.newCollectionButton.hidden = false
                    })
                }
                // Update cells
                self.reFetch()
                self.collectionView.reloadData()

            })
        }
    }
    
    // Load map view for the current pin
    // Reference: http://studyswift.blogspot.com/2014/09/mkpointannotation-put-pin-on-map.html
    func loadMapView() {

        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = pin?.pinTitle
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        // Select the annotation so the title can be shown
        mapView.selectAnnotation(point, animated: true)

    }
    
    // Return the number of photos from fetchedResultsController
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
            let sectionInfo = self.fetchedResultsController.sections![section]
            print("Number of photos returned from fetchedResultsController -- \(sectionInfo.numberOfObjects)")
        
        if sectionInfo.numberOfObjects == 0 {
            noImagesLabel.hidden = false
            newCollectionButton.hidden = true
        }
        
        return sectionInfo.numberOfObjects
    }
    
    // Remove photos from an album when user select a cell or multiple cells
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        
        // Configure the UI of the collection item
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // When user deselect the cell, remove it from the selectedIndexofCollectionViewCells array
        if let index = selectedIndexofCollectionViewCells.indexOf(indexPath){
            selectedIndexofCollectionViewCells.removeAtIndex(index)
            // Hide the deleteButton
            cell.deleteButton.hidden = true
        } else {
            // Else, add it to the selectedIndexofCollectionViewCells array
            selectedIndexofCollectionViewCells.append(indexPath)
            cell.deleteButton.hidden = false
        }
        
        // If the array is not empty, show the 'Delete all' button
        if selectedIndexofCollectionViewCells.count > 0 {
            print(selectedIndexofCollectionViewCells.count)
            newCollectionButton.setTitle("Delete all", forState: UIControlState.Normal)
        } else{
            // Else, show the 'New Collection' button
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
        
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        print("Photo URL from the collection view is \(photo.url)")

        cell.photoView.image = photo.image
        
        cell.deleteButton.hidden = true
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        
        // Trigger the action 'deletePhoto' when the button is tapped
        cell.deleteButton.addTarget(self, action: "deletePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    
        return cell
    }

    func deletePhoto(sender: UIButton){
        
        // I want to know if the cell is selected giving the indexPath
        let indexOfTheItem = sender.layer.valueForKey("indexPath") as! NSIndexPath

        // Get the photo associated with the indexPath
        let photo = fetchedResultsController.objectAtIndexPath(indexOfTheItem) as! Photos
        print("Cell selected is \(photo)")
        
        // When user deselected it, remove it from the selectedIndexofCollectionViewCells array
        if let index = selectedIndexofCollectionViewCells.indexOf(indexOfTheItem){
            selectedIndexofCollectionViewCells.removeAtIndex(index)
        }
        
        // Remove the photo
        sharedContext.deleteObject(photo)
        
        // Save to core data
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Update selected cell
        reFetch()
        collectionView.reloadData()
    }
    
    

} // The end

