import FluentKit
import WKCodable
import Foundation

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
        // Universal decoder from json / wkb
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            self.init(longitude: latitude, latitude: longitude)
        } catch {
            let value = try decoder.singleValueContainer().decode(Data.self)
            let decoder = WKBDecoder()
            let geometry: GeometryType = try decoder.decode(from: value)
            self.init(geometry: geometry)
        }
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
