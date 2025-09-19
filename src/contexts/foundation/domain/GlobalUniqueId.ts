import { v7 as uuidv7 } from 'uuid';

export class GlobalUniqueId {
    readonly id: string;

    constructor(id?: string) {
        this.id = id ?? uuidv7();
    }
}