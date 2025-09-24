export type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonValue[]
  | { [key: string]: JsonValue };

export type StoredEvent = {
  id: string;
  orgId: string;
  aggregateId: string;
  aggregateType: string;
  version: number;
  type: string;
  data: JsonValue;
  meta: JsonValue;
  createdAt: Date;
};

export type NewEvent = Omit<StoredEvent, "createdAt"> & {
  createdAt?: Date;
};

export type StoredSnapshot = {
  aggregateId: string;
  aggregateType: string;
  version: number;
  state: JsonValue;
  createdAt: Date;
};

export type NewSnapshot = Omit<StoredSnapshot, "createdAt"> & {
  createdAt?: Date;
};

export type AppendEventsOptions = {
  events: NewEvent[];
  expectedVersion?: number;
};

export type LoadStreamOptions = {
  aggregateId: string;
  fromVersion?: number;
};

export interface EventRepository {
  append(options: AppendEventsOptions): Promise<void>;
  loadStream(options: LoadStreamOptions): Promise<StoredEvent[]>;
  loadLatestSnapshot(aggregateId: string): Promise<StoredSnapshot | null>;
  persistSnapshot(snapshot: NewSnapshot): Promise<void>;
}
