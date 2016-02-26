//
//  LocationMapViewController.swift
//  VirtualTourist
//
//  Created by Stella Su on 1/27/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//
//  *If the app is turned off, the map should return to the same state when it is turned on again.

import UIKit
import MapKit
import CoreLocation
import CoreData

class LocationMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UINavigationItem!
    
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    var editingPins: Bool = false
    
    // Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            print("error in fetch")
            return [Pin]()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        // Set the map view delegate
        mapView.delegate = self
        deleteLabel.hidden = true
        
    }
    

    @IBAction func editClicked(sender: UIBarButtonItem) {
        print("Editing pins is ... \(editingPins)")
        
        if editingPins == false {
            editingPins = true
            deleteLabel.hidden = false
            navigationItem.rightBarButtonItem?.title = "Done"
        
            print("Now, the editing pins is ... \(editingPins)")
        }

        else if editingPins {
   
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingPins = false
            deleteLabel.hidden = true

        }

        // I need to push the view up a little bit?
    
    }

    // http://stackoverflow.com/questions/5182082/mkmapview-drop-a-pin-on-touch
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        
        if (editingPins) {
            // Do something?!
            return
        } else {
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        let pin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
        pins.append(pin)
        
        // Downloading photos
        FlickrClient.sharedInstance().downloadPhotosForPin(pin) { (success, error) in print("\(success) - \(error)") }
        
        // Find out the location name based on the coordinates
        let coordinates = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(coordinates, completionHandler: { (placemark, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            if placemark!.count > 0 {
                let pm = placemark![0] as CLPlacemark
                if (pm.locality != nil) && (pm.country != nil) {
                    annotation.title = "\(pm.locality!), \(pm.country!)"
                }
            } else {
                print("Error with data")
            }
        })
        
        mapView.addAnnotation(annotation)
        }
    }

    // Pin will transition to the Phone Album View when a pin is tapped
    // Start by updating the view for the annotation. This is necessary because it allows you to intercept taps on the annotation's view (the pin).
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }

    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let annotation = view.annotation else { /* no annotation */ return }
        
        let title = annotation.title!
        selectedPin = nil
        
        for pin in pins {
            
            if annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude {
                
                selectedPin = pin
                
                if editingPins {
                    
                    print("Deleting pin - verify core data is deleting as well")
                    sharedContext.deleteObject(selectedPin!)
                    self.mapView.removeAnnotation(annotation)
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                } else {
                    
                    if title != nil {
                        pin.pinTitle = title!
                        
                    } else {
                        pin.pinTitle = "This pin has no name"
                    }
                    
                    // Move to the Phone Album View Controller
                    self.performSegueWithIdentifier("PhotoAlbum", sender: nil)

                    }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "PhotoAlbum") {
            let viewController = segue.destinationViewController as! PhotoAlbumViewController
            viewController.pin = selectedPin
        
        }
        
    }


 
    
    
} // End of LocationMapViewController.swift





















