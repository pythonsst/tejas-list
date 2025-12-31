import type {
  HybridView,
  HybridViewMethods,
  HybridViewProps,
} from 'react-native-nitro-modules';

export interface TejasListProps extends HybridViewProps {
  color: string;
}
export interface TejasListMethods extends HybridViewMethods {}

export type TejasList = HybridView<
  TejasListProps,
  TejasListMethods
>;
