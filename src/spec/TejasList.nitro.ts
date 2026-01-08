import type {
  HybridView,
  HybridViewProps,
  HybridViewMethods,
} from 'react-native-nitro-modules';

export type ScrollDirection = 'vertical' | 'horizontal';

/**
 * Visual-only style applied to each item.
 * Must NOT affect layout.
 */
export interface ItemStyle {
  padding: number;
  paddingHorizontal: number;
  paddingVertical: number;

  backgroundColor: number | null;
  borderRadius: number;

  borderWidth: number;
  borderColor: number | null;
}

export interface TejasListProps extends HybridViewProps {
  itemCount: number;
  estimatedItemHeight: number;
  scrollDirection?: ScrollDirection;

  itemStyle?: ItemStyle;

  onVisibleRangeChange?: (start: number, end: number) => void;
}

export interface TejasListMethods extends HybridViewMethods {
  scrollToIndex(index: number, animated: boolean): void;
}

export type TejasList = HybridView<TejasListProps, TejasListMethods>;
