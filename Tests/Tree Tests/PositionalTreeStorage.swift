import Index
import Memory
import Memory_Allocator
import Memory_Allocator_Pool
import Memory_Pool
import Ownership_Shared_Primitive
import Storage
import Store
import Tree

struct PositionalTreeNode<Element: ~Copyable, ChildLinks>: ~Copyable {

    var element: Element

    var links: ChildLinks

    var parentHandle: Store::Store.Generational.Handle?
    init(
        element: consuming Element,
        links: consuming ChildLinks,
        parentHandle: Store::Store.Generational.Handle?
    ) {
        self.element = element
        self.links = links
        self.parentHandle = parentHandle
    }
}

extension PositionalTreeNode: Copyable where Element: Copyable, ChildLinks: Copyable {}

extension PositionalTreeNode: Sendable where Element: Sendable, ChildLinks: Sendable {}

struct PositionalTreeArena<Element: ~Copyable, ChildLinks>: ~Copyable {
    typealias Slot = PositionalTreeNode<Element, ChildLinks>
    var _column: Ownership.Shared<Slot, Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Slot>>
    var rootHandle: Store::Store.Generational.Handle?
    init() {
        self._column = Ownership.Shared(Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Slot>.create(slotCapacity: 1))
        self.rootHandle = nil
    }
    init() where Element: Copyable, ChildLinks: Copyable {
        self._column = Ownership.Shared(Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Slot>.create(slotCapacity: 1))
        self.rootHandle = nil
    }
    init(minimumCapacity: Index<Element>.Count) {
        let slots = Index<Slot>.Count(UInt(Swift.max(Int(bitPattern: minimumCapacity), 1)))
        self._column = Ownership.Shared(Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Slot>.create(slotCapacity: slots))
        self.rootHandle = nil
    }
    init(minimumCapacity: Index<Element>.Count)
    where Element: Copyable, ChildLinks: Copyable {
        let slots = Index<Slot>.Count(UInt(Swift.max(Int(bitPattern: minimumCapacity), 1)))
        self._column = Ownership.Shared(Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Slot>.create(slotCapacity: slots))
        self.rootHandle = nil
    }
    var count: Index<Element>.Count {
        Index<Element>.Count(UInt(Int(bitPattern: _column.withColumn { $0.count })))
    }
    func liveHandle(_ position: __TreePosition) -> Store::Store.Generational.Handle? {
        let slot = Int(bitPattern: position.index)
        guard
            slot >= 0,
            let handle = _column.withColumn({ $0.handle(at: Index<Slot>(Ordinal(UInt(slot)))) }),
            UInt32(truncatingIfNeeded: handle.generation) == position.token
        else { return nil }
        return handle
    }
    mutating func insertNode(
        _ element: consuming Element,
        links: consuming ChildLinks,
        parent: Store::Store.Generational.Handle?
    ) -> Store::Store.Generational.Handle {
        _column.withUnique(
            consuming: Slot(element: element, links: links, parentHandle: parent)
        ) { column, node -> Store::Store.Generational.Handle in
            if column.count == column.capacity {
                let doubled = Index<Slot>.Count(UInt(2 &* Int(bitPattern: column.capacity)))
                column.grow(to: doubled)
            }
            return column.insert(node)
        }
    }
    mutating func removeNode(_ handle: Store::Store.Generational.Handle) -> Element {
        guard let node = _column.withUnique({ $0.remove(handle) }) else {

            preconditionFailure("PositionalTreeArena: live handle failed to resolve on removal")
        }
        return node.element
    }
    mutating func removeAll() {
        _column.withUnique { $0.removeAll() }
        rootHandle = nil
    }
    func parentHandle(of handle: Store::Store.Generational.Handle) -> Store::Store.Generational.Handle? {
        _column.withColumn { $0[handle].parentHandle }
    }
    func withElement<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (borrowing Element) -> R
    ) -> R {
        _column.withColumn { body($0[handle].element) }
    }
    func withLinks<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (borrowing ChildLinks) -> R
    ) -> R {
        _column.withColumn { body($0[handle].links) }
    }
    mutating func withLinksMut<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (inout ChildLinks) -> R
    ) -> R {
        _column.withUnique { body(&$0[handle].links) }
    }
    mutating func withElementMut<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (inout Element) -> R
    ) -> R {
        _column.withUnique { body(&$0[handle].element) }
    }
}

extension PositionalTreeArena: Copyable where Element: Copyable, ChildLinks: Copyable {}

extension PositionalTreeArena: Sendable where Element: Sendable, ChildLinks: Sendable {}

