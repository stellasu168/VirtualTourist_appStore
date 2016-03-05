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
    
    // collection - array of IndexPath
    var selectedIndexofCollectionViewCells = [NSIndexPath]()
    
    // MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    // Lazily computed property pointing to the Photo entity objects, sorted by title, predicated on the pin.
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

    // Make sure the closure always runs in the main thread
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
    
    
    // "new' images might overlap with previous collections of images
    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        
        // If the button changed is "Delete all"
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
                self.reFetch()
                self.collectionView.reloadData()

            })
        }
    }
    
    
    // Reference: http://studyswift.blogspot.com/2014/09/mkpointannotation-put-pin-on-map.html
    func loadMapView() {

        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = pin?.pinTitle
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        //Span of the map
        //mapView.setRegion(MKCoordinateRegionMake(point.coordinate, MKCoordinateSpanMake(7,7)), animated: true)
        mapView.selectAnnotation(point, animated: true)

    }
    

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
            let sectionInfo = self.fetchedResultsController.sections![section]
            print("Number of photos returned -- \(sectionInfo.numberOfObjects)")
        
        if sectionInfo.numberOfObjects == 0 {
            noImagesLabel.hidden = false
            newCollectionButton.hidden = true
        }
        
            return sectionInfo.numberOfObjects
    }
    
    // Remove photos from an album when user select a cell or select multiple cells
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        
        // Whenever user selects any collection view item
        // Configure the UI of the collection item
        
        print("In the beginning of didSelectItemAtIndexPath \(selectedIndexofCollectionViewCells.count)")
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // When user deselected it
        if let index = selectedIndexofCollectionViewCells.indexOf(indexPath){
            selectedIndexofCollectionViewCells.removeAtIndex(index)
            // Hide the deleteButton
            cell.deleteButton.hidden = true
        } else {
            selectedIndexofCollectionViewCells.append(indexPath)
            cell.deleteButton.hidden = false
        }
        
        if selectedIndexofCollectionViewCells.count > 0 {
            print(selectedIndexofCollectionViewCells.count)
            newCollectionButton.setTitle("Delete all", forState: UIControlState.Normal)
        } else{
            print("the count in the else loop\(selectedIndexofCollectionViewCells.count)")
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
        
        
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        print("URL from the collection view is \(photo.url)")

        cell.photoView.image = photo.image
        
        // First time we are not sure show
        cell.deleteButton.hidden = true
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        cell.deleteButton.addTarget(self, action: "deletePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    
        return cell
    }


    func deletePhoto(sender: UIButton){
        
        // I want to know if the cell is selected
        let indexOfTheItem = sender.layer.valueForKey("indexPath") as! NSIndexPath

        // Get photo associated with the indexPath.
        let photo = fetchedResultsController.objectAtIndexPath(indexOfTheItem) as! Photos
        print("Cell selected is \(photo)")
        
        // When user deselected it
        if let index = selectedIndexofCollectionViewCells.indexOf(indexOfTheItem){
            selectedIndexofCollectionViewCells.removeAtIndex(index)
        }
        
        // Remove the photo
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Update selected cell
        reFetch()
        collectionView.reloadData()
        
    }
    
    
    
    

} // The end

