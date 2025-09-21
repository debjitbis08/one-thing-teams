import { v7 as uuidv7, validate } from "uuid";

export class GlobalUniqueId {
    readonly id: string;

    constructor(id?: string) {
        this.id = id ?? uuidv7();
    }
}
