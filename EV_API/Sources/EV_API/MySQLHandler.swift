//
//  MySQLHandler.swift
//  EV_API
//
//  Created by Shin on 3/11/21.
//

import Foundation
import MySQLKit
import NIO
//arn:aws:iam::627914706622:role/service-role/Query_EV_Charger-role-4fpftbzt
class MySQLHandler: NSObject {
    
    // MYSQL sever config
    let defaultDatabase: String
    let configuration: MySQLConfiguration
    var eventLoopGroup: EventLoopGroup!
    var pools: EventLoopGroupConnectionPool<MySQLConnectionSource>!
    
    var sql: SQLDatabase {
        self.mysql.sql()
    }
    var mysql: MySQLDatabase {
        self.pools.database(logger: .init(label: "mysql logger"))
    }
    func setUp() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.pools = .init(
            source: .init(configuration: configuration),
            maxConnectionsPerEventLoop: 1,
            requestTimeout: .seconds(30),
            logger: .init(label: "pool logger"),
            on: eventLoopGroup)
        do {
            _ =  try mysql.withConnection{ conn in
                return conn.simpleQuery("USE \(self.defaultDatabase)")
            }
            .wait()
        } catch {
            print(error)
        }
    }
    func insertStation(_ station: EVStation) throws {
        try mysql.sql().insert(into: "allChargers")
            .model(station)
            .run().wait()
    }
    init(host: String, port: Int, username: String, password: String, databasename: String) {
        defaultDatabase = databasename
        self.configuration = MySQLConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: databasename,
            tlsConfiguration: nil)
    }
}
