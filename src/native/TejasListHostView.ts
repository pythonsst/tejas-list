import { getHostComponent } from 'react-native-nitro-modules';
import type { TejasListProps, TejasListMethods } from '../spec/TejasList.nitro';

const TejasListConfig = require('../../nitrogen/generated/shared/json/TejasListConfig.json');

/**
 * Native-backed host view.
 *
 * Rules:
 * - No JS layout logic
 * - No scroll handlers
 * - No recycling logic
 * - No user-facing API
 */
export const TejasListHostView = getHostComponent<
  TejasListProps,
  TejasListMethods
>('TejasList', () => TejasListConfig);
