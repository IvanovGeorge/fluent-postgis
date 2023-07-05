import FluentKit
import WKCodable

public struct GeographicPoint2D: Codable, Equatable, CustomStringConvertible {
    /// The point's x coordinate.
    public var longitude: Double

    /// The point's y coordinate.
    public var latitude: Double
    
    /// Coding keys
     private enum CodingKeys: CodingKey {
        case longitude, latitude
    }

    /// Create a new `GISGeographicPoint2D` from json
    public init(from decoder: Decoder) throws {
        // Person.init(from:) is being used here!
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(longitude: latitude, latitude: longitude)
    }

    /// Create a new `GISGeographicPoint2D`
    public init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}

extension GeographicPoint2D: GeometryConvertible, GeometryCollectable {
    /// Convertible type
    public typealias GeometryType = Point

    public init(geometry point: GeometryType) {
        self.init(longitude: point.x, latitude: point.y)
    }

    public var geometry: GeometryType {
        .init(vector: [self.longitude, self.latitude], srid: FluentPostGISSrid)
    }

    public var baseGeometry: Geometry {
        self.geometry
    }
}
