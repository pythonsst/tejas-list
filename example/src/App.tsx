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
    (start: number, end: number): void => {
      console.log('visible range:', start, end);
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
      />
    </SafeAreaView>
  );
};

export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  list: {
    flex: 1,
  },
});
