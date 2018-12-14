import Async
import Core
import XCTest
import FluentBenchmark
import FluentPostgreSQL
import Fluent
import Foundation
@testable import FluentPostGIS

final class QueryTests: XCTestCase {
    var benchmarker: Benchmarker<PostgreSQLDatabase>!
    var database: PostgreSQLDatabase!
    
    override func setUp() {
        let config: PostgreSQLDatabaseConfig = .init(
            hostname: "localhost",
            port: 5432,
            username: "postgres",
            database: "postgis_tests"
        )
        database = PostgreSQLDatabase(config: config)
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        benchmarker = try! Benchmarker(database, on: eventLoop, onFail: XCTFail)
        let conn = try! benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try! FluentPostgreSQLProvider._setup(on: conn).wait()
        try! FluentPostGISProvider._setup(on: conn).wait()
    }
    
    func testContains() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let testPoint = GISGeometricPoint2D(x: 5, y: 5)
        let all = try UserArea.query(on: conn).filterGeometryContains(\UserArea.area, testPoint).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testContainsReversed() throws {
        struct UserLocation: PostgreSQLModel, Migration {
            var id: Int?
            var location: GISGeometricPoint2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserLocation.prepare(on: conn).wait()
        defer { try! UserLocation.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPoint = GISGeometricPoint2D(x: 5, y: 5)
        var user = UserLocation(id: nil, location: testPoint)
        user = try user.save(on: conn).wait()
        
        let all = try UserLocation.query(on: conn).filterGeometryContains(polygon, \UserLocation.location).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testContainsWithHole() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let hole = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 2.5, y: 2.5),
            GISGeometricPoint2D(x: 7.5, y: 2.5),
            GISGeometricPoint2D(x: 7.5, y: 7.5),
            GISGeometricPoint2D(x: 2.5, y: 7.5),
            GISGeometricPoint2D(x: 2.5, y: 2.5)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing, interiorRings: [hole])
        
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let testPoint = GISGeometricPoint2D(x: 5, y: 5)
        let all = try UserArea.query(on: conn).filterGeometryContains(\UserArea.area, testPoint).all().wait()
        XCTAssertEqual(all.count, 0)
        
        let testPoint2 = GISGeometricPoint2D(x: 1, y: 5)
        let all2 = try UserArea.query(on: conn).filterGeometryContains(\UserArea.area, testPoint2).all().wait()
        XCTAssertEqual(all2.count, 1)
    }
    
    func testCrosses() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 5, y: 5)
            ])
        
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let all = try UserArea.query(on: conn).filterGeometryCrosses(\UserArea.area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testCrossesReversed() throws {
        struct UserLocation: PostgreSQLModel, Migration {
            var id: Int?
            var path: GISGeometricLineString2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserLocation.prepare(on: conn).wait()
        defer { try! UserLocation.revert(on: conn).wait() }

        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 5, y: 5)
            ])

        var user = UserLocation(id: nil, path: testPath)
        user = try user.save(on: conn).wait()
        
        let all = try UserLocation.query(on: conn).filterGeometryCrosses(polygon, \UserLocation.path).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testDisjoint() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 11, y: 5)
            ])
        
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let all = try UserArea.query(on: conn).filterGeometryDisjoint(\UserArea.area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testDisjointReversed() throws {
        struct UserLocation: PostgreSQLModel, Migration {
            var id: Int?
            var path: GISGeometricLineString2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserLocation.prepare(on: conn).wait()
        defer { try! UserLocation.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 11, y: 5)
            ])
        
        var user = UserLocation(id: nil, path: testPath)
        user = try user.save(on: conn).wait()
        
        let all = try UserLocation.query(on: conn).filterGeometryDisjoint(polygon, \UserLocation.path).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testEquals() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
                
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let all = try UserArea.query(on: conn).filterGeometryEquals(\UserArea.area, polygon).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testIntersects() throws {
        struct UserArea: PostgreSQLModel, Migration {
            var id: Int?
            var area: GISGeometricPolygon2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserArea.prepare(on: conn).wait()
        defer { try! UserArea.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 5, y: 5)
            ])
        
        var user = UserArea(id: nil, area: polygon)
        user = try user.save(on: conn).wait()
        
        let all = try UserArea.query(on: conn).filterGeometryIntersects(\UserArea.area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testIntersectsReversed() throws {
        struct UserLocation: PostgreSQLModel, Migration {
            var id: Int?
            var path: GISGeometricLineString2D
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        conn.logger = DatabaseLogger(database: .psql, handler: PrintLogHandler())
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try UserLocation.prepare(on: conn).wait()
        defer { try! UserLocation.revert(on: conn).wait() }
        
        let exteriorRing = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 0, y: 0),
            GISGeometricPoint2D(x: 10, y: 0),
            GISGeometricPoint2D(x: 10, y: 10),
            GISGeometricPoint2D(x: 0, y: 10),
            GISGeometricPoint2D(x: 0, y: 0)])
        let polygon = GISGeometricPolygon2D(exteriorRing: exteriorRing)
        
        let testPath = GISGeometricLineString2D(points: [
            GISGeometricPoint2D(x: 15, y: 0),
            GISGeometricPoint2D(x: 5, y: 5)
            ])
        
        var user = UserLocation(id: nil, path: testPath)
        user = try user.save(on: conn).wait()
        
        let all = try UserLocation.query(on: conn).filterGeometryIntersects(polygon, \UserLocation.path).all().wait()
        XCTAssertEqual(all.count, 1)
    }
}
