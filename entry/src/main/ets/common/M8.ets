import { Encoder } from 'decoder';

export class M8 {
  static encrypt(src: Uint8Array): Uint8Array {
    return Encoder.m8Encrypt(src);
  }

  static decrypt(src: Uint8Array): Uint8Array | null {
    return Encoder.m8Decrypt(src);
  }
}
