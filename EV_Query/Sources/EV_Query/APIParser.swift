#if canImport(FoundationXML)
import FoundationXML
#endif

import Foundation
import NIO

class APIParser: NSObject, XMLParserDelegate {
    // Data
    private var results = Set<EVStationStatus>()
    private var currentParsingData = [String: String]()
    
    // Parse flow properites
    private var onParsing: Bool = false
    private var currentElement = ""
    private var elementCount = 0

    
    // Request parameters
    let eCarKey: String
    var pageNum: Int
    private let numOfRows: Int
    
    init(apiKey: String, pageNum: Int = 1, numOfRows: Int = 1000) {
        self.eCarKey = apiKey
        self.pageNum = pageNum
        self.numOfRows = numOfRows
    }
    
    var urlChargerInfo: URL {
        URL(string: "http://apis.data.go.kr/B552584/EvCharger/getChargerInfo?serviceKey=\(eCarKey)&numOfRows=\(numOfRows)&pageNo=\(pageNum)")!
    }
    var urlChargerStatus: URL {
        URL(string: "http://apis.data.go.kr/B552584/EvCharger/getChargerStatus?serviceKey=\(eCarKey)&numOfRows=\(numOfRows)&pageNo=\(pageNum)")!
    }
    func parse() -> Promise<Set<EVStationStatus>> {
        let promise = Promise<Set<EVStationStatus>>()
        if let parser = XMLParser(contentsOf: urlChargerStatus) {
            parser.delegate = self
            if parser.parse() {
                print("parsed: \(results.count)")
                promise.resolve(with: results)
            } else {
                print("fail to parse")
                promise.reject(with: ParsingError.dataMissing)
            }
            results.removeAll()
        }
        return promise
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
            if elementName == "item" && !onParsing {
                onParsing = true
                currentParsingData.removeAll()
            }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if onParsing {
            let parseString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let parsingKey = ResponseKey(rawValue: currentElement)
            else {
                print(ParsingError.failAboutElement(currentElement))
                return
            }
            currentParsingData[parsingKey.rawValue] = parseString
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" && onParsing {
            if let parsed = EVStationStatus(dict: currentParsingData){
                if var exist = results.first(where: { $0.stationId == parsed.stationId})
                {
                    exist.chargerStatus[parsed.chargerStatus.first!.key] = parsed.chargerStatus.first!.value
                    results.update(with: exist)
                }else {
                    results.insert(parsed)
                }
            }
            onParsing = false
        }
    }
    enum ParsingError: Error {
        case dataMissing
        case failAboutElement(String)
        case failAboutItem([String: String])
    }
}
