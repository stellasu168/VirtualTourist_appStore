//
//  LocationMapViewController.swift
//  VirtualTourist
//
//  Created by Stella Su on 1/27/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//
// If the app is turned off, the map should return to the same state when it is turned on again.

import UIKit
import MapKit
import CoreLocation

class LocationMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    var selectedPin: Pin? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        // Set the map view delegate
        mapView.delegate = self
        
        deleteLabel.hidden = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // I need to push the view up a little bit
    @IBAction func editClicked(sender: AnyObject) {
        deleteLabel.hidden = false
        
    }

    // http://stackoverflow.com/questions/5182082/mkmapview-drop-a-pin-on-touch
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        
        let coordinates = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        //annotation.title = "Dropped Pin"
        //annotation.subtitle = CLGeocoder().reverseGeocodeLocation(coordinates, completionHandler: )
        
        let geoCoder = CLGeocoder()
        var _: AnyObject
        var _: NSError
        
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

    // Pin will transition to the Phone Album View when a pin is tapped
    // Start by updating the view for the annotation. This is necessary because it allows you to intercept taps on the annotation's view (the pin).
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        // do other things when pin is selected
        guard let annotation = view.annotation else { /* no annotation */ return }
       
        // let latitude = annotation.coordinate.latitude
        // let longitude = annotation.coordinate.longitude
        let title = annotation.title!
        mapView.deselectAnnotation(annotation, animated: true)
        if title != nil {
            print(title!)
        }
        
        // Move to the Phone Album view controller
        //let controller = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbum")
        //self.presentViewController(controller!, animated: true, completion: nil)
        self.performSegueWithIdentifier("PhotoAlbum", sender: nil)
        
        }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "PhotoAlbum") {
            let viewController = segue.destinationViewController as! PhotoAlbumViewController
            viewController.pin = selectedPin
            
        }
        
    }


 
    
    
}





















