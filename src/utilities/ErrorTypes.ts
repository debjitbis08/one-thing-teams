export enum ErrorTypes {
    InternalException = "InternalException",
    NotFound = "NotFound",
    ValidationError = "ValidationError",
    Unauthorized = "Unauthorized",
    Forbidden = "Forbidden",
    BadRequest = "BadRequest",
    Conflict = "Conflict",
    ServiceUnavailable = "ServiceUnavailable",
    ExternalServiceError = "ExternalServiceError",
}

export function errorTypeToHttpStatusCode(errorType: ErrorTypes) {
    switch (errorType) {
        case ErrorTypes.NotFound:
            return 404;
        case ErrorTypes.ValidationError:
            return 400;
        case ErrorTypes.Unauthorized:
            return 401;
        case ErrorTypes.Forbidden:
            return 403;
        case ErrorTypes.BadRequest:
            return 400;
        case ErrorTypes.Conflict:
            return 409;
        case ErrorTypes.ServiceUnavailable:
            return 503;
        case ErrorTypes.ExternalServiceError:
            return 503;
        case ErrorTypes.InternalException:
        default:
            return 500;
    }
}