struct PositionalTreeStorage<Element: ~Copyable>: ~Copyable {
    var _arena: PositionalTreeArena<Element, [Store::Store.Generational.Handle]>
    init() { _arena = PositionalTreeArena<Element, [Store::Store.Generational.Handle]>() }
    init(minimumCapacity: Index<Element>.Count) {
        _arena = PositionalTreeArena<Element, [Store::Store.Generational.Handle]>(
            minimumCapacity: minimumCapacity
        )
    }
    init() where Element: Copyable {
        _arena = PositionalTreeArena<Element, [Store::Store.Generational.Handle]>()
    }
    init(minimumCapacity: Index<Element>.Count) where Element: Copyable {
        _arena = PositionalTreeArena<Element, [Store::Store.Generational.Handle]>(
            minimumCapacity: minimumCapacity
        )
    }
}

extension PositionalTreeStorage where Element: ~Copyable {

    typealias Address = Index<Self>
}

extension PositionalTreeStorage: __TreeStorage where Element: ~Copyable {
    var _count: Index<Element>.Count { _arena.count }
    var _rootHandle: Store::Store.Generational.Handle? {
        get { _arena.rootHandle }
        set { _arena.rootHandle = newValue }
    }
    func _liveHandle(_ position: __TreePosition) -> Store::Store.Generational.Handle? {
        _arena.liveHandle(position)
    }
    mutating func _insertNode(
        _ element: consuming Element,
        parent: Store::Store.Generational.Handle?
    ) -> Store::Store.Generational.Handle {
        _arena.insertNode(element, links: [], parent: parent)
    }
    mutating func _removeNode(_ handle: Store::Store.Generational.Handle) -> Element {
        _arena.removeNode(handle)
    }
    mutating func _removeAll() { _arena.removeAll() }
    func _parentHandle(of handle: Store::Store.Generational.Handle) -> Store::Store.Generational.Handle? {
        _arena.parentHandle(of: handle)
    }
    func _withElement<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (borrowing Element) -> R
    ) -> R {
        _arena.withElement(at: handle, body)
    }
    mutating func _withElementMut<R: ~Copyable>(
        at handle: Store::Store.Generational.Handle,
        _ body: (inout Element) -> R
    ) -> R {
        _arena.withElementMut(at: handle, body)
    }
    func _childHandle(
        at handle: Store::Store.Generational.Handle,
        address index: Index<Self>
    ) -> Store::Store.Generational.Handle? {
        let i = Int(bitPattern: index)
        return _arena.withLinks(at: handle) { (i >= 0 && i < $0.count) ? $0[i] : nil }
    }
    func _validateLink(
        to parent: Store::Store.Generational.Handle,
        at index: Index<Self>
    ) throws(__TreeError) {
        let i = Int(bitPattern: index)
        let childCount = _arena.withLinks(at: parent) { $0.count }
        guard i >= 0, i <= childCount else { throw .childIndexOutOfBounds }
    }
    mutating func _linkChild(
        _ child: Store::Store.Generational.Handle,
        to parent: Store::Store.Generational.Handle,
        at index: Index<Self>
    ) {
        let i = Int(bitPattern: index)
        _arena.withLinksMut(at: parent) { $0.insert(child, at: i) }
    }
    mutating func _unlinkChild(
        _ child: Store::Store.Generational.Handle,
        from parent: Store::Store.Generational.Handle
    ) {
        _arena.withLinksMut(at: parent) {
            if let position = $0.firstIndex(of: child) { $0.remove(at: position) }
        }
    }
    func _childCount(at handle: Store::Store.Generational.Handle) -> Int {
        _arena.withLinks(at: handle) { $0.count }
    }
    func _forEachChild(
        at handle: Store::Store.Generational.Handle,
        _ body: (Store::Store.Generational.Handle) -> Void
    ) {
        _arena.withLinks(at: handle) { links in
            links.indices.forEach { index in body(links[index]) }
        }
    }
}

extension PositionalTreeStorage: Copyable where Element: Copyable {}

extension PositionalTreeStorage: Sendable where Element: Sendable {}

typealias Tree<Element: ~Copyable> = __Tree<PositionalTreeStorage<Element>>

extension __Tree where S: ~Copyable {
    init<Element: ~Copyable>() where S == PositionalTreeStorage<Element> {
        self.init(storage: PositionalTreeStorage<Element>())
    }
    init<Element: ~Copyable>(minimumCapacity: Index::Index<Element>.Count)
    where S == PositionalTreeStorage<Element> {
        self.init(storage: PositionalTreeStorage<Element>(minimumCapacity: minimumCapacity))
    }
    init<Element>() where S == PositionalTreeStorage<Element> {
        self.init(storage: PositionalTreeStorage<Element>())
    }
    init<Element>(minimumCapacity: Index::Index<Element>.Count)
    where S == PositionalTreeStorage<Element> {
        self.init(storage: PositionalTreeStorage<Element>(minimumCapacity: minimumCapacity))
    }
}
