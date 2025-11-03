export class Entry<K,V> {
    private key: K
    private value: V

    constructor(key: K, value: V) {
        this.key = key
        this.value = value
    }

    getKey(): K{
        return this.key
    }

    getValue(): V{
        return this.value
    }
}