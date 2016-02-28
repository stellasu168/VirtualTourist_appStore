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
            print("\(error)")
        }
    }
    
    
    // "new' images might overlap with previous collections of images
    @IBAction func newCollectionButtonTapped(sender: UIButton) {
        print("New collection tapped")
        
        // ??? Empty the photo album ???
        for photo in fetchedResultsController.fetchedObjects as! [Photos]{
            sharedContext.deleteObject(photo)
        }
        
        // Save the chanages to core data
        CoreDataStackManager.sharedInstance().saveContext()
        reFetch()
        
        // Download a new set of photos with this pin
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
        })
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
            print("\(sectionInfo.numberOfObjects)")
        
        if sectionInfo.numberOfObjects == 0 {
            noImagesLabel.hidden = false
            newCollectionButton.hidden = true
        }
        
            return sectionInfo.numberOfObjects
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        print("URL from the collection view is \(photo.url)")

        cell.photoView.image = photo.image
        
        return cell
    }


    
    
    
    
    
    
    
    

} // The end

