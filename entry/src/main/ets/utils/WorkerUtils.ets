import { worker } from "@kit.ArkTS"
import { WorkerCommand } from "../workers/TimerWorker"
import { Logger } from "./LogUtil"

export function postCommandToWorker(worker: worker.ThreadWorker, command: WorkerCommand) {
  try {
    worker.postMessage(command)
  } catch (e) {
    let be = e as BusinessError<Object>
    Logger.error("postCommandToWorker: %{public}d, %{public}s", be.code, be.message)
  }
}
