import Foundation
import MySQLKit

// EV Charger API
let apikey:String = ""

// My SQL Config
let hostURL: String = ""
let username: String = ""
let password: String = ""
let port:Int = 3306
let defaultDB:String = ""

let mySQLHandler = MySQLHandler(host: hostURL,
                                port: port,
                                username: username,
                                password: password,
                                defaultDB: defaultDB)


var parser = APIParser(apiKey: apikey)
let startPage = 4

func fetchData(index: Int) {
    parser.pageNum = index
    let promise = parser.parse()
    promise.observe { result in
        switch result {
        case .success(let stations):
            stations.forEach {
                do {
                    try mySQLHandler.insertStation($0)
                }catch {
                    print(error.localizedDescription)
                }
            }
            fetchData(index: index + 1)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

fetchData(index: startPage)



