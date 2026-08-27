public import Index
public import Tree_Primitive

extension __Tree where S: ~Copyable {

    public typealias Index<Tag: ~Copyable & ~Escapable> = Index.Index<Tag>
}
