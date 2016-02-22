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

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        loadMapView()
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
    }

    // Reference: http://studyswift.blogspot.com/2014/09/mkpointannotation-put-pin-on-map.html
    func loadMapView() {

        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = "Test1"
        point.subtitle = "Test2"
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        //Span of the map
        mapView.setRegion(MKCoordinateRegionMake(point.coordinate, MKCoordinateSpanMake(7,7)), animated: true)

    }
    


} // The end

