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
const os = require('os');
const uuid = require('uuid');
const child_process = require('child_process');
const nodemailer = require('nodemailer');
const { exit } = require('process');

const shell = require('node-powershell');
let ps = new shell({
  executionPolicy: 'Bypass',
  noProfile: true
});

// const isLive = __dirname + '' == 'C:\\scripts\\nodejs\\formsserver';
// console.log(isLive);

const isLive = true; // note that this doesn't work on RDS

//const { exit } = require('process');
//const { exception } = require('console');

const jsondir = '\\\\file01\\data\\nmmc documents\\Scripts\\excelToJson\\';

function sendemail(mailoptions) {
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
    transporter.sendMail(mailoptions, (err, info) => {
        if (err) throw (err);
        console.log(`Sent: ${info.response}`);
    });
}


// ------------------------------------------------------------------------------------------
// variables
let fname = '';
let names = [];

function editing(dname) {
    let n = names.find(n => n.dname === dname && n.counter > -2) || null;
    return n;
}

var interval = setInterval(()=>{
    console.log(names);
    names.forEach((n) =>{
        if (n.counter > -2) {
            n.counter--;
        }
    });
}, 5000);

// ------------------------------------------------------------------------------------------
// server
http.createServer(function (req, res) {
    const params = new URLSearchParams(req.url.slice(1)); // starts with a /
    const action = params.get('q');

    let ip = req.connection.remoteAddress;
    let usr = os.userInfo().username;

    console.log(req.url);
    console.log(req.method);
    console.log(action);

    if (req.method === 'PUT' && action === 'getform') {
        var dname = params.get('dname');
        console.log(dname);
        var n = editing(dname);
        if (n === null) {
            names.push({
                dname: dname,
                ip: ip,
                counter: 1,
            });
        }
        else {
            n.counter++;
        }
        res.writeHead(204);
        res.end();
    }
    if (req.method === 'POST'  || req.method === 'GET') {
        if (action === 'makeform') {
            fname = params.get('fname')
            var u = uuid.v1();
            var uname = `${fname}-${u}.html`;
            console.log(ip);

            var start = process.hrtime();
            ps.addCommand(`./json2html.ps1 "${jsondir}${fname}" "./html/${uname}" "${ip}" "${usr}"`);
            ps.invoke()
            .then((result)=>{
                ps.clear()
                .then((result)=>{
                    var end = process.hrtime(start);
                    console.log(end);
                    fs.readFile(`./html/${uname}`, null, (err, html) => {
                        if (err) throw err;
                        var hstr = html.toString();
        
                        res.writeHead(200, { 'Content-Type': 'text/html' })
                        res.write(Buffer.from(hstr, 'utf-8'));
                        res.end();
                    });
                });
            });
        }
    }
    if (req.method === 'POST' && req.url === '/submit') {
        let body = [];
        req.on('data', (chunk) => {
            body.push(chunk);
        }).on('end', () => {
            var u = uuid.v1();
            var dname = `${fname}-${u}.txt`;
            var uname = `./formdata/${dname}`;
            body = Buffer.concat(body).toString();

            var bdict = qs.parse(body);
            var from = unescape(bdict['popFrom']);
            var to = unescape(bdict['popTo']);
            var bcc = unescape(bdict['popCc']);
            var subject = unescape(bdict['popSubject']).replace('+', ' ');
            var message = unescape(bdict['popMessage']).replace('+', ' ').replace('\n', '<br>');

            console.log(bdict['popMessage']);

            var link = `http://server:1342/q=getform&fname=${fname}&dname=${dname}`

            console.log('from');

            console.log(isLive);
            if (isLive) {
                link = link.replace('server', 'scripts');
            }
            else {
                link = link.replace('server', '10.1.2.63');
            }

            sendemail({
                from: from,
                to: [from, to],
                bc: bcc,
                subject: subject,
                html: `<a href=${link}>Click here!</a><br><br>Message:<br>${message}`
            });

            fs.writeFile(uname, body, (err) => {
                if (err) throw err;
            });

            res.statusCode=302;
            res.setHeader('Location','/');
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
        if (action === 'getform') {
            fname = params.get('fname');
            var dname = params.get('dname');
            console.log(editing(dname));
            let n = editing(dname);
            if (n === null) {
                var u = uuid.v1();
                var uname = `${fname}-${u}.html`;
                console.log(ip);

                var start = process.hrtime();
                ps.addCommand(`./json2html.ps1 "${jsondir}${fname}" "./html/${uname}" "${ip}" "${usr}"`);
                ps.invoke()
                .then((result)=>{
                    ps.clear()
                    .then((result)=>{
                        var end = process.hrtime(start);
                        console.log(end);
                        fs.readFile(`./html/${uname}`, null, (err, html) => {
                            if (err) throw err;
                            var hstr = html.toString();
                            fs.readFile(`./formdata/${dname}`, null, (err, data) => {
                                if (err) throw err;
            
                                hstr = hstr.replace('data841350ab-4f07-46b9-9fca-1e03d46779e8', data);
            
                                res.writeHead(200, { 'Content-Type': 'text/html' })
                                res.write(Buffer.from(hstr, 'utf-8'));
                                res.end();
                            });
                        });
                    });
                });
            }
            else {
                res.writeHead(200, { 'Content-Type': 'text/html' })
                res.write(`That form is currently being edited at ${n.ip}.`);
                res.end();
            }
        }
    }
}).listen(port);
