import * as React from 'react';
import {
  StyleSheet,
  processColor,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { TejasListHostView } from '../native/TejasListHostView';
import type { TejasListProps, TejasListMethods } from '../spec/TejasList.nitro';

/**
 * Public props exposed to users.
 *
 * - `itemStyle` is a React Native style (ViewStyle)
 * - internally converted to Nitro-safe ItemStyle
 */
type PublicTejasListProps = Omit<
  TejasListProps,
  'itemStyle' | 'onVisibleRangeChange'
> & {
  style?: StyleProp<ViewStyle>;
  itemStyle?: StyleProp<ViewStyle>;
  onVisibleRangeChange?: (start: number, end: number) => void;
};

function toNumber(value: unknown): number {
  return typeof value === 'number' ? value : 0;
}

function toColor(value: unknown): number | null {
  const c = processColor(value as any);
  return typeof c === 'number' ? c : null;
}

/**
 * RN ViewStyle → Nitro-safe ItemStyle
 * (visual-only, no layout semantics)
 */
function resolveItemStyle(style?: StyleProp<ViewStyle>) {
  if (!style) return undefined;

  const flat = StyleSheet.flatten(style);
  if (!flat) return undefined;

  return {
    paddingHorizontal: toNumber(flat.paddingHorizontal),
    paddingVertical: toNumber(flat.paddingVertical),
    backgroundColor: toColor(flat.backgroundColor),
    borderRadius: toNumber(flat.borderRadius),
    borderWidth: toNumber(flat.borderWidth),
    borderColor: toColor(flat.borderColor),
  };
}

export const TejasList = React.forwardRef<
  TejasListMethods,
  PublicTejasListProps
>(function TejasList(props, forwardedRef) {
  const { style, itemStyle, onVisibleRangeChange, ...nativeProps } = props;

  const resolvedItemStyle = React.useMemo(
    () => resolveItemStyle(itemStyle),
    [itemStyle]
  );

  /**
   * Visible range callback is event-style → wrapped
   */
  const visibleRangeCallback = React.useMemo(() => {
    if (!onVisibleRangeChange) return undefined;
    return { f: onVisibleRangeChange };
  }, [onVisibleRangeChange]);

  /**
   * Forward hybrid ref
   */
  const hybridRef = React.useMemo(() => {
    if (!forwardedRef) return undefined;

    return {
      f(instance: TejasListMethods | null) {
        if (typeof forwardedRef === 'function') {
          forwardedRef(instance);
        } else {
          forwardedRef.current = instance;
        }
      },
    };
  }, [forwardedRef]);

  return (
    <TejasListHostView
      {...nativeProps} // includes itemString
      style={style}
      itemStyle={resolvedItemStyle}
      hybridRef={hybridRef}
      onVisibleRangeChange={visibleRangeCallback}
    />
  );
});
