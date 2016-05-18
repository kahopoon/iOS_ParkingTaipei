//
//  API_Call.swift
//  ParkingTaipei
//
//  Created by Ka Ho on 15/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import Alamofire

let parkingArea_API_url = "http://data.taipei/opendata/datalist/apiAccess?scope=resourceAquire&rid=790d745e-6a0a-4f86-a231-a1025bf39218"
let parkingSpot_API_url = "http://data.taipei/opendata/datalist/apiAccess?scope=resourceAquire&rid=940f77e5-95a2-4a03-aff0-2a63997f54e2"

func parkingAreaAPICall (completion: (parkingArea: AnyObject) -> Void) {
    Alamofire.request(.GET, parkingArea_API_url).responseJSON { (response) in
        completion(parkingArea: response.result.value!)
    }
}

func parkingSpotAPICall (completion: (parkingSpot: AnyObject) -> Void) {
    Alamofire.request(.GET, parkingSpot_API_url).responseJSON { (response) in
        completion(parkingSpot: response.result.value!)
    }
}
