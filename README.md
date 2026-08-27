# Tree

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-molecules/swift-tree/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-molecules/swift-tree/actions/workflows/ci.yml)

A tree generic over its storage **column** — the carrier writes the node-shape-agnostic surface (insert, remove, subtree teardown, traversal, navigation) once against the column seam, and copyability flows from the column rather than from per-tree machinery. The shipped column is `TreeStorage.Dynamic<Element>`, a dense ordered-children arena; `Tree<Element>` names the canonical dynamic tree built on it.

Positions are generational: `Tree.Position` carries a slot index plus a generation token, so a position held across a removal goes *stale* and is rejected — it can never silently resolve to whatever node later reuses the freed slot. Elements may be `~Copyable`; with a `Copyable` element the dynamic tree is copy-on-write, so copies fork lazily and mutate independently.

---

## Key Features

- **Column-generic engine** — one `Tree<S>` type; the shared operations attach by conditional extension on the storage seam, so alternative columns plug in without re-implementing the algorithms.
- **Generational positions** — stale positions throw or return `nil` instead of aliasing a recycled slot; positions survive unrelated growth and in-place element mutation.
- **Noncopyable elements** — borrowing element access via `peek(at:)` closures and in-place mutation via `withElementMut(at:)`, with no requirement that elements be copyable.
- **Copyability from the column** — move-only by default; opt into copy-on-write value semantics simply by storing a `Copyable` element.
- **Read-only fluent views** — `tree.forEach.preOrder { }` / `.postOrder` / `.levelOrder` and `tree.child.at(_:of:)` / `.count(of:)` / `.leftmost(of:)` / `.rightmost(of:)`, callable on a `let` or borrowed tree.
- **Typed throws end-to-end** — every failing operation throws `Tree.Error`; consumers can match exhaustively without `any Error`.

---

## Quick Start

```swift
import Tree

var tree = Tree<String>()
let root = try tree.insert("root", at: .root)
let draft = try tree.insert("draft", at: .child(of: root, at: 0))
_ = try tree.insert("published", at: .child(of: root, at: 1))

var visited: [String] = []
tree.forEach.preOrder { visited.append($0) }    // ["root", "draft", "published"]

// Positions are generational: removal invalidates the position rather than
// letting it alias whatever node reuses the freed slot.
try tree.remove(at: draft)
let recovered = tree.peek(at: draft)            // nil — stale position rejected
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-molecules/swift-tree.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Tree", package: "swift-tree")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | When to import |
|---------|----------------|
| `Tree` | Umbrella — the ADT, positions and errors, the dynamic column, and the traversal / navigation views |
| `Tree Primitive` | The bare column-generic carrier value type, zero dependencies — column authors and minimal consumers |
| `Tree Index` | `Tree.Position`, `Tree.Error`, insert positions, and the storage / consumer seam protocols — writing code generic over tree-like storage |
| `Tree Storage` | The dynamic column (`TreeStorage.Dynamic`) and the canonical `Tree<Element>` front door, without the operations surface |
| `Tree Operations` | The shared algorithm engine and the `forEach` / `child` views |
| `Tree Test Support` | Test utilities for targets exercising tree code |

---

## Error Handling

Every throwing operation throws `Tree.Error`:

```
Tree.Error
├── .invalidPosition        // The position is stale or out of bounds
├── .rootOccupied           // Root insert attempted on a non-empty tree
├── .slotOccupied           // A child slot is already occupied (bounded-arity / keyed columns)
├── .childIndexOutOfBounds  // Child index above the parent's current child count (dynamic column)
└── .cannotRemoveNonLeaf    // remove(at:) on an interior node — use removeSubtree(at:)
```

Typed throws make exhaustive handling checkable:

```swift
do {
    try tree.insert(item, at: .child(of: parent, at: 3))
} catch .invalidPosition {
    // `parent` went stale — its node was removed
} catch .rootOccupied, .slotOccupied {
    // The insert target is already filled
} catch .childIndexOutOfBounds {
    // Dynamic column: the index must be at most the current child count
} catch .cannotRemoveNonLeaf {
    // Raised by remove(at:), not insert — removeSubtree(at:) tears down interior nodes
}
```

---

## Platform Support

| Platform                  | CI  | Status    |
|---------------------------|-----|-----------|
| macOS 26                  | Yes | Full support |
| Linux                     | Yes | Supported |
| Windows                   | Yes | Supported |
| iOS/tvOS/watchOS/visionOS | —   | Supported |
| Swift Embedded            | —   | Untested  |

---

## Related Packages

### Dependencies

- [`swift-index`](https://github.com/swift-molecules/swift-index) — the typed index / count vocabulary behind positions and node counts.
- [`swift-storage-generational`](https://github.com/swift-molecules/swift-storage-generational) — the generational handles that make stale positions detectable.
- [`swift-storage`](https://github.com/swift-molecules/swift-storage) — the store vocabulary the arena is expressed in.
- [`swift-column`](https://github.com/swift-molecules/swift-column) — the storage-column vocabulary the arena composes.
- [`swift-ownership-shared`](https://github.com/swift-molecules/swift-ownership-shared) — the copy-on-write box behind the copyable tree.
- [`swift-property`](https://github.com/swift-molecules/swift-property) — the borrowing accessor mechanism behind the `forEach` / `child` views.
- [`swift-stack`](https://github.com/swift-molecules/swift-stack), [`swift-queue`](https://github.com/swift-molecules/swift-queue), [`swift-buffer-ring`](https://github.com/swift-molecules/swift-buffer-ring) — the work-list containers driving the iterative traversals.

### Variants

- swift-tree-n (private, unreleased) — the bounded-arity column over the same seam.
- swift-tree-keyed (private, unreleased) — the keyed (children-by-key) column over the same seam.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
