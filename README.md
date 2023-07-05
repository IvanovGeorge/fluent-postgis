# FluentPostGIS

![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OS%20X-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-SwiftPM-yellow.svg)



A fork of the [FluentPostGIS](https://github.com/brokenhandsio/fluent-postgis), with is a for of the original [FluentPostGIS](https://github.com/plarson/fluent-postgis) package which adds support for geographic queries. FluentPostGIS provides PostGIS support for [fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver) and [Vapor 4](https://github.com/vapor/vapor).
Main feature — added initialization from json

Json
```
"location" : {
     "longitude" : 12.694644422012956,
     "latitude" :  12.38693920847816
} 
```

Decoding
```
let location = try req.content.decode(GeographicPoint2D.self)
```

# Installation

## Swift Package Manager

Add this line to your dependencies in `Package.swift`:

```swift
.package(url: "https://github.com/brokenhandsio/fluent-postgis.git", from: "0.3.0")
```

Then add this line to a target's dependencies:

```swift
.product(name: "FluentPostGIS", package: "fluent-postgis"),
```

# Setup

Import module

```swift
import FluentPostGIS
```

Optionally, you can add a `Migration` to enable PostGIS:

```swift
app.migrations.add(EnablePostGISMigration())

```

# Models

Add a type to your model

```swift
final class User: Model {
    static let schema = "user"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "location")
    var location: GeometricPoint2D
}
```

Then use its data type in the `Migration`:

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws -> {
        try await database.schema(User.schema)
            .id()
            .field("location", .geometricPoint2D)
            .create()
    }
    func revert(on database: Database) async throws -> {
        try await database.schema(User.schema).delete()
    }
}
```

| Geometric Types | Geographic Types  |
|---|---|
|GeometricPoint2D|GeographicPoint2D|
|GeometricLineString2D|GeographicLineString2D|
|GeometricPolygon2D|GeographicPolygon2D|
|GeometricMultiPoint2D|GeographicMultiPoint2D|
|GeometricMultiLineString2D|GeographicMultiLineString2D|
|GeometricMultiPolygon2D|GeographicMultiPolygon2D|
|GeometricGeometryCollection2D|GeographicGeometryCollection2D|

# Queries

Query using any of the filter functions:

```swift
let eiffelTower = GeographicPoint2D(longitude: 2.2945, latitude: 48.858222)
try await User.query(on: database)
    .filterGeographyDistanceWithin(\.$location, eiffelTower, 1000)
    .all()
```

| Queries |
|---|
|filterGeometryContains|
|filterGeometryCrosses|
|filterGeometryDisjoint|
|filterGeometryDistance|
|filterGeometryDistanceWithin|
|filterGeographyDistanceWithin|
|filterGeometryEquals|
|filterGeometryIntersects|
|filterGeometryOverlaps|
|filterGeometryTouches|
|filterGeometryWithin|
|sortByDistance|

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
BrokenHands, Tim Condon, Nikolai Guyot - https://www.brokenhands.io/
Ricardo Carvalho - https://rabc.github.io/
Phil Larson - http://dizm.com
