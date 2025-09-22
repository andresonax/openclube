"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
const util_1 = require("util");
const os_1 = require("os");
const winston_1 = require("winston");
const { combine, timestamp, json, colorize, printf } = winston_1.format;
const logsPath = process.env.LOGS_PATH || './logs';
const fileFormat = combine(timestamp({ format: 'DD-MM-YYYY HH:mm:ss' }), json());
const consoleFormat = combine(winston_1.format((info) => {
    info.level = info.level.toUpperCase();
    return info;
})(), colorize(), timestamp({ format: 'DD-MM-YYYY HH:mm:ss' }), printf((info) => {
    const { timestamp, level, message, ...args } = info;
    const msg = (typeof message === 'string') ? message : util_1.inspect(message, false, 2, true);
    const stripped = Object.assign({}, args);
    delete stripped[Symbol.for('splat')];
    delete stripped[Symbol.for('message')];
    delete stripped[Symbol.for('level')];
    let str = `\n${timestamp.trim()} [${level.trim()}]: ${msg.trim()}`;
    if (Object.keys(args).length) {
        str += `\nMetadata: ${util_1.inspect(stripped, false, 2, true)}`;
    }
    return str;
}));
class Logger {
    constructor(args) {
        this.isHandlerOn = false;
        // Maybe use inheritance for this
        this.isChild = false;
        this.exceptionsLogger = null;
        if (args === null || args === void 0 ? void 0 : args.logger) {
            this.isChild = true;
            this.logger = args.logger;
        }
        else {
            if (process.env.NODE_ENV === 'production') {
                this.logger = winston_1.createLogger({
                    defaultMeta: args === null || args === void 0 ? void 0 : args.defaultMeta,
                    transports: [
                        new winston_1.transports.File({
                            dirname: logsPath,
                            filename: 'errors.log',
                            level: 'warn',
                            maxsize: 20971520,
                            maxFiles: 5,
                            format: fileFormat
                        })
                    ]
                });
                this.exceptionsLogger = winston_1.createLogger({
                    defaultMeta: args === null || args === void 0 ? void 0 : args.defaultMeta,
                    transports: [
                        new winston_1.transports.File({
                            dirname: logsPath,
                            filename: 'exceptions.log',
                            level: 'warn',
                            maxsize: 20971520,
                            maxFiles: 5,
                            format: fileFormat
                        })
                    ]
                });
            }
            else {
                this.logger = winston_1.createLogger({
                    defaultMeta: args === null || args === void 0 ? void 0 : args.defaultMeta,
                    transports: [
                        new winston_1.transports.Console({
                            level: 'silly',
                            format: consoleFormat
                        })
                    ]
                });
                this.exceptionsLogger = winston_1.createLogger({
                    defaultMeta: args === null || args === void 0 ? void 0 : args.defaultMeta,
                    transports: [
                        new winston_1.transports.Console({
                            level: 'silly',
                            format: consoleFormat
                        })
                    ]
                });
            }
        }
    }
    child(metaArgs) {
        return new Logger({ logger: this.logger.child(metaArgs) });
    }
    _logException(logger, exception, details, verbose = false) {
        const errorAny = exception;
        const logObject = {
            level: 'error',
            message: exception.message,
            name: exception.name,
            stack: exception.stack,
            ...errorAny
        };
        if (details) {
            logObject.details = details;
        }
        if (verbose) {
            logger.log({
                ...logObject,
                pid: process.pid,
                cwd: process.cwd(),
                execPath: process.execPath,
                version: process.version,
                argv: process.argv,
                memoryUsage: process.memoryUsage(),
                uptime: os_1.uptime(),
            });
        }
        else {
            logger.log(logObject);
        }
        ;
    }
    _rejectionHandler(rejection) {
        if (rejection instanceof Error && this.exceptionsLogger) {
            this._logException(this.exceptionsLogger, rejection, 'unhandledRejection', true);
        }
        else {
            console.error(rejection);
        }
    }
    _getExceptionHandler(shouldExit) {
        return (exception) => {
            if (this.exceptionsLogger) {
                this._logException(this.exceptionsLogger, exception, 'uncaughtException', true);
            }
            else {
                console.error(exception);
            }
            if (shouldExit) {
                process.exit(1);
            }
        };
    }
    addErrorsListener(shouldExit = true) {
        if (!this.isChild && !this.isHandlerOn) {
            this.rejectionHandler = this._rejectionHandler.bind(this);
            this.exceptionHandler = this._getExceptionHandler(shouldExit).bind(this);
            process.on('unhandledRejection', this.rejectionHandler)
                .on('uncaughtException', this.exceptionHandler);
            this.isHandlerOn = true;
        }
    }
    removeErrorsListener() {
        if (!this.isChild && this.isHandlerOn) {
            process.removeListener('unhandledRejection', this.rejectionHandler)
                .removeListener('uncaughtException', this.exceptionHandler);
            this.isHandlerOn = false;
        }
    }
    error(arg) {
        if (arg instanceof Error) {
            this._logException(this.logger, arg);
        }
        else {
            this.logger.error(arg);
        }
    }
    warn(arg) {
        this.logger.warn(arg);
    }
    info(arg) {
        this.logger.info(arg);
    }
    silly(arg) {
        this.logger.silly(arg);
    }
    exception(exception, details, verbose = false) {
        this._logException(this.logger, exception, details, verbose);
    }
}
exports.Logger = Logger;
