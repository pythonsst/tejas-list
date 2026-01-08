import { SafeAreaView, StyleSheet } from 'react-native';
import { TejasList } from 'react-native-tejas-list';

const ITEM_COUNT = 10_000;
const ESTIMATED_ITEM_HEIGHT = 84;

export default function TejasListApp() {
  return (
    <SafeAreaView style={styles.container}>
      <TejasList
        itemCount={ITEM_COUNT}
        estimatedItemHeight={ESTIMATED_ITEM_HEIGHT}
        rowSpacing={16}
        style={styles.list}
        itemStyle={styles.item}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,

    // iOS grouped background
    backgroundColor: '#F2F2F7',
  },

  list: {
    flex: 1,
    paddingHorizontal: 12,
    paddingTop: 8,
  },

  /**
   * Visual-only row style
   * (SAFE for TejasList layout engine)
   */
  item: {
    paddingHorizontal: 18,
    paddingVertical: 16,

    backgroundColor: '#FFFFFF',
    borderRadius: 20,

    // subtle definition without shadows
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D1D6',
  },
});
