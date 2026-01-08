import type {
  HybridView,
  HybridViewProps,
  HybridViewMethods,
} from 'react-native-nitro-modules';

export type ScrollDirection = 'vertical' | 'horizontal';

/**
 * Visual-only style applied to each item.
 * Must NOT affect list-level layout math.
 */
export interface ItemStyle {
  paddingHorizontal?: number;
  paddingVertical?: number;

  backgroundColor?: number | null; // ARGB
  borderRadius?: number;

  borderWidth?: number;
  borderColor?: number | null;
}

/**
 * TejasList props (Nitro-safe)
 */
export interface TejasListProps extends HybridViewProps {
  /** Total number of items */
  itemCount: number;

  /** Estimated size along scroll axis */
  estimatedItemHeight: number;

  /** Scroll direction (default: vertical) */
  scrollDirection?: ScrollDirection;

  /** Deterministic spacing */
  rowSpacing?: number;
  columnSpacing?: number;

  /** Visual-only per-item style */
  itemStyle?: ItemStyle;

  /**
   * Static row label prefix.
   * Example: "Row"
   */
  itemString?: string;

  /** Visible range callback */
  onVisibleRangeChange?: (start: number, end: number) => void;
}

export interface TejasListMethods extends HybridViewMethods {
  scrollToIndex(index: number, animated: boolean): void;
}

export type TejasList = HybridView<TejasListProps, TejasListMethods>;
