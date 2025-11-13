import express from 'express';
const app = express();

app.use(express.static('public'));

app.use(express.json());

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

        // Act as a relay for the HUD
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
            console.log("Received from remote", data);

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

app.listen(3000, () => {
    console.log('Server is running on port 3000');
});
