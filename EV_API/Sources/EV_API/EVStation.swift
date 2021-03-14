//
//  EVStation.swift
//  CommandLine
//
//  Created by Shin on 3/8/21.
//

import Foundation

struct EVStation: Codable {
    private let stationName: String
     let stationId: String
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
    
    init? (dict: [String: String]) {
        guard let stationName = dict.value(of: .statNm),
              let stationId = dict.value(of: .statId),
              let latitude = Float(dict.value(of: .lat) ?? ""),
              let longitude = Float(dict.value(of: .lng) ?? ""),
              let organName = dict.value(of: .busiNm),
              let address =  dict.value(of: .addr),
              let organCallNumber = dict.value(of: .busiCall),
              let zcode = Int(dict.value(of: .zcode) ?? "")
              else {
            print("Data missing \n", dict)
            return nil
        }
        self.stationName = stationName
        self.stationId = stationId
        self.latitude = latitude
        self.longitude = longitude
        self.zcode = zcode
        self.address = address
        self.organName = organName
        self.organCallNumber = organCallNumber
        self.chargerType = dict.value(of: .chgerType) ?? ""
        self.powerType = dict.value(of: .powerType) ?? ""
        self.organId = dict.value(of: .busiId) ?? ""
        self.timeAvailable = dict.value(of: .useTime) ?? ""
        self.note = dict.value(of: .note) ?? ""
        self.chargerId = dict.value(of: .chgerId) ?? ""
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
