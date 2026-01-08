# react-native-tejas-list

A native-first, deterministic, high-performance list engine for React Native.

TejasList is built for cases where list performance must be **predictable and explainable**, not just fast in the average case. It is designed as a rendering engine, not a heuristic-driven wrapper around existing list components.

---

## What TejasList Is

TejasList is a low-level list infrastructure that:

- Owns scrolling, mounting, recycling, and reuse natively
- Uses a strict and deterministic lifecycle (recycle → mount)
- Keeps memory usage bounded and explicit
- Keeps JavaScript off the hot path

The JavaScript layer is intentionally thin. JS provides configuration and data boundaries, while native code is responsible for layout, recycling, and performance-critical decisions.

---

## Why TejasList Instead of FlashList

FlashList is an excellent general-purpose list, but it optimizes performance primarily through runtime measurement, estimation, and adaptive heuristics. Under heavy load or complex lifecycles, this can make behavior harder to reason about and debug.

TejasList takes a different approach:

- No runtime heuristics or adaptive estimation
- Deterministic mount, recycle, and reuse behavior
- No hidden work during scroll or layout passes
- Bounded allocation and explicit reuse pools
- Performance that remains stable as data size grows

The goal is not to outperform FlashList in simple demos, but to remain predictable and stable in worst-case scenarios.

---

## Architecture Overview

At the native layer, TejasList behaves like a rendering engine:

- Visible ranges are computed natively
- Cells are recycled from a bounded pool
- Updates are applied in two distinct phases
- Mutation never occurs during iteration

JavaScript is notified only when meaningful state changes occur (e.g. visible range changes), not on every scroll frame.

---

## Why Nitro

The native core is built using Nitro Hybrid Views:

- Statically compiled JSI bindings
- Near-zero JS ↔ native overhead
- Strong typing across JS, C++, and Swift/Obj-C
- No runtime reflection or dynamic dispatch

This allows TejasList to expose low-level native primitives safely without compromising performance.

---

## Example

```ts
import * as React from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';
import { TejasList } from 'react-native-tejas-list';

const ITEM_COUNT = 10_000;
const ESTIMATED_ITEM_HEIGHT = 80;

const App = () => {
  const handleVisibleRangeChange = React.useCallback(
    (_start: number, _end: number) => {
      // Called only when visible range changes
    },
    []
  );

  return (
    <SafeAreaView style={styles.container}>
      <TejasList
        itemCount={ITEM_COUNT}
        estimatedItemHeight={ESTIMATED_ITEM_HEIGHT}
        onVisibleRangeChange={handleVisibleRangeChange}
        style={styles.list}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1 },
  list: { flex: 1 },
});
```

This example renders 10,000 items while keeping JavaScript entirely off the scrolling hot path. Native code owns scrolling, layout, and recycling.

---

## Status

- iOS native core: **significantly implemented**
- Deterministic mount / recycle lifecycle
- Focused on correctness, bounded memory, and sustained performance

Android implementation and JS-layer evolution are in progress.

---

## Contributing

TejasList is intentionally low-level and performance-oriented. Contributions are welcome from developers interested in:

- Native rendering systems

- React Native internals

- Large-scale list performance

- Android native implementation

- Documentation and benchmarking

- [Development workflow](CONTRIBUTING.md#development-workflow)

- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)

- [Code of conduct](CODE_OF_CONDUCT.md)

---

## License

MIT

---

Made with create-react-native-library
