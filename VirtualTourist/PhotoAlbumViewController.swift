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
    
    // Flag for deleting pictures
    var isDeleting = false
    var editingFlag: Bool = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // Array of IndexPath - keeping track of index of selected cells
    //var selectedIndexofCollectionViewCells = [NSIndexPath]()
    
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
        
        bottomButton.hidden = false
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
        
        // Subscirbe to notification so photos can be reloaded - catches the notification from FlickrConvenient
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "photoReload:", name: "downloadPhotoImage.done", object: nil)
    }

    // Inserting dispatch_async to ensure the closure always run in the main thread
    func photoReload(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
            
            // If no photos remaining, show the 'New Collection' button
            let numberRemaining = FlickrClient.sharedInstance().numberOfPhotoDownloaded
            //print("numberRemaining is from photoReload \(numberRemaining)")
            if numberRemaining <= 0 {
                self.bottomButton.hidden = false
            }
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
    @IBAction func bottomButtonTapped(sender: UIButton) {
        
        // Hiding the button once it's tapped, because I want to finish either deleting or reloading first
        bottomButton.hidden = true
        
            
        // 1. Empty the photo album from the previous set
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
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                print("error downloading a new set of photos")
                self.bottomButton.hidden = false
                })
            }
            // Update cells
            dispatch_async(dispatch_get_main_queue(), {
                self.reFetch()
                self.collectionView.reloadData()
            })

        })
        
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
        print("Number of photos returned from fetchedResultsController #\(sectionInfo.numberOfObjects)")
        // If numberOfObjects is not zero, hide the noImagesLabel
        noImagesLabel.hidden = sectionInfo.numberOfObjects != 0
        
        return sectionInfo.numberOfObjects
    }
    
    @IBAction func editButtonTapped(sender: AnyObject) {
        
        if(self.navigationItem.rightBarButtonItem?.title == "Edit"){
            
            self.navigationItem.rightBarButtonItem?.title = "Done"

            for item in self.collectionView!.visibleCells() as! [PhotoCollectionViewCell] {
                
                let indexpath : NSIndexPath = self.collectionView!.indexPathForCell(item as PhotoCollectionViewCell)!
                
                let cell : PhotoCollectionViewCell = self.collectionView!.cellForItemAtIndexPath(indexpath) as! PhotoCollectionViewCell
                
                //Delete Button
                cell.deleteButton.hidden = false
            }
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Edit"
            self.collectionView?.reloadData()
            editingFlag = false
        }
        
    }
    
    // Remove photos from an album when user select a cell or multiple cells
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
       
        if editingFlag == false{

            let myImageViewPage: ImageScrollView = self.storyboard?.instantiateViewControllerWithIdentifier("ImageScrollView") as! ImageScrollView
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
            
            // Pass the selected image
            if photo.url != nil {
                myImageViewPage.selectedImage = photo.url!
            } else {
                print("Error -> photo.url")
            }
        
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        print("Photo URL from the collection view is \(photo.url)")
        
        if self.navigationItem.rightBarButtonItem!.title == "Edit" {
            cell.deleteButton.hidden = true
        } else {
            cell.deleteButton?.hidden = false
        }

        cell.photoView.image = photo.image
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
        print("Delete cell selected from 'deletePhoto' is \(photo)")
        
        // Remove the photo
        sharedContext.deleteObject(photo)
        
        // Save to core data
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Update selected cell
        reFetch()
        self.collectionView.reloadData()
    }
    
    

} // The end

