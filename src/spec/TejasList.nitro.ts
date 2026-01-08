import type {
  HybridView,
  HybridViewProps,
  HybridViewMethods,
} from 'react-native-nitro-modules';

export type ScrollDirection = 'vertical' | 'horizontal';

/**
 * Visual-only style applied to each item.
 * May affect item measurement via padding,
 * but must NOT affect list-level layout math.
 */
export interface ItemStyle {
  /** Internal spacing */
  paddingHorizontal?: number;
  paddingVertical?: number;

  /** Visual-only */
  backgroundColor?: number | null; // ARGB: 0xAARRGGBB
  borderRadius?: number;

  borderWidth?: number;
  borderColor?: number | null;
}

/**
 * TejasList props
 */
export interface TejasListProps extends HybridViewProps {
  /** Total number of items */
  itemCount: number;

  /** Estimated size of an item along the scroll axis */
  estimatedItemHeight: number;

  /** Scroll direction (default: vertical) */
  scrollDirection?: ScrollDirection;

  /** Layout-level spacing (deterministic) */
  rowSpacing?: number; // vertical lists (default: 0)
  columnSpacing?: number; // horizontal lists (default: 0)

  /** Visual-only per-item style */
  itemStyle?: ItemStyle;

  /** Called when visible range changes */
  onVisibleRangeChange?: (start: number, end: number) => void;
}

export interface TejasListMethods extends HybridViewMethods {
  scrollToIndex(index: number, animated: boolean): void;
}

export type TejasList = HybridView<TejasListProps, TejasListMethods>;
