import express from 'express';
import https from 'https';
import {Server} from 'socket.io';
import fs from 'fs';
import Config from './config.js'
const privateKey = fs.readFileSync('/certs/priv.key');
const certificate = fs.readFileSync('/certs/pub.cer');
const port = Config.port || 3000;
const serverFile = './server';
let serverUrl = fs.readFileSync(serverFile, 'utf8');
console.log("Initializing with serverUrl", serverUrl);
const app = express();
const server = https.createServer({
    key : privateKey,
    cert : certificate
}, app);
const io = new Server(server);

app.get('/api', (req, res) => {
    res.send('OK');
});

app.use(express.static('public'));

app.use(express.json());

/*
    Expects a JSON body:
    {
        task : String,
        args : Array,
        hud : String
    }
*/
function validateUrl( hud ){
    hud = new URL(hud);
    let hostname = hud.host.split('.');
    if( hostname.at(-1) !== "io" && hostname.at(-2) !== "secondlife" )
        throw new Error("Invalid host");
    return hud;
}

app.post('/api', async (req, res) => {

    if( typeof req.body !== "object" )
        return res.status(400).send("Bad request");
    
    let task = req.body.task,
        args = req.body.args,
        hud = req.body.hud
    ;
    if( !Array.isArray(args) )
        args = [args];

    let out = {};
    let data = {};

    try{
        

        // Act as a relay for the browser -> LSL. Task to relay is the first arg, followed by any additional args
        if( task === 'Fwd' ){
            
            hud = validateUrl(hud);

            let task = args[0];
            let subArgs = args.slice(1);
            const fe = await fetch(hud, {
                method : 'POST',
                headers : {
                    'Content-Type' : 'application/json'
                },
                body : JSON.stringify({
                    task : task,
                    args : subArgs
                })
            });
            data = await fe.json();

        }
        else if( task === "InitHud" ){
            
            data = {
                version : Config.hudVersion
            };

        }
        // Reverse relay, from LSL -> browser via websocket. Task to relay is the first arg, followed by any additional args
        else if( task === "WSFwd" ){

            hud = validateUrl(hud);
            io.to(hud.href).emit(args[0], args.slice(1));

        }
        // Accepts 2 arguments: admin token, and new URL
        else if( task === "SetDeliveryUrl" && args[0] === Config.adminToken ){
            
            const url = args[1];
            if( serverUrl !== url ){
                
                fs.writeFileSync(serverFile, url);
                serverUrl = url;
            }

        }
        // Arg 0 is the admin token, arg 1 is the UUID to deliver to
        else if( task === "DeliverHud" && args[0] === Config.adminToken ){

            const uuid = args[1];
            const fe = await fetch(serverUrl, {
                method : 'POST',
                headers : {
                    'Content-Type' : 'application/json'
                },
                body : JSON.stringify({
                    task : 'Deliver',
                    args : [
                        Config.hudPrefix+Config.hudVersion,
                        uuid
                    ]
                })
            });
            data = await fe.json();

        }
        else
            throw new Error("Invalid task or access denied");

        out.success = true;
        out.data = data;
    }catch(err){
        out.success = false;
        out.data = err.message || err;
    }

    res.send(out);

});

server.listen(port, () => {
    console.log('Server is running on docker port ' + port);
});

io.on('connection', (socket) => {
    console.log("Socket connected");
    socket.on('hookup', (data) => {
        if( !data || typeof data !== "object" || typeof data.hud !== "string" )
            return;

        if( socket.__room__ )
            socket.leave(socket.__room__);
        socket.__room__ = data.hud;
        socket.join(data.hud);
        
    });
});


