import type { AuthenticatedSession } from "../contexts/id/infrastructure/authenticateSession";

declare global {
  namespace App {
    interface Locals {
      session?: AuthenticatedSession;
    }
  }
}

export {};
