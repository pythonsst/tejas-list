import { SafeAreaView, StyleSheet, View, Text } from 'react-native';
import { FlashList } from '@shopify/flash-list';

const ITEM_COUNT = 10_000;
const ESTIMATED_ITEM_HEIGHT = 84;

const data = Array.from({ length: ITEM_COUNT }, (_, i) => i);

export default function FlashListApp() {
  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>FlashList</Text>
        <Text style={styles.headerSubtitle}>10,000 rows</Text>
      </View>

      {/* List */}
      <FlashList
        style={styles.listContainer}
        data={data}
        estimatedItemSize={ESTIMATED_ITEM_HEIGHT}
        keyExtractor={(item) => String(item)}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <View style={styles.row}>
            <View style={styles.item}>
              <Text style={styles.text}>Row {item + 1}</Text>
            </View>
          </View>
        )}
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
    paddingTop: 6,
    paddingBottom: 10,
    alignItems: 'center',
    backgroundColor: '#F9F9FB',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#D1D1D6',
  },

  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000',
    letterSpacing: -0.2,
  },

  headerSubtitle: {
    marginTop: 2,
    fontSize: 12,
    color: '#6E6E73',
  },

  listContainer: {
    flex: 1,
  },

  list: {
    paddingHorizontal: 12,
    paddingTop: 8,
  },

  row: {
    marginBottom: 16,
  },

  item: {
    paddingHorizontal: 18,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D1D6',
  },

  text: {
    fontSize: 15,
    fontWeight: '500',
    color: '#000',
  },
});
