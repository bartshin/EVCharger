
import Foundation
import NIO

class APIParser: NSObject, XMLParserDelegate {
    // Data
    private var results: [EVStation] = []
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
    
    var url: URL {
        URL(string: "http://apis.data.go.kr/B552584/EvCharger/getChargerInfo?serviceKey=\(eCarKey)&numOfRows=\(numOfRows)&pageNo=\(pageNum)")!
    }
    func parse() -> Promise<[EVStation]> {
        let promise = Promise<[EVStation]>()
        if let parser = XMLParser(contentsOf: url) {
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
            guard let parsingKey = EVStation.ResponseKey(rawValue: currentElement)
            else {
                print(ParsingError.failAboutElement(currentElement))
                return
            }
            currentParsingData[parsingKey.rawValue] = parseString
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" && onParsing {
            if let parsedEVStation = EVStation(dict: currentParsingData) {
                results.append(parsedEVStation)
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
