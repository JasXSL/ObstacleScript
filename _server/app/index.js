import express from 'express';
import http from 'http';
import {Server} from 'socket.io';
const app = express();
const server = http.createServer(app);
const io = new Server(server);

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
        hud = new URL(hud);
        let hostname = hud.host.split('.');
        if( hostname.at(-1) !== "io" && hostname.at(-2) !== "secondlife" )
            throw new Error("Invalid host");

        // Act as a relay for the browser -> LSL. Task to relay is the first arg, followed by any additional args
        if( task == 'Fwd' ){
            
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
        // Reverse relay, from LSL -> browser via websocket. Task to relay is the first arg, followed by any additional args
        else if( task == "WSFwd" ){
            io.to(hud.href).emit(args[0], args.slice(1));
            return true;
        }
        else
            throw new Error("Invalid task");

        out.success = true;
        out.data = data;
    }catch(err){
        out.success = false;
        out.data = err.message || err;
    }

    res.send(out);

});

server.listen(3000, () => {
    console.log('Server is running on port 3000');
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


