//
//  directionNavigation_ViewController.swift
//  ParkingTaipei
//
//  Created by Ka Ho on 15/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class directionNavigation_ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var navigationMapView: MKMapView!
    @IBOutlet weak var goingToLabel, distanceLabel: UILabel!
    @IBOutlet weak var renewNavigationButton: UIButton!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var targetLocation: CLLocationCoordinate2D!
    var parkingLocation: CLLocationCoordinate2D!
    let distanceToAlert: Double = 100
    var targetPlaceName: String!
    var parkingName: String!
    var routeColor: UIColor!
    var parkingPlaceArrived: Bool = false
    var targetPlaceArrived: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        navigationMapView.delegate = self
        
        renewNavigationButton.layer.cornerRadius = 5
        goingToLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.adjustsFontSizeToFitWidth = true
        
        markDestinationStop(targetLocation, title: targetPlaceName, subtitle: "目的地")
        markDestinationStop(parkingLocation, title: parkingName, subtitle: "停車地")
        
        navigationRoute(currentLocation, end: parkingLocation, method: .Automobile)
        navigationRoute(parkingLocation, end: targetLocation, method: .Walking)
        
        goingToLabel.text = parkingName
        distanceLabel.text = "\(Int(CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude).distanceFromLocation(CLLocation(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude))))米"
    }

    func markDestinationStop(source: CLLocationCoordinate2D, title: String, subtitle: String) {
        let marker = MKPointAnnotation()
        marker.title = title
        marker.subtitle = subtitle
        marker.coordinate = source
        navigationMapView.addAnnotation(marker)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !parkingPlaceArrived {
            if locations[0].distanceFromLocation(CLLocation(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)) < distanceToAlert {
                parkingPlaceArrived = true
                alertDisplay("停車的地點已到達！")
                goingToLabel.text = targetPlaceName
                distanceLabel.text = "\(Int(CLLocation(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude).distanceFromLocation(CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude))))米"
            }
        }
        if !targetPlaceArrived && parkingPlaceArrived {
            if locations[0].distanceFromLocation(CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)) < distanceToAlert {
                targetPlaceArrived = true
                alertDisplay("目的地已到達！祝你有愉快的一天：）")
                goingToLabel.text = "已到達"
                distanceLabel.text = ""
            }
        }
        // update eta
        distanceLabel.text = "\(Int(CLLocation(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude).distanceFromLocation(CLLocation(latitude: (parkingPlaceArrived ? targetLocation : parkingLocation).latitude, longitude: (parkingPlaceArrived ? targetLocation : parkingLocation).longitude))))米"
    }
    
    func alertDisplay(message: String) {
        let alertController = UIAlertController(title: "溫馨提示", message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "知道了", style: .Cancel) { (action) in
            // update route
            self.renewNavigationAction(self)
            // quit if finished
            if self.targetPlaceArrived && self.parkingPlaceArrived {
                dispatch_async(dispatch_get_main_queue(), {
                    let rootVC = self.storyboard?.instantiateInitialViewController()
                    self.presentViewController(rootVC!, animated: true, completion: nil)
                })
            }
        }
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func renewNavigationAction(sender: AnyObject) {
        navigationMapView.removeOverlays(navigationMapView.overlays)
        parkingPlaceArrived ? () : navigationRoute(currentLocation, end: parkingLocation, method: .Automobile)
        navigationRoute(parkingLocation, end: targetLocation, method: .Walking)
    }
    
    func navigationRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, method: MKDirectionsTransportType) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = method
        
        let directions = MKDirections(request: request)
        
        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            for route in unwrappedResponse.routes {
                self.routeColor = method == .Automobile ? UIColor.redColor().colorWithAlphaComponent(0.4) : UIColor.blueColor().colorWithAlphaComponent(0.4)
                // level is essential for multi color on route
                self.navigationMapView.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
                if method == .Automobile {
                    self.navigationMapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 80.0, left: 80.0, bottom: 80.0, right: 80.0), animated: true)
                }
            }
        }
    }
    
    // essential for route showing on rendering
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = routeColor
        renderer.lineWidth = 5.0
        return renderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
