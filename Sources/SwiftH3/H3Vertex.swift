import Ch3
import Darwin

public struct H3Vertex {
    private var value: UInt64
    
    /**
     Initializes using a 64-bit integer
     
     - Parameter value: 64-bit integer representing index
     */
    public init(_ value: UInt64) {
        self.value = value
    }
    
    /**
     Initializes using the string representation of an index.
     For example: "842a107ffffffff"
     
     - Parameter string: The string representing the hex value of the int
     */
    public init(string: String) {
        var value: UInt64 = 0
        let _ = string.withCString { ptr in
            // TODO: do sth with return code of `stringToH3`
            stringToH3(ptr, &value)
        }
        self.value = value
    }
}

extension H3Vertex {
    public var latLngRads: LatLng {
        let memory = UnsafeMutablePointer<LatLng>.allocate(capacity: 1)
        defer { memory.deallocate() }
        vertexToLatLng(value, memory)
        return memory.pointee
    }
    
    public var latLng: H3LatLng {
        let latLng = self.latLngRads
        return H3LatLng(lat: radsToDegs(latLng.lat), lng: radsToDegs(latLng.lng))
    }

}


extension H3Vertex: CustomStringConvertible {
    /// String description of the index
    public var description: String {
        let cString = strdup("")
        h3ToString(value, cString, 17)
        return String(cString: cString!)
    }
}

extension H3Vertex: Equatable, Hashable {}

