import { Level } from './Level';
export class Event {
  protected isStop: boolean = false;
  protected data: Object | null = null;
  protected result: Object | null = null;
  protected type: string | null;
  protected level: Level;

  constructor(type: string | null = null, level: Level = Level.Common, data?: Object) {
    this.type = type;
    this.level = level;
    this.data = data || null;
  }

  stop(result?: Object): void {
    this.isStop = true;
    this.result = result || null;
  }

  getLevel(): Level {
    return this.level;
  }

  getType(): string {
    return this.type!;
  }

  getData(): Object | null {
    return this.data;
  }

  getResult(): Object | null {
    return this.result;
  }

  isStoped(): boolean {
    return this.isStop;
  }
}