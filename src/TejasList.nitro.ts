import type {
  HybridView,
  HybridViewProps,
  HybridViewMethods,
} from 'react-native-nitro-modules';

export interface TejasListProps extends HybridViewProps {
  itemCount: number;
  estimatedItemHeight: number;
  onVisibleRangeChange?: (start: number, end: number) => void;
}

export interface TejasListMethods extends HybridViewMethods {
  scrollToIndex(index: number, animated: boolean): void;
}

export type TejasList = HybridView<TejasListProps, TejasListMethods>;
