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
        
        // do other things
        
        guard let annotation = view.annotation else { /* no annotation */ return }
        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude
        let title = annotation.title
        mapView.deselectAnnotation(annotation, animated: true)
        print(latitude, longitude, title)
        
        
    }


    
}

