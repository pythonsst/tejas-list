import { getHostComponent } from 'react-native-nitro-modules';
import type { TejasListProps, TejasListMethods } from '../spec/TejasList.nitro';

const TejasListConfig = require('../../nitrogen/generated/shared/json/TejasListConfig.json');

export const TejasListHostView = getHostComponent<
  TejasListProps,
  TejasListMethods
>('TejasList', () => TejasListConfig);
