import * as React from 'react';
import type { StyleProp, ViewStyle } from 'react-native';

import { TejasListView } from './TejasListView';
import type { TejasListProps, TejasListMethods } from './TejasList.nitro';

/**
 * Public props (what users write)
 */
type PublicTejasListProps = Omit<TejasListProps, 'onVisibleRangeChange'> & {
  style?: StyleProp<ViewStyle>;
  onVisibleRangeChange?: (start: number, end: number) => void;
};

export const TejasList = React.forwardRef<
  TejasListMethods,
  PublicTejasListProps
>(function TejasList(props, forwardedRef) {
  const { style, onVisibleRangeChange, ...nativeProps } = props;

  // ✅ Wrap Nitro callback
  const visibleRangeCallback = React.useMemo(() => {
    if (!onVisibleRangeChange) {
      return undefined;
    }
    return { f: onVisibleRangeChange };
  }, [onVisibleRangeChange]);

  // ✅ Wrap Nitro hybridRef
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
    <TejasListView
      {...nativeProps}
      style={style}
      hybridRef={hybridRef}
      onVisibleRangeChange={visibleRangeCallback}
    />
  );
});
