//
//  File.swift
//  
//
//  Created by Shin on 3/12/21.
//

import Foundation

struct EVStation: Codable {
    
    private let stationName: String
    private let stationId: String
    private let chargerId: String
    private let chargerType: String
    private let address: String
    private let latitude: Float
    private let longitude: Float
    private let timeAvailable: String
    private let organId: String
    private let organName: String // 운영 기관
    private let organCallNumber: String
    private let powerType: String
    private let note: String
    private let zcode: Int
}

struct Coordinates {
    let latitude: Double
    let longitude: Double
    
    init?(latitudeString: String, longitudeString: String) {
        if let latitude = Double(latitudeString),
           let longitude = Double(longitudeString) {
            self.latitude = latitude
            self.longitude = longitude
        }else {
            return nil
        }
    }
}
