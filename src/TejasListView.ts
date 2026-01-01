import { getHostComponent } from 'react-native-nitro-modules';
import type { TejasListProps, TejasListMethods } from './TejasList.nitro';
const TejasListConfig = require('../nitrogen/generated/shared/json/TejasListConfig.json');

/**
 * Native-backed host component.
 *
 * - No JS layout logic
 * - No scroll handlers
 * - No recycling
 *
 * This is the lowest-level React surface.
 */
export const TejasListView = getHostComponent<TejasListProps, TejasListMethods>(
  'TejasList',
  () => TejasListConfig
);
