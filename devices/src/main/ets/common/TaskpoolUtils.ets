import { QTBle } from '../QTBle';
import { ArkTSUtils } from '@kit.ArkTS';
import { BTProtocol } from '../bluetooth/BTProtocol';
import { BTSetSystemTime } from '../model/BTSetSystemTime';
import { Log } from 'common/src/main/ets/Log';


@Concurrent
export function isSuccessTempFun(){
    try {
        const conditionVariable: ArkTSUtils.locks.ConditionVariable = new ArkTSUtils.locks.ConditionVariable();
        conditionVariable.waitFor(1000).then(() => {
            QTBle.write(BTProtocol.write(new BTSetSystemTime()));
        })
    }
    catch (ex){
        Log.e("Bluetooth", ex);
    }
}