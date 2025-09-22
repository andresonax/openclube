"use strict";

const conection = require("../config/database"); // ATENCÃO A ESTE PATH!!!
const { isValidExtension } = require("../config/globals");
const express = require("express");
const path = require("path");
const multer = require("multer");
const shortid = require("shortid");
const fs = require("fs");
const jwt = require("jsonwebtoken");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "./uploads/private");
  },
  filename: (req, file, cb) => {
    const id = shortid.generate();
    const preffix = req.body.page ? req.body.page : "generic";
    cb(null, preffix + "_" + Date.now() + id + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5242880, files: 1 },
  fileFilter: (req, file, callback) => {
    if (!isValidExtension(path.extname(file.originalname))) {
      return callback({ invalid: true });
    }
    callback(null, true);
  },
});

module.exports = (server) => {
  const router = express.Router();

  router.post("/uploads/private", (req, res) => {
    const token = req.signedCookies.jwt;

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWTSECRET);

        conection.query(
          "SELECT * FROM pessoa WHERE email = ? AND id_pessoa = ?",
          [decoded.email, decoded.id],
          (error, results, fields) => {
            if (error || results.length === 0) {
              if (error) {
                console.error("Error in login verify for add private!");
                console.error(error);
              }
              res.json({ err: true, message: "unauthorized" });
            } else {
              upload.single("file")(req, res, (err) => {
                if (err) {
                  console.log(err);
                  const ans = { err: true };
                  ans.message = err.invalid
                    ? "Tipo de arquivo inválido!"
                    : "Erro ao enviar arquivo! Max 5MB";
                  res.json(ans);
                } else {
                  if (req.file != undefined) {
                    res.send(req.file);
                  } else {
                    res.json({ err: true, message: "Nenhum arquivo!" });
                  }
                }
              });
            }
          }
        );
      } catch (err) {
        res.json({ err: true, message: "unauthorized" });
      }
    } else {
      res.json({ err: true, message: "unauthorized" });
    }
  });

  router.post("/uploads/private/del", (req, res) => {
    if (req.body.file) {
      const token = req.signedCookies.jwt;

      if (token) {
        try {
          //console.log('Hey');
          const decoded = jwt.verify(token, process.env.JWTSECRET);

          conection.query(
            "SELECT * FROM pessoa WHERE email = ? AND id_pessoa = ?",
            [decoded.email, decoded.id],
            (error, results, fields) => {
              if (error || results.length === 0) {
                if (error) {
                  console.error("Error in login verify for delete private!");
                  console.error(error);
                }
                res.json({ err: true, message: "unauthorized" });
              } else {
                let file_path = "";
                try {
                  file_path = req.body.file.path
                    ? path.basename(req.body.file.path)
                    : path.basename(req.body.file);
                } catch (error) {
                  file_path = "";
                }

                console.log("Apagando: " + file_path);
                const p = "uploads/private/" + (file_path ? file_path : "");
                console.log(file_path);
                fs.lstat(p, function (error, stat) {
                  if (stat && stat.isFile()) {
                    fs.unlink(p, (err) => {
                      if (err) {
                        console.error("Error Deleting Private File");
                        console.error(err);
                        res.json({ err: true });
                      } else {
                        res.json({ err: false });
                      }
                    });
                  } else {
                    res.json({ err: true });
                  }
                });
              }
            }
          );
        } catch (err) {
          res.json({ err: true, message: "unauthorized" });
        }
      } else {
        res.json({ err: true, message: "unauthorized" });
      }
    } else {
      res.json({ err: true });
    }
  });

  router.post("/uploads/private/del/batch", (req, res) => {
    if (req.body.files) {
      const files = req.body.files;

      if (Array.isArray(files) && files.length != 0) {
        const token = req.signedCookies.jwt;

        if (token) {
          try {
            const decoded = jwt.verify(token, process.env.JWTSECRET);

            conection.query(
              "SELECT * FROM pessoa WHERE email = ? AND id_pessoa = ?",
              [decoded.email, decoded.id],
              (error, results, fields) => {
                if (error || results.length === 0) {
                  if (error) {
                    console.error(
                      "Error in login verify for delete batch private!"
                    );
                    console.error(error);
                  }
                  res.json({ err: true, message: "unauthorized" });
                } else {
                  files.forEach((file) => {
                    // Doesnt detect files not deleted
                    const p = "uploads/private/" + path.basename(file);
                    fs.lstat(p, function (error, stat) {
                      if (stat && stat.isFile()) {
                        fs.unlink(p, (err) => {
                          if (err) {
                            console.error("Error Deleting Private File Batch");
                            console.error(err);
                          }
                        });
                      }
                    });
                  });
                  res.json({ err: false });
                }
              }
            );
          } catch (err) {
            res.json({ err: true, message: "unauthorized" });
          }
        } else {
          res.json({ err: true, message: "unauthorized" });
        }
      } else {
        res.json({ err: !Array.isArray(files) });
      }
    } else {
      res.json({ err: true });
    }
  });

  router.get("/uploads/private/*", (req, res) => {
    const token = req.signedCookies.jwt;

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWTSECRET);

        conection.query(
          "SELECT * FROM pessoa WHERE email = ? AND id_pessoa = ?",
          [decoded.email, decoded.id],
          (error, results, fields) => {
            if (error || results.length === 0) {
              if (error) {
                console.error("Error in login verify for get private!");
                console.error(error);
              }
              res.status(401).json({ err: true, message: "unauthorized" });
            } else {
              const p = "uploads/private/" + path.basename(req.originalUrl);
              console.log("Carregou: " + p);
              fs.lstat(p, function (error, stat) {
                if (stat && stat.isFile()) {
                  res.sendFile(p, { root: "./" });
                } else {
                  res.status(404).send("<h1>404</h1>");
                }
              });
            }
          }
        );
      } catch (err) {
        res.status(401).json({ err: true, message: "unauthorized" });
      }
    } else {
      res.status(401).json({ err: true, message: "unauthorized" });
    }
  });

  server.use("/", router);
};
