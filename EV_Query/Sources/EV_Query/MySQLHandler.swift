
import Foundation
import MySQLKit
import NIO
import AWSLambdaEvents

class MySQLHandler: NSObject {
    
    // MYSQL sever config
    private let defaultDatabase: String
    
    private let configuration: MySQLConfiguration
    private var eventLoopGroup: EventLoopGroup!
    private var pools: EventLoopGroupConnectionPool<MySQLConnectionSource>!
    
    private var sql: SQLDatabase {
        self.mysql.sql()
    }
    private var mysql: MySQLDatabase {
        self.pools.database(logger: .init(label: "mysql logger"))
    }
    
    func changeDB(to dbName: String) {
        
        do {
            _ =  try mysql.withConnection{ conn in
                return conn.simpleQuery("USE \(dbName)")
            }
            .wait()
        } catch {
            print(error)
        }
    }
    private func query(located coordinates: Coordinates , with margin: Double, by maxLimit: Int = 100) throws -> [SQLRow] {
        do
        {
            return try sql.select().columns(SQLLiteral.all)
                .from("allChargers")
                .where{
                    $0.where("latitude", .greaterThan, coordinates.latitude - margin)
                        .where("latitude", .lessThan, coordinates.latitude + margin)
                        .where("longitude", .greaterThan, coordinates.longitude - margin)
                        .where("longitude", .lessThan, coordinates.longitude + margin)
                }
                .limit(maxLimit)
                .all().wait()
            
        }catch {
            throw MySQLError.failToQueryDB(error.localizedDescription)
        }
    }
    private func query(contain address: String, by maxLimit: Int = 100) throws -> [SQLRow] {
        do
        {
            return try sql.select().columns(SQLLiteral.all)
                .from("allChargers")
                .where("address", .like, "%\(address)%")
                .limit(maxLimit)
                .all().wait()
        }catch {
            throw MySQLError.failToQueryDB(error.localizedDescription)
        }
    }
    
    init(hostURL: String, port: Int, username: String, password:String,  defaultDB: String) {
        self.configuration = MySQLConfiguration(
            hostname: hostURL,
            port: port,
            username: username,
            password: password,
            database: defaultDB,
            tlsConfiguration: nil)
        defaultDatabase = defaultDB
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.pools = .init(
            source: .init(configuration: configuration),
            maxConnectionsPerEventLoop: 1,
            requestTimeout: .seconds(30),
            logger: .init(label: "pool logger"),
            on: eventLoopGroup)
    }
    func searchDB(for request: APIGateway.V2.Request) throws -> [EVStation] {
        let result: [SQLRow]
        if let latitude = request.queryStringParameters?["latitude"],
           let longitude = request.queryStringParameters?["longitude"],
           let coordinates = Coordinates(latitudeString: latitude, longitudeString: longitude){
            let margin = Double((request.queryStringParameters?["margin"]) ?? "") ?? 0.5
            do {
                result = try query(located: coordinates, with: margin)
            }catch {
                throw error
            }
        }else if let address = request.queryStringParameters?["address"] {
            do{
                result = try query(contain: address)
            }catch {
                throw error
            }
        }else {
            throw MySQLError.invaildRequest("\(request.rawQueryString)")
        }
        var stations = [EVStation]()
        result.forEach{
            if let parsed = try? $0.decode(model: EVStation.self){
                stations.append(parsed)
            }
        }
        return stations
    }
    enum Tables: String {
        case allChargers
        case chargerStatus
    }
}

enum MySQLError: Error {
    case failToFindDB
    case invaildRequest(String)
    case decodingError
    case failToQueryDB(String)
}
