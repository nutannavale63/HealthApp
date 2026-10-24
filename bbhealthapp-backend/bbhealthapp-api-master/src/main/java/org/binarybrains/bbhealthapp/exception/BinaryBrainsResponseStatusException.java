package org.binarybrains.bbhealthapp.exception;

import org.springframework.http.HttpStatus;
import org.springframework.lang.Nullable;
import org.springframework.web.server.ResponseStatusException;

import javax.validation.ConstraintViolationException;

public class BinaryBrainsResponseStatusException extends ResponseStatusException {


    public BinaryBrainsResponseStatusException(HttpStatus status) {
        super(status, null, null);
    }


    public BinaryBrainsResponseStatusException(HttpStatus status, @Nullable String reason) {
        super(status, reason, null);
    }


    public BinaryBrainsResponseStatusException(HttpStatus status, @Nullable String reason, @Nullable Throwable cause) {
        super(status, reason, cause);
    }



    public static BinaryBrainsResponseStatusException asForbidden(String msg) {
        return asExceptionFromHttpStatus(msg, HttpStatus.FORBIDDEN);
    }
    public static BinaryBrainsResponseStatusException asBadRequest(String msg) {
        return asExceptionFromHttpStatus(msg, HttpStatus.BAD_REQUEST);
    }
    public static BinaryBrainsResponseStatusException asBadRequest(String msg, Throwable throwable) {
        return new BinaryBrainsResponseStatusException( HttpStatus.BAD_REQUEST,msg,throwable);
    }

    public static BinaryBrainsResponseStatusException asServerError(String msg) {
        return asExceptionFromHttpStatus(msg, HttpStatus.INTERNAL_SERVER_ERROR);
    }
   public static BinaryBrainsResponseStatusException asNoContent(String msg) {
        return asExceptionFromHttpStatus(msg, HttpStatus.BAD_REQUEST);
    }


    public static BinaryBrainsResponseStatusException asConstraintViolation(ConstraintViolationException e) {

        return  new BinaryBrainsResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(),e);
    }

    public static BinaryBrainsResponseStatusException asExceptionFromHttpStatus(String msg, HttpStatus httpStatus) {
        return new BinaryBrainsResponseStatusException(httpStatus, msg);
    }


}
