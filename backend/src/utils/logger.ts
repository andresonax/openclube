import { inspect } from 'util';
import { uptime } from 'os';
import winston, { createLogger, transports, format, LogEntry } from 'winston';
const { combine, timestamp, json, colorize, printf } = format;

const logsPath = process.env.LOGS_PATH || './logs';

const fileFormat = combine(
    timestamp({ format: 'DD-MM-YYYY HH:mm:ss' }),
    json()
);

const consoleFormat = combine(
    format((info) => {
        info.level = info.level.toUpperCase();
        return info;
    })(),
    colorize(),
    timestamp({ format: 'DD-MM-YYYY HH:mm:ss' }),
    printf((info) => {
        const {
            timestamp, level, message, ...args
        } = info;

        const msg = (typeof message === 'string') ? message : inspect(message, false, 2, true);

        const stripped = Object.assign({}, args);

        delete stripped[Symbol.for('splat') as any];
        delete stripped[Symbol.for('message') as any];
        delete stripped[Symbol.for('level') as any];

        let str = `\n${timestamp.trim()} [${level.trim()}]: ${msg.trim()}`;
        if (Object.keys(args).length) {
            str += `\nMetadata: ${inspect(stripped, false, 2, true)}`;
        }
        return str;
    }),
);


export class Logger {
    private logger: winston.Logger;
    private isHandlerOn: boolean = false;
    // Maybe use inheritance for this
    private isChild: boolean = false;
    private rejectionHandler: any;
    private exceptionHandler: any;
    private exceptionsLogger: winston.Logger | null = null;

    constructor(args?: LoggerArgs) {
        if (args?.logger) {
            this.isChild = true;
            this.logger = args.logger;
        } else {
            if (process.env.NODE_ENV === 'production') {
                this.logger = createLogger({
                    defaultMeta: args?.defaultMeta,
                    transports: [
                        new transports.File({
                            dirname: logsPath,
                            filename: 'errors.log',
                            level: 'warn',
                            maxsize: 20971520, // 20 MB
                            maxFiles: 5,
                            format: fileFormat
                        })
                    ]
                });
                this.exceptionsLogger = createLogger({
                    defaultMeta: args?.defaultMeta,
                    transports: [
                        new transports.File({
                            dirname: logsPath,
                            filename: 'exceptions.log',
                            level: 'warn',
                            maxsize: 20971520, // 20 MB
                            maxFiles: 5,
                            format: fileFormat
                        })
                    ]
                });
            } else {
                this.logger = createLogger({
                    defaultMeta: args?.defaultMeta,
                    transports: [
                        new transports.Console({
                            level: 'silly',
                            format: consoleFormat
                        })
                    ]
                });
                this.exceptionsLogger = createLogger({
                    defaultMeta: args?.defaultMeta,
                    transports: [
                        new transports.Console({
                            level: 'silly',
                            format: consoleFormat
                        })
                    ]
                });
            }
        }
    }

    child(metaArgs: Object): Logger {
        return new Logger({ logger: this.logger.child(metaArgs) });
    }

    private _logException(logger: winston.Logger, exception: Error, details?: string, verbose: boolean = false): void {
        const errorAny = exception as any;

        const logObject: LogEntry = {
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
                uptime: uptime(),
            });
        } else {
            logger.log(logObject);
        };
    }

    private _rejectionHandler(rejection: any) {
        if (rejection instanceof Error && this.exceptionsLogger) {
            this._logException(this.exceptionsLogger, rejection, 'unhandledRejection', true);
        } else {
            console.error(rejection);
        }
    }

    private _getExceptionHandler(shouldExit: boolean) {
        return (exception: Error) => {
            if (this.exceptionsLogger) {
                this._logException(this.exceptionsLogger, exception, 'uncaughtException', true);
            } else {
                console.error(exception);
            }
            if (shouldExit) {
                process.exit(1);
            }
        }
    }

    addErrorsListener(shouldExit: boolean = true) {
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

    error(arg: any) {
        if (arg instanceof Error) {
            this._logException(this.logger, arg);
        } else {
            this.logger.error(arg);
        }
    }

    warn(arg: any) {
        this.logger.warn(arg);
    }

    info(arg: any) {
        this.logger.info(arg);
    }

    silly(arg: any) {
        this.logger.silly(arg);
    }

    exception(exception: Error, details?: string, verbose: boolean = false) {
        this._logException(this.logger, exception, details, verbose);
    }

}

interface LoggerArgs {
    defaultMeta?: any,
    logger?: winston.Logger
}