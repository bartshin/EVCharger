import Foundation
import AWSLambdaEvents
import AWSLambdaRuntime
import MySQLKit

/// - Tag: Config

// EV Charger API
let apikey:String = ""

//  AWS Config
let AWSInvokePath: String = ""

// My SQL Config
let hostURL: String = ""
let username: String = ""
let password: String = ""
let port:Int = 3306
let defaultDB:String = ""

// Update interval
let minimumRetrigger: TimeInterval = 5 * 60

Lambda.run { 
  (context,
   request: APIGateway.V2.Request,
   callback: @escaping (Result<APIGateway.V2.Response, Error>) -> Void) in
    switch (request.context.http.path, request.context.http.method) {
    case (AWSInvokePath, .GET):
        // MARK: - Return station data
        
        let db = MySQLHandler(
            hostURL: hostURL,
            port: port,
            username: username,
            password: password,
            defaultDB: defaultDB)
        do{
            let stations = try db.searchDB(for: request)
            let data = try JSONEncoder().encode(stations)
            callback(.success(
                        APIGateway.V2.Response(
                            statusCode: .ok,
                            headers: ["content-type": "application/json"],
                            body: String(data: data, encoding: .utf8)
                        )))
        }catch {
            returnError(error, by: callback)
        }
        // MARK: - Update charger status
        
        if let lastUpdated = db.getLastUpdated(of: "chargerStatus") ,
           abs(lastUpdated.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate) > minimumRetrigger{
            let parser = APIParser(apiKey: apikey)
            let promise = parser.parse()
            promise.observe { result in
                switch result {
                case .success(let statusSet):
                    statusSet.forEach{
                        do{
                            try db.insertStatus($0)
                        }catch {
                            print(error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    case ( AWSInvokePath, .POST):
        let db = MySQLHandler(
            hostURL: hostURL,
            port: port,
            username: username,
            password: password,
            defaultDB: defaultDB)
        let jsonDecoder = JSONDecoder()
        if let body = request.body,
            let idToSearch = try? jsonDecoder.decode([String].self, from: body) {
            do {
                let status = try db.getStatus(for: idToSearch)
                let data = try JSONEncoder().encode(status)
                callback(.success(
                            APIGateway.V2.Response(
                                statusCode: .ok,
                                headers: ["content-type": "application/json"],
                                body: String(data: data, encoding: .utf8))))
            }catch {
                returnError(error, by: callback)
            }
        }else {
            callback(.success(
                        APIGateway.V2.Response(
                            statusCode: .badRequest,
                            body: request.body)))
        }
    default:
        callback(.success(APIGateway.V2.Response(statusCode: .notFound)))
    }
}


func returnError(_ error: Error, by callback : @escaping (Result<APIGateway.V2.Response, Error>) -> Void) {
    if let sqlError = error as? MySQLError {
        switch sqlError {
        case .decodingError:
            callback(.success(APIGateway.V2.Response(
                statusCode: .internalServerError,
                body:"Decoding error"
            )))
        case .failToFindDB:
            callback(.success(APIGateway.V2.Response(
                                statusCode: .internalServerError,
                                body: "Fail to set up db")))
        case .invaildRequest(let request):
            callback(.success(APIGateway.V2.Response(
                                statusCode: .badRequest,
                body: request)))
        case .failToQueryDB(let error):
            callback(.success(
                        APIGateway.V2.Response(statusCode: .internalServerError,
                                               body: error)))
        }
    }else {
        callback(.success(
                    APIGateway.V2.Response(
                        statusCode: .internalServerError,
                        body: "\(error.localizedDescription)")))
    }
}
