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
    
    let taipeiCenter:CLLocation = CLLocation(latitude: 25.0856513, longitude: 121.4231615)
    let distanceTooFar:Double = 100000.0
    let locationManager = CLLocationManager()
    var lastKnownInputCoordinate: CLLocationCoordinate2D!
    var lastKnownCurrentCoordinate: CLLocationCoordinate2D!
    var lastKnownInputPlaceName: String!
    var initialStart: Bool = true
    var firstZoom: Bool = true
    var databaseUpdateNeeded: Bool = true
    var databaseTimeStamp:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUpdateNeeded { (required, timeStamp) in
            self.databaseUpdateNeeded = required
            self.databaseTimeStamp = timeStamp
        }
        
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
            serachButtonTitleChange("尋找車位")
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
            initialStart = false
        }
        lastKnownCurrentCoordinate = locations[0].coordinate
    }
    
    func zoomToTarget(target: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegion(center: target, span: span)
        addressSelectionMapView.setRegion(region, animated: false)
        firstZoom ? firstZoom = false : ()
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if !firstZoom {
            getAddressFromCoordinate(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))
        }
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
            self.lastKnownInputPlaceName = self.addressInput.text
            self.lastKnownInputCoordinate = source.coordinate
        }
    }
    
    func getCoordinateFromAddress(source: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(source, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            if let foundPlace = placemarks?[0].location?.coordinate {
                self.lastKnownInputCoordinate = foundPlace
                self.zoomToTarget(foundPlace)
            }
        })
    }
    
    @IBAction func searchAction(sender: AnyObject) {
        if lastKnownCurrentCoordinate == nil {
            alertDisplay("系統還沒有找到你現在的所在位置，請在手機設置裡開啟定位服務喔！如定位服務已開啟，請嘗試到空曠的地方再試試看！")
        } else if lastKnownInputCoordinate == nil {
            alertDisplay("你還沒輸入目的地喔！")
        } else if taipeiCenter.distanceFromLocation(CLLocation(latitude: lastKnownCurrentCoordinate.latitude, longitude: lastKnownCurrentCoordinate.longitude)) > distanceTooFar {
            alertDisplay("你所在位置距離台北市太遠喔！")
        } else {
            self.performSegueWithIdentifier("showParkingList", sender: sender)
        }
    }
    
    func alertDisplay(message: String) {
        let alertController = UIAlertController(title: "等一下", message: message, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "知道了", style: .Cancel, handler: nil)
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showParkingList" {
            let vc = segue.destinationViewController as! ParkingList_ViewController
            vc.destinationLocation = lastKnownInputCoordinate
            vc.currentLocation = lastKnownCurrentCoordinate
            vc.destinationName = lastKnownInputPlaceName
            vc.updateDB = databaseUpdateNeeded
            vc.updateStamp = databaseTimeStamp
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

