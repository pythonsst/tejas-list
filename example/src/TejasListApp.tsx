import { SafeAreaView, StyleSheet, Text, View } from 'react-native';
import { TejasList } from 'react-native-tejas-list';

const ITEM_COUNT = 10_000;
const ESTIMATED_ITEM_HEIGHT = 84;

export default function TejasListApp() {
  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>TejasList</Text>
        <Text style={styles.headerSubtitle}>Deterministic native list</Text>
      </View>

      {/* List */}
      <TejasList
        itemCount={ITEM_COUNT}
        estimatedItemHeight={ESTIMATED_ITEM_HEIGHT}
        rowSpacing={16}
        itemString="Row"
        style={styles.list}
        itemStyle={styles.item}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },

  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#D1D1D6',
    backgroundColor: '#F2F2F7',
  },

  headerTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: '#000000',
  },

  headerSubtitle: {
    marginTop: 2,
    fontSize: 13,
    color: '#6D6D72',
  },

  list: {
    flex: 1,
    paddingHorizontal: 12,
    paddingTop: 8,
  },

  item: {
    paddingHorizontal: 18,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D1D6',
  },
});
