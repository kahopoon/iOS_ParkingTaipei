//
//  ParkingList_TableViewController.swift
//  ParkingTaipei
//
//  Created by Ka Ho on 15/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import PKHUD

class ParkingList_ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var bikeCarChoice: UISegmentedControl!
    @IBOutlet weak var mainTableView: UITableView!
    
    var destinationLocation: CLLocationCoordinate2D!
    var currentLocation: CLLocationCoordinate2D!
    var destinationName: String!
    var updateDB:Bool!
    var updateStamp:String!
    var parkingSpotResult: [String:[String:String]] = [:]
    var parkingAreaResult: [String:[String:String]] = [:]
    var sortedParkingSpot:[(String,[String:String])] = []
    var sortedParkingArea:[(String,[String:String])] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainTableView.alpha = 0
        bikeCarChoice.alpha = 0
        
        if updateDB == true {
            HUD.show(.LabeledProgress(title: (NSUserDefaults.standardUserDefaults().objectForKey("lastUpdate") == nil ? "首次使用下載中" : "新版資料庫下載中"), subtitle: "請稍候"))
            parkingResultAPICall { (result) in
                if result {
                    HUD.flash(.LabeledSuccess(title: "下載成功", subtitle: ""), delay: 2.0)
                    self.mainTableView.reloadData()
                    self.bikeCarChoice.alpha = 1
                    self.mainTableView.alpha = 1
                }
            }
        } else {
            HUD.flash(.LabeledSuccess(title: "搜尋到以下車位", subtitle: ""), delay: 2.0)
            parkingResultFromLocal({ (result) in
                if result {
                    self.mainTableView.reloadData()
                    self.bikeCarChoice.alpha = 1
                    self.mainTableView.alpha = 1
                }
            })
        }
    }
    
    @IBAction func bikeCarSelection(sender: AnyObject) {
        switch bikeCarChoice.selectedSegmentIndex {
        default:
            mainTableView.reloadData()
        }
    }

    func parkingResultFromLocal(completion: (result:Bool) -> Void) {
        let destination = CLLocation(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude)
        parkingSpotResult = NSKeyedUnarchiver.unarchiveObjectWithFile(NSHomeDirectory().stringByAppendingString("/Documents/parkingSpotResult.dat")) as! [String:[String:String]]
        parkingAreaResult = NSKeyedUnarchiver.unarchiveObjectWithFile(NSHomeDirectory().stringByAppendingString("/Documents/parkingAreaResult.dat")) as! [String:[String:String]]
        sortArrayByDistance(destination, category: 0)
        sortArrayByDistance(destination, category: 1)
        completion(result: true)
    }
    
    func parkingResultAPICall(completion: (result: Bool) -> Void) {
        let destination = CLLocation(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude)
        parkingAreaAPICall { (parkingArea) in
            self.resultInsertArray(JSON(parkingArea), category: 1)
            self.sortArrayByDistance(destination, category: 1)
            parkingSpotAPICall({ (parkingSpot) in
                self.resultInsertArray(JSON(parkingSpot), category: 0)
                self.sortArrayByDistance(destination, category: 0)
                completion(result: true)
            })
        }
    }
    
    // category 1 = area, 0 = spot
    func resultInsertArray(data: JSON, category: Int) -> Bool {
        let results = data["result"]["results"].arrayValue
        for eachResult in results {
            let jsonName = category == 1 ? "GATENAME" : "Near_Place"
            let id = eachResult["_id"].stringValue
            let name = eachResult[jsonName].stringValue
            let lat = eachResult["POINT_Y"].stringValue
            let lng = eachResult["POINT_X"].stringValue
            category == 1 ? (parkingAreaResult[id] = ["name":name, "lat":lat, "lng":lng]) : (parkingSpotResult[id] = ["name":name, "lat":lat, "lng":lng])
        }
        // all data save to file
        NSKeyedArchiver.archiveRootObject((category == 1 ? parkingAreaResult : parkingSpotResult), toFile: NSHomeDirectory().stringByAppendingString("/Documents/\(category == 1 ? "parkingAreaResult" : "parkingSpotResult").dat"))
        // update user defaults
        NSUserDefaults.standardUserDefaults().setObject(updateStamp, forKey: "lastUpdate")
        NSUserDefaults.standardUserDefaults().synchronize()
        return true
    }
    
    func sortArrayByDistance(sourceLocation: CLLocation, category: Int) {
        for loop in (category == 1 ? parkingAreaResult : parkingSpotResult) {
            let stopLocation = CLLocation(latitude: Double(loop.1["lat"]!)!, longitude: Double(loop.1["lng"]!)!)
            let distance = String(stopLocation.distanceFromLocation(sourceLocation))
            category == 1 ? (parkingAreaResult[loop.0]!["distanceFromYou"] = distance) : (parkingSpotResult[loop.0]!["distanceFromYou"] = distance)
        }
        
        func sort(source: [String:[String:String]]) -> [(String,[String:String])] {
            return source.sort({Double($0.1["distanceFromYou"]!)! < Double($1.1["distanceFromYou"]!)!})
        }
        category == 1 ? (sortedParkingArea = sort(parkingAreaResult)) : (sortedParkingSpot = sort(parkingSpotResult))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bikeCarChoice.selectedSegmentIndex == 1 ? sortedParkingArea.count : sortedParkingSpot.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ParkingList_TableViewCell", forIndexPath: indexPath) as! ParkingList_TableViewCell
        let data = bikeCarChoice.selectedSegmentIndex == 1 ? sortedParkingArea : sortedParkingSpot
        cell.name.text = data[indexPath.row].1["name"]
        cell.distance.text = "\(Int(Double(data[indexPath.row].1["distanceFromYou"]!)!))米"
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "directionMap" {
            let vc = segue.destinationViewController as! directionNavigation_ViewController
            let indexPath = mainTableView.indexPathForSelectedRow
            
            vc.parkingName = (bikeCarChoice.selectedSegmentIndex == 1 ? sortedParkingArea : sortedParkingSpot)[indexPath!.row].1["name"]
            vc.targetLocation = destinationLocation
            vc.currentLocation = currentLocation
            vc.targetPlaceName = destinationName
            
            func transformCoordinate2D(lat: String, lng: String) -> CLLocationCoordinate2D {
                return CLLocation(latitude: Double(lat)!, longitude: Double(lng)!).coordinate
            }
            vc.parkingLocation = bikeCarChoice.selectedSegmentIndex == 1 ? (transformCoordinate2D(sortedParkingArea[indexPath!.row].1["lat"]!, lng: sortedParkingArea[indexPath!.row].1["lng"]!)) : (transformCoordinate2D(sortedParkingSpot[indexPath!.row].1["lat"]!, lng: sortedParkingSpot[indexPath!.row].1["lng"]!))
        }
    }
}
