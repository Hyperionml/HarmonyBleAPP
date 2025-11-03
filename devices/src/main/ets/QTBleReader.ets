import { BluetoothReader } from "./bluetooth/BluetoothReader";
import { ArkTSUtils } from '@kit.ArkTS'
import { systemDateTime } from "@kit.BasicServicesKit";
import { ValueUtils } from 'common/src/main/ets/ValueUtils'

let lock: ArkTSUtils.locks.AsyncLock = ArkTSUtils.locks.AsyncLock.request("QTBleReader")

export class QTBleReader {

    private static readonly TAG: string = 'BluetoothReader'
    private static readonly FLAG = new Uint8Array([81,84,66,84]) ;//QTBT {'Q','T','B','T'}; //
    private static readonly SHORT_TIMEOUT = 3000;//读取过程中，小的超时
    private static readonly DEBUG_TIMEOUT = 1000 * 1000;//读取过程中，小的超时
    private static readonly LONG_TIMEOUT = 10000;//读取过程中，大的超时
    private static readonly SHORT_SLEEP = 10;
    private static readonly MAX_BUFFER_LENGTH = 310*1024;
    private static readonly BLOCK_HEADER_LENGTH = QTBleReader.FLAG.length + 4;
    private buffer: Uint8Array | null = null
    private blockLength = 0;//读取的数据，总长度是多少
    private curLength = 0;
    private lastReadTime = 0;

    public async mergeRead(unit: Uint8Array): Promise<Uint8Array | null | undefined>{
        return lock.lockAsync((): Uint8Array | null | undefined => {
            if (this.buffer == null) {
                this.buffer = new Uint8Array(QTBleReader.MAX_BUFFER_LENGTH)
                this.curLength = 0;
            }
            let lastReadTimeBackup = this.lastReadTime;
            let curTime = systemDateTime.getTime()

            let remainLength =  100000;
            if(this.curLength == 0 ){//通常unit不会低于20长度
                if( unit.length < QTBleReader.BLOCK_HEADER_LENGTH){
                    return null;//丢弃掉
                }
                if( unit.length > QTBleReader.MAX_BUFFER_LENGTH){
                    return null;//丢弃掉
                }
                let fixedCount = 0;
                for(let i = 0; i< QTBleReader.FLAG.length; i++){
                    let b = unit[i];
                    if(b == QTBleReader.FLAG[fixedCount]){
                        fixedCount++;
                    }
                }
                //读取到头标志了
                if(fixedCount != QTBleReader.FLAG.length){
                    return null;//丢弃掉
                }

                this.buffer?.set(unit, 0)

                this.blockLength = ValueUtils.toInt(this.buffer!,4,4);
                if (this.blockLength >= QTBleReader.MAX_BUFFER_LENGTH) {
                    throw new Error(`Assertion failed: blockLength (${this.blockLength}) >= MAX_BUFFER_LENGTH (${QTBleReader.MAX_BUFFER_LENGTH}).`);
                }
                this.curLength = unit.length;

                remainLength = this.blockLength - this.curLength;
                this.lastReadTime = curTime;
            }
            else{
                //读取超时，丢弃
                if(curTime - lastReadTimeBackup > QTBleReader.SHORT_TIMEOUT){
                    this.blockLength = 0;
                    this.curLength = 0;
                    this.lastReadTime = 0;
                    return null;
                }
                this.lastReadTime = curTime;
                remainLength = this.blockLength - this.curLength;
                let toReadLength = unit.length;
                if(toReadLength > remainLength){
                    toReadLength = remainLength;
                }
                this.buffer.set(unit.subarray(0, toReadLength), this.curLength)

                this.curLength += toReadLength;

                remainLength = this.blockLength - this.curLength;
            }
            if(this.buffer.length > 0 && remainLength<=0){
                let block = new Uint8Array(this.blockLength)
                block.set(this.buffer.subarray(0, this.blockLength), 0)
                this.blockLength = 0;
                this.curLength = 0;
                this.lastReadTime = 0;

                return block;
            }
            return null
        })
    }
}