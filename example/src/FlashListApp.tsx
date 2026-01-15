// FlashListApp.tsx

import React from 'react';
import { SafeAreaView, StyleSheet, Text, View } from 'react-native';
import { FlashList } from '@shopify/flash-list';

const ITEM_COUNT = 10_000;
const ITEM_HEIGHT = 50;

export default function FlashListApp() {
  const data = React.useMemo(
    () => Array.from({ length: ITEM_COUNT }, (_, i) => `Row ${i}`),
    []
  );

  return (
    <SafeAreaView style={styles.safeArea}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>FlashList</Text>
        <Text style={styles.headerSubtitle}>Optimized JS-driven list</Text>
      </View>

      <FlashList
        data={data}
        estimatedItemSize={ITEM_HEIGHT}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={[styles.listContent, { paddingTop: 8 }]}
        renderItem={({ item }) => (
          <View style={styles.item}>
            <Text style={styles.itemText}>{item}</Text>
          </View>
        )}
        style={styles.list}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },

  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#F2F2F7',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#D1D1D6',
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
    backgroundColor: '#F2F2F7',
  },

  listContent: {
    paddingHorizontal: 12,
    paddingBottom: 0,
  },

  item: {
    height: ITEM_HEIGHT,
    paddingHorizontal: 18,
    marginBottom: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D1D6',
    justifyContent: 'center',
  },

  itemText: {
    fontSize: 16,
    color: '#000000',
  },
});
