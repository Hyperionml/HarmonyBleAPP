import { Event } from './Event';

export interface IEventReceiver {
  //onEvent(sender: Object, event: Event, isAsync: boolean): void;
  onEvent:(sender: Object | null, event: Event, isAsync: boolean) => void;
}

