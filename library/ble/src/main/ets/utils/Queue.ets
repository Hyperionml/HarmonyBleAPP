/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export class Queue <T> {
  private items: Array<T>
  private capacity: number | undefined;

  public constructor(capacity?: number) {
    this.items = new Array<T>();
    this.capacity = capacity;
  }

  public add(item: T): boolean {
    if (item == null) {
      return false;
    }

    if (this.capacity != undefined && this.capacity == this.items.length) {
      this.items.pop();
    }

    this.items.unshift(item);
    return true;
  }

  public offer(item: T): boolean {
    if (item == null) {
      return false;
    }

    if (this.capacity != undefined && this.capacity == this.items.length) {
      return false;
    }

    this.items.unshift(item);
    return true;
  }

  public remove(): T|undefined{
    if (this.items.length == 0) {
      return this.items.pop();
    }
    throw EvalError('NoSuchElement');
  }

  public poll(): T|undefined{
    if (this.items.length > 0) {
      return this.items.pop();
    }
    return undefined;
  }

  public element(): T{
    if (this.items.length > 0) {
      return this.items[this.items.length-1];
    }
    throw EvalError('NoSuchElement');
  }

  public peek(): T|null{
    if (this.items.length > 0) {
      return this.items[this.items.length-1];
    }
    return null;
  }

  public size(): number {
    return this.items.length;
  }

  public empty(): boolean{
    return this.size() == 0;
  }

  public clear() {
    this.items = new Array<T>();
  }
}
