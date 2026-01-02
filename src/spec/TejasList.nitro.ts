import type {
  HybridView,
  HybridViewProps,
  HybridViewMethods,
} from 'react-native-nitro-modules';

export type ScrollDirection = 'vertical' | 'horizontal';

export interface TejasListProps extends HybridViewProps {
  /**
   * Total number of items in the list.
   * Must be stable across renders.
   */
  itemCount: number;

  /**
   * Estimated height of a single item (used by native layout).
   */
  estimatedItemHeight: number;

  scrollDirection?: ScrollDirection;

  /**
   * Native-driven visible range callback.
   * Wrapped on the JS side.
   */
  onVisibleRangeChange?: (start: number, end: number) => void;
}

export interface TejasListMethods extends HybridViewMethods {
  /**
   * Scroll to a specific index.
   */
  scrollToIndex(index: number, animated: boolean): void;
}

/**
 * Hybrid view contract (native ↔ JS).
 */
export type TejasList = HybridView<TejasListProps, TejasListMethods>;
