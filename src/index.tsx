import { getHostComponent } from 'react-native-nitro-modules';
const TejasListConfig = require('../nitrogen/generated/shared/json/TejasListConfig.json');
import type {
  TejasListMethods,
  TejasListProps,
} from './TejasList.nitro';

export const TejasListView = getHostComponent<
  TejasListProps,
  TejasListMethods
>('TejasList', () => TejasListConfig);
