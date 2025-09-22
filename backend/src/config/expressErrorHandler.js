
const { logger } = require('./globals');

module.exports = (server) => {
    server.use((err, req, res, next) => {
        try {

            err.req = {
                body: req.body
            };

            err.originalUrl = req.originalUrl;

            if (!err.service) {
                err.service = 'defaultExpressErrorHandler';
            }

            if (!err.isUserError) {
                logger.error(err);
            }

            if (res.headersSent) {
                next(err);
            } else {
                const userErrObj = {
                    err: true,
                    message: "Erro inesperado! Tente novamente!"
                };

                if (err.details) {
                    userErrObj.message = err.details;
                }

                res.status(500);
                res.json(userErrObj);
            }
        }
        catch (e) {
            console.error("Fatal error on default express error handler");
            console.error("Original Error:", err);
            console.error(e);
            if (res.headersSent) {
                next(err);
            } else {
                res.status(500);
                res.json({ err: true, message: "Erro Fatal!" });
            }
        }
    });
};