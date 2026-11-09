import Store
import Testing
import Tree

@Suite
struct `Tree.Position Tests` {

    @Test
    func `position token keeps a generation beyond the 32-bit range`() {
        let tree = Tree<Int>()
        let wrapped = Int(UInt32.max) + 2
        let position = tree._position(of: Store.Generational.Handle(index: 0, generation: wrapped))
        #expect(position.token == wrapped)
        #expect(position != tree._position(of: Store.Generational.Handle(index: 0, generation: 1)))
    }

    @Test
    func `stale position whose generation differs by 2^32 is not live`() throws {
        var tree = Tree<Int>()
        let root = try tree.insert(7, at: .root)
        let stale = __TreePosition(index: root.index, token: root.token + Int(UInt32.max) + 1)
        #expect(tree.peek(at: stale) == nil)
        #expect(tree.peek(at: root) == 7)
    }
}
