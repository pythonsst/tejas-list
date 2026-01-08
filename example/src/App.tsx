import * as React from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';

import { TejasList } from 'react-native-tejas-list';

const ITEM_COUNT = 10_000;
const ESTIMATED_ITEM_HEIGHT = 80;

const App: React.FC = () => {
  /**
   * This callback is NOT on the hot path.
   * Native calls it only when visible range changes.
   */
  const handleVisibleRangeChange = React.useCallback(
    (_start: number, _end: number): void => {
      // console.log('visible range:', _start, _end);
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
        /** 👇 THIS IS THE IMPORTANT PART */
        itemStyle={styles.item}
      />
    </SafeAreaView>
  );
};

export default App;
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7', // iOS grouped background
  },

  list: {
    flex: 1,
  },

  /**
   * Applied to EACH item container
   * (visual only, does not affect layout math)
   */
  item: {
    paddingHorizontal: 16,
    paddingVertical: 12,

    // ARGB: 0xAARRGGBB
    backgroundColor: 0xffffffff, // pure white card
    borderRadius: 14,

    borderWidth: 1,
    borderColor: 0xffe5e5ea, // subtle iOS separator gray
  },
});
