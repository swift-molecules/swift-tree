# swift-tree

Use this package when you are writing a new tree storage layout, or code that should work over any tree regardless of its layout. It provides `__Tree<S>`, the shape-independent tree over a storage `S` that conforms to `__TreeStorage`, nodes addressed by `__TreePosition`, and the `Traversable` protocol that the `Property` trait's `child` and `forEach` views are built on. To store values, use a sibling package instead: swift-tree-column for a tree with any number of ordered children per node, swift-tree-n for a tree with a fixed number of child slots per node (binary included), swift-tree-keyed for children addressed by a hashable key. Add new storage layouts under the `TreeStorage` namespace.

## Laws

- A `__TreePosition` is a slot index plus the slot's generation, truncated to 32 bits. It identifies a node only while that node is live: after the node is removed, `validate(_:)` throws and every non-throwing lookup (`peek`, `withElementMut`, `parent(of:)`, `isLeaf`, and the `child` views) returns `nil` (`false` for `isLeaf`) instead of trapping. A `__TreeStorage` conformer must make `_liveHandle(_:)` return `nil` for such a position.
- Insertion at `.root` fails when the tree already has a root. Insertion as a child first rejects a stale parent position, then defers to the storage's `_validateLink(to:at:)`, which decides whether the address is out of bounds or already occupied.
- `remove(at:)` removes only a leaf and fails on a node that has children. `removeSubtree(at:)` detaches the node from its parent, then removes it and every descendant, children before their parent. Removing the root this way empties the tree.
- Traversals visit children in the order the storage's `_forEachChild(at:_:)` yields them, and that order also defines `child.leftmost` (first) and `child.rightmost` (last). Pre-order visits a node and then its children's subtrees; post-order visits every child's subtree and then the node; level-order goes breadth first. Traversal, `height` and `removeSubtree(at:)` use an explicit `Stack` or `Queue`, never recursion, so tree depth does not use up the call stack.
- `height` counts edges: `nil` for an empty tree, 0 for a root with no children.
- Mutating a copy of a `__Tree` never changes the original. This holds only if the storage copies on write; the tests show it for their own test storage.
