"use strict"
require('dotenv').config();

const validFileExtensions = [
'.doc',
'.docx',
'.odt',
'.rtf',
'.pdf',
'.jpg',
'.jpeg',
'.png',
'.gif',
'.bmp',
'.svg',
'.webp',
'.wav',
'.webm',
'.mkv',
'.mp4',
'.m4a',
'.m4v',
'.f4v',
'.f4a',
'.m4b',
'.m4r',
'.f4b',
'.mov',
'.3gp',
'.3gp2',
'.3g2',
'.3gpp',
'.3gpp2',
'.avi',
'.wmv',
'.wma',
'.ogg',
'.oga',
'.ogv',
'.ogx'];

//LOCAL
// const corsAllow = [
//     'http://127.0.0.1:3001',
//     'http://localhost:3001',
//     'http://127.0.0.1:8000',
//     'http://localhost:8000',
//     'http://localhost:5500'    
//     ];
 
//NUVEM

const corsAllow = '*'

//const corsAllow = 'https://projetogravei.sxesportes.com.br';
//const sharedResourcesUrl = "https://shared.sonaxsistemas.com.br/";
const port = 3002;

const dbConfig = {
    host: "127.0.0.1",
    user: "root",
    //password: "root",
    password: "Sql@123456",
    database: "gravou",
    multipleStatements: true
};  

/*
const dbConfig = {
    host: "clinic82.c8tuthxylqic.sa-east-1.rds.amazonaws.com",
    user: "usergravou",
    password: "v@!_#8?5Zr9PXuUM",
    database: "gravou",
    multipleStatements: true
};*/

const banks = {
    juno: "383",
    viaCredi: "085",
    inter: "077",
    sicredi: "748",
    bb: "001",
    sicoob: "756"
};

const certificatesPath = 'resources/certificates/';
const uploadsPath = 'files/uploads/'


const isValidExtension = (ext) => {
    return validFileExtensions.includes(ext);
};

module.exports = {
    isValidExtension,
    banks,
    certificatesPath,
    corsAllow,
    port,
    dbConfig,
    uploadsPath
    //sharedResourcesUrl,   
};