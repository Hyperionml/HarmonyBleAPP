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

export default class ArrayUtils{
    public static isEmpty<T>(array: Array<T>): boolean {
        return array == null || array == undefined || array.length==0;
    }

    public static getAllKeys<K, V>(map: Map<K, V>) : Array<K>{
        let array = new Array<K>();
        for(let item of map.keys()) {
            array.push(item)
        }
        return array;
    }
    public static getAllValues<K, V>(map: Map<K, V>) : Array<V>{
        let array = new Array<V>();
        for(let item of map.values()) {
            array.push(item)
        }
        return array;
    }

    public static getAll<T>(iterator: IterableIterator<T>) : Array<T>{
        let array = new Array<T>();
        for(let item of iterator) {
            array.push(item)
        }
        return array;
    }
}