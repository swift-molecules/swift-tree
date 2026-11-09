public import Index

public struct __TreePosition: Sendable, Equatable, Hashable {

    public let index: Index<Self>

    public let token: Int

    @inlinable
    internal init(index: Index<Self>, token: Int) {
        self.index = index
        self.token = token
    }

    @inlinable
    public init<T: ~Copyable & ~Escapable>(index: Index<T>, token: Int) {
        self.init(index: index.retag(Self.self), token: token)
    }

    @inlinable
    internal init(index: Int, token: Int) {
        self.init(
            index: Index<Self>(Ordinal(UInt(index))),
            token: token
        )
    }
}

extension __Tree where S: ~Copyable {

    public typealias Position = __TreePosition
}
