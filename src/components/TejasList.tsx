import * as React from 'react';
import {
  StyleSheet,
  processColor,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { TejasListHostView } from '../native/TejasListHostView';
import type { TejasListProps, TejasListMethods } from '../spec/TejasList.nitro';

type PublicTejasListProps = Omit<
  TejasListProps,
  'itemStyle' | 'onVisibleRangeChange'
> & {
  style?: StyleProp<ViewStyle>;
  itemStyle?: StyleProp<ViewStyle>;
  onVisibleRangeChange?: (start: number, end: number) => void;
};

/**
 * Strict numeric normalizer.
 */
function toNumber(v: unknown): number {
  return typeof v === 'number' ? v : 0;
}

/**
 * Strict color normalizer.
 * processColor runtime → number | null
 */
function toColor(v: unknown): number | null {
  const c = processColor(v as any);
  return typeof c === 'number' ? c : null;
}

/**
 * RN style → Nitro-safe ItemStyle
 */
function resolveItemStyle(style?: StyleProp<ViewStyle>) {
  if (!style) return undefined;

  const flat = StyleSheet.flatten(style);
  if (!flat) return undefined;

  return {
    padding: toNumber(flat.padding),
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

  const visibleRangeCallback = React.useMemo(() => {
    if (!onVisibleRangeChange) return undefined;
    return { f: onVisibleRangeChange };
  }, [onVisibleRangeChange]);

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
      {...nativeProps}
      style={style}
      itemStyle={resolvedItemStyle}
      hybridRef={hybridRef}
      onVisibleRangeChange={visibleRangeCallback}
    />
  );
});
