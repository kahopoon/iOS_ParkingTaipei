//
//  ViewController.swift
//  ParkingTaipei
//
//  Created by Ka Ho on 14/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class AddressInput_ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var addressSelectionMapView: MKMapView!
    @IBOutlet weak var addressInput: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    let locationManager = CLLocationManager()
    var lastKnownCoordinate: CLLocationCoordinate2D!
    var initialStart: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchButton.layer.cornerRadius = 5
        addressSelectionMapView.layer.cornerRadius = 5
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        addressSelectionMapView.delegate = self
        addressInput.delegate = self
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
            // enable for next step only when location service enabled
            searchButton.enabled = true
            serachButtonTitleChange("尋找")
        } else {
            serachButtonTitleChange("請先於設置開啟定位服務")
        }
    }
    
    func serachButtonTitleChange(wording: String) {
        searchButton.titleLabel?.adjustsFontSizeToFitWidth = true
        searchButton.setTitle(wording, forState: .Normal)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if initialStart {
            zoomToTarget(locations[0].coordinate)
            getAddressFromCoordinate(locations[0])
            initialStart = false
        }
    }
    
    func zoomToTarget(target: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegion(center: target, span: span)
        addressSelectionMapView.setRegion(region, animated: true)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        getAddressFromCoordinate(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))
    }

    func textFieldDidEndEditing(textField: UITextField) {
        getCoordinateFromAddress(textField.text!)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func getAddressFromCoordinate(source: CLLocation) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(source) {
            (placemarks, error) -> Void in
            // chinese geocoder output
            NSUserDefaults.standardUserDefaults().setObject(NSArray(object: "zh-tw"), forKey: "AppleLanguages")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.addressInput.text = String(placemarks![0].addressDictionary!["Name"]!)
            self.lastKnownCoordinate = source.coordinate
        }
    }
    
    func getCoordinateFromAddress(source: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(source, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            if let foundPlace = placemarks?[0].location?.coordinate {
                self.lastKnownCoordinate = foundPlace
                self.zoomToTarget(foundPlace)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

