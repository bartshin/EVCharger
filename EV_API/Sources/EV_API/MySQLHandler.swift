//
//  MySQLHandler.swift
//  EV_API
//
//  Created by Shin on 3/11/21.
//

import Foundation
import MySQLKit
import NIO

class MySQLHandler: NSObject {
    
    // MYSQL sever config
    let defaultDB: String
    let configuration: MySQLConfiguration
    var eventLoopGroup: EventLoopGroup!
    var pools: EventLoopGroupConnectionPool<MySQLConnectionSource>!
    
    var sql: SQLDatabase {
        self.mysql.sql()
    }
    var mysql: MySQLDatabase {
        self.pools.database(logger: .init(label: "mysql logger"))
    }
    func getLastUpdated(of dbName: String) -> Date?{
        defer {
            changeDB(to: defaultDB)
        }
        do {
            changeDB(to: "mysql")
            let result = try sql.select().column("last_update")
                .from("innodb_table_stats")
                .where("table_name", .equal, dbName)
                .all().wait()
            return try result.first?.decode(column: "last_update", as: Date.self)
        }catch {
            print(error.localizedDescription)
            return nil
        }
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
    func insertStation(_ station: EVStation) throws {
        try sql.insert(into: Tables.allChargers.rawValue)
            .model(station)
            .run().wait()
    }
    
    init(host: String, port: Int, username: String, password: String, defaultDB: String) {
        self.defaultDB = defaultDB
        self.configuration = MySQLConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: defaultDB,
            tlsConfiguration: nil)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.pools = .init(
            source: .init(configuration: configuration),
            maxConnectionsPerEventLoop: 1,
            requestTimeout: .seconds(30),
            logger: .init(label: "pool logger"),
            on: eventLoopGroup)
    }
    
    enum Tables: String {
        case allChargers
        case chargerStatus
    }
}
