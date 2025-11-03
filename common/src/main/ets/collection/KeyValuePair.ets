export class KeyValuePair<TKey,TValue> {
    private Key: TKey
    private Value: TValue

    constructor(key: TKey, value: TValue) {
        this.Key = key
        this.Value = value
    }

    public getKey() {
        return this.Key;
    }

    public setKey(key: TKey) {
        this.Key = key;
    }

    public getValue() {
        return this.Value;
    }

    public setValue(value: TValue) {
        this.Value = value;
    }
}