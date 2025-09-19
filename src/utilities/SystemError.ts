import { CustomError } from "ts-custom-error";
import { ErrorTypes, errorTypeToHttpStatusCode } from "./ErrorTypes.js";
import { logger } from "./logger";

export class SystemError extends CustomError {
    public errorType: ErrorTypes;
    public shouldLog: boolean;
    public details: string;

    constructor(
        message: string,
        errorType: ErrorTypes,
        shouldLog: boolean = false,
        details: string = "",
    ) {
        super(message);
        this.errorType = errorType;
        this.shouldLog = shouldLog;
        this.details = details;
    }

    static fromGenericError(error: Error, title: string) {
        const details = [
            `Name: ${error.name}`,
            `Message: ${error.message}`,
            `Stack: ${error.stack || "No stack trace available"}`,
        ].join(", ");

        return new SystemError(
            title,
            ErrorTypes.InternalException,
            true,
            details,
        );
    }

    static fromUnknownError(error: unknown, title: string, errorType = ErrorTypes.InternalException, shouldLog = true) {
        if (error instanceof Error) {
          const details = [
              `Name: ${error.name}`,
              `Message: ${error.message}`,
              `Stack:\n${error.stack || "No stack trace available"}`,
          ].join('\n');

          return new SystemError(
              title,
              errorType,
              shouldLog,
              details,
          );
        } else {
          return new SystemError(
            title,
            errorType,
            shouldLog,
            "No details available",
          );
        }
    }

    toWebError() {
      if (this.shouldLog) {
        logger.error(`${this.message}\n${this.details}`)
      }
      return { status: errorTypeToHttpStatusCode(this.errorType),
        message: this.message,
      };
    }

    log() {
      if (this.shouldLog) {
        logger.error(`${this.message}\n${this.details}`)
      }
    }
}