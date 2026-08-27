public import Index

extension __Tree where S: ~Copyable {

    public typealias Index<Tag: ~Copyable & ~Escapable> = Index.Index<Tag>
}
