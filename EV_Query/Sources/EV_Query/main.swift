import Foundation
import AWSLambdaEvents
import AWSLambdaRuntime
import MySQLKit

//  AWS Config
let AWSInvokePath: String = ""

// My SQL Config
let hostURL: String = ""
let username: String = ""
let password: String = ""
let port:Int = 3306
let defaultDB:String = ""

Lambda.run { 
  (context,
   request: APIGateway.V2.Request,
   callback: @escaping (Result<APIGateway.V2.Response, Error>) -> Void) in
    switch request.context.http.path {
    case AWSInvokePath:
        guard request.context.http.method == .GET else {
            callback(.success(APIGateway.V2.Response(statusCode: .badRequest)))
            return
        }
        let db = MySQLHandler(
            hostURL: hostURL,
            port: port,
            username: username,
            password: password,
            defaultDB: defaultDB)
        do{
            try db.useDefaultDB()
            let stations = try db.searchDB(for: request)
            let data = try JSONEncoder().encode(stations)
            callback(.success(
                        APIGateway.V2.Response(
                            statusCode: .ok,
                            headers: ["content-type": "application/json"],
                            body: String(data: data, encoding: .utf8)
                        )))
        }catch {
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
                }
            }else {
                callback(.success(
                            APIGateway.V2.Response(
                                statusCode: .internalServerError,
                                body: "\(error.localizedDescription)")))
            }
        }    default:
        callback(.success(APIGateway.V2.Response(statusCode: .notFound)))
    }
}
