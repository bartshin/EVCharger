
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
    func useDefaultDB() throws {
        do {
            _ =  try mysql.withConnection{ conn in
                return conn.simpleQuery("USE \(self.defaultDatabase)")
            }
            .wait()
        } catch {
            throw MySQLError.failToFindDB
        }
    }
    private func query(located coordinates: Coordinates , with margin: Double, by maxLimit: Int = 100) -> [SQLRow] {
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
            print(error.localizedDescription)
            return []
        }
    }
    private func query(contain address: String, by maxLimit: Int = 100) -> [SQLRow] {
        do
        {
            return try sql.select().columns(SQLLiteral.all)
                .from("allChargers")
                .where("address", .like, "%\(address)%")
                .limit(maxLimit)
                .all().wait()
        }catch {
            print(error.localizedDescription)
            return []
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
            result = query(located: coordinates, with: margin)
        }else if let address = request.queryStringParameters?["address"] {
            result = query(contain: address)
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
}

enum MySQLError: Error {
    case failToFindDB
    case invaildRequest(String)
    case decodingError
}
