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

struct EVStationStatus: Codable, Hashable {
    let stationId: String
    var lastUpdated: Date
    var chargerStatus: [Int: Int] // chargerID: status
    
    enum ResponseKey: String {
        case statNm
        case statId
        case chgerId
        case statUpdDt
        case stat
    }
    init? (dict: [String: String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        guard let stationId = dict.value(of: .statId),
              let statUpdDt = dict.value(of: .statUpdDt),
              let lastUpdated = dateFormatter.date(from: statUpdDt) ,
              let chargerId = Int(dict.value(of: .chgerId) ?? ""),
              let status = Int(dict.value(of: .stat) ?? "")
        else {
            return nil
        }
        self.stationId = stationId
        self.lastUpdated = lastUpdated
        self.chargerStatus = [ chargerId: status ]
    }
}



enum ResponseKey: String {
    case statNm
    case statId
    case chgerId
    case chgerType
    case addr
    case lat
    case lng
    case useTime
    case busiId
    case busiNm
    case busiCall
    case stat
    case statUpdDt
    case powerType
    case note
    case zcode
    case parkingFree
}

extension Dictionary where Key == String, Value == String {
    func value(of key: ResponseKey) -> String? {
        self[key.rawValue]
    }
}
