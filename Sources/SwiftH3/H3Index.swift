import Ch3

/// Represents an index in H3
public struct H3Index {

    private static let invalidIndex = 0

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
        string.withCString { ptr in
            // TODO: do sth with return code of `stringToH3`
            stringToH3(ptr, &value)
        }
        self.value = value
    }

}

// MARK: Properties

extension H3Index {

    /// The resolution of the index
    public var resolution: Int {
        return Int(getResolution(value))
    }

    /// Indicates whether this is a valid H3 index
    public var isValid: Bool {
        return isValidCell(value) == 1
    }

    /// The coordinate that this index represents
    public var latLngRads: LatLng {
        let memory = UnsafeMutablePointer<LatLng>.allocate(capacity: 1)
        defer { memory.deallocate() }
        cellToLatLng(value, memory)
        return memory.pointee
    }
    
    public var latLng: H3LatLng {
        let latLng = self.latLngRads
        return H3LatLng(lat: radsToDegs(latLng.lat), lng: radsToDegs(latLng.lng))
    }
    
}

// MARK: Traversal

extension H3Index {

    /**
     Returns the indices that are `ringK` "rings" from the index.

     - Parameters:
        - ringK: The numbers of rings to expand to
     - Returns: A list of indices. Can be empty.
     */
    public func kRingIndices(ringK: Int32) -> [H3Index] {
        let maxGridSizeMem = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { maxGridSizeMem.deallocate() }
        guard maxGridDiskSize(ringK, maxGridSizeMem) == 0 else {
            return []
        }
        var maxGridSize = maxGridSizeMem.pointee

        var indices = [UInt64](repeating: 0, count: Int(maxGridSize))
        indices.withUnsafeMutableBufferPointer { ptr in
            gridDisk(value, ringK, ptr.baseAddress)
        }
        return indices.map { H3Index($0) }
    }

}

// MARK: Hierarchy

extension H3Index {

    /// The index that is one resolution lower than the index.
    /// Can be nil if invalid.
    public var directParent: H3Index? {
        return parent(at: resolution - 1)
    }

    /// The index that is one resolution higher than the index.
    /// Can be nil if invalid.
    public var directCenterChild: H3Index? {
        return centerChild(at: resolution + 1)
    }

    /// The index for the parent at the resolution `resolution`.
    ///
    /// - Parameter resolution: The resolution for the parent
    /// - Returns: The parent index at that resolution.
    ///            Can be nil if invalid
    public func parent(at resolution: Int) -> H3Index? {
        let memory = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { memory.deallocate() }
        guard cellToParent(value, Int32(resolution), memory) == 0 else {
            return nil
        }
        let val = memory.pointee
        return val == H3Index.invalidIndex ? nil : H3Index(val)
    }

    /// The index for the parent at the resolution `resolution`.
    ///
    /// - Parameter resolution: The resolution for the parent
    /// - Returns: The parent index at that resolution.
    ///            Can be nil if invalid
    public func children(at resolution: Int) -> [H3Index] {
        let childrenSizeMemory = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { childrenSizeMemory.deallocate() }
        guard cellToChildrenSize(value, Int32(resolution), childrenSizeMemory) == 0 else {
            return []
        }
        let childrenSize = childrenSizeMemory.pointee
        
        var children = [UInt64](
            repeating: 0,
            count: Int(childrenSize)
        )
        children.withUnsafeMutableBufferPointer { ptr in
            cellToChildren(value, Int32(resolution), ptr.baseAddress)
        }
        return children
            .filter { $0 != 0 }
            .map { H3Index($0) }
    }

    /// The index for the child directly below the current index
    /// at the resolution `resolution`.
    ///
    /// - Parameter resolution: The resolution for the parent
    /// - Returns: The center child index at that resolution.
    ///            Can be nil if invalid
    public func centerChild(at resolution: Int) -> H3Index? {
        let memory = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { memory.deallocate() }
        guard cellToCenterChild(value, Int32(resolution), memory) == 0 else {
            return nil
        }
        
        let index = memory.pointee
        return index == H3Index.invalidIndex ? nil : H3Index(index)
    }
}

// MARK: Vertexes

extension H3Index {
    public var vertexes: [H3Vertex] {
        var vertexes = [UInt64](
            repeating: 0,
            count: 6
        )
        vertexes.withUnsafeMutableBufferPointer { ptr in
            cellToVertexes(value, ptr.baseAddress)
        }
        return vertexes.map { H3Vertex($0) }
    }
}

extension H3Index: CustomStringConvertible {

    /// String description of the index
    public var description: String {
        let cString = strdup("")
        h3ToString(value, cString, 17)
        return String(cString: cString!)
    }

}

extension H3Index: Equatable, Hashable {}
