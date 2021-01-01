// formsserver - show list of forms available and create on the fly

'use strict';

// ------------------------------------------------------------------------------------------
// constants

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');
const port = process.env.PORT || 1342;
const qs = require('querystring');
const uuid = require('uuid');
const child_process = require('child_process');
const nodemailer = require('nodemailer');

//const { exit } = require('process');
//const { exception } = require('console');

const jsondir = '\\\\file01\\data\\nmmc documents\\Scripts\\excelToJson\\';

sendemail();

function sendemail() {
    let transporter = nodemailer.createTransport({
        host: '10.1.1.96',
        port: 587,
        secure: false,
        auth: {
            user: "script@NMMC-NET.local",
            pass: "#N33c$cr!pTs@"
        },
        tls: { rejectUnauthorized: false }
    });
    let mailoptions = {
        from: 'script.user@nmmc.org',
        to: 'scott.warner@nmmc.org',
        subject: 'Ahoy',
        text: 'this was easy'
    }
    transporter.sendMail(mailoptions, (err, info) => {
        if (err) throw (err);
        console.log(`Sent: ${info.response}`);
    });
}


// ------------------------------------------------------------------------------------------
// variables

// ------------------------------------------------------------------------------------------
// server
http.createServer(function (req, res) {
    const params = new URLSearchParams(req.url.slice(1)); // starts with a /
    const action = params.get('q');

    console.log(req.url);
    console.log(req.method);
    console.log(action);

    if (req.method === 'POST') {
        if (action === 'makeform') {
            var fname = params.get('fname')
            var u = uuid.v1();
            var uname = `${fname}-${u}.html`;
            child_process.execSync(`powershell -ExecutionPolicy Bypass -File ./json2html.ps1 "${jsondir}${fname}" "./html/${uname}"`);

            fs.readFile(`./html/${uname}`, null, (err, html) => {
                if (err) throw err;
                var hstr = html.toString();

                res.writeHead(200, { 'Content-Type': 'text/html' })
                res.write(Buffer.from(hstr, 'utf-8'));
                res.end();
            });
        }
    }
    if (req.method === 'POST' && req.url === '/submit') {
        let body = [];
        req.on('data', (chunk) => {
            body.push(chunk);
        }).on('end', () => {
            body = Buffer.concat(body).toString();

            console.log(body);

            res.writeHead(200, { 'Content-Type': 'text/html' })
            res.write(body);
            res.end();
        });
    }
    if (req.method === 'GET') {
        if (action === null) {
            fs.readFile('./menu.html', null, (err, html) => {
                if (err) throw err;
                var hstr = html.toString();
                var fnames = fs.readdirSync(jsondir);
                var options = '';
                for (var f of fnames) {
                    options += `<option value="${f}">${f}</option>`;
                }
                hstr = hstr.replace('<select name="menu" id="menu">', `<select name="menu" id="menu">${options}`);
                var re = new RegExp('src="(.*\.png)"\/>');
                try {
                    var m = hstr.match(re);
                    var base64img = fs.readFileSync(`./${m[1]}`, { encoding: 'base64' });
                    hstr = hstr.replace(`src="${m[1]}"/>`, `src="data:image/png;base64, ${base64img}"/>`);
                }
                catch (e) {
                    console.log(e);
                }

                res.writeHead(200, { 'Content-Type': 'text/html' })
                res.write(Buffer.from(hstr, 'utf-8'));
                res.end();
            });
        }
    }
}).listen(port);
