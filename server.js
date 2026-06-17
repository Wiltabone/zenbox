// require dependencies for server
const express = require('express');
const max = require('max-api-or-not');
const socket = require('socket.io');
const shell = require('child_process');
const rpi = require('detect-rpi');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');

// add --debug option to not start in full screen and log
const verbose = process.argv[2] === '--debug';

// init the app server and port listen
const app = express();
app.use(express.static('.'));

const port = 3000;
const server = app.listen(port, () => {
	console.log(`Server is running at http://localhost:${port}`);
	console.log(`Run 'node server.js --debug' for logs`);
	
	if (rpi() && !verbose){
		// hide mouse when not moving
		shell.exec(`unclutter -idle 1`);
		// open browser in fullscreen incognito when on rpi
		shell.exec(`chromium-browser --start-fullscreen --start-maximized --incognito http://localhost:${port}`);
	}
});

// connect via socket io
const io = socket(server);

// initialize all visuals
let init = {};

// post socket id to max console
io.sockets.on('connection', function(socket){
	console.log(`Connected ${socket.id}`);

	// randomize initial values
	init = {
		'/dial/1':    Math.random() * 4096,
		'/dial/2':    Math.random() * 4096,
		'/dial/3':    Math.random() * 4096,
		'/slider/1':  Math.random() * 4096,
		'/slider/2':  Math.random() * 4096,
		'/slider/3':  Math.random() * 4096,
		'/slider/4':  Math.random() * 4096,
		'/2way/1': 1,
		'/2way/2': 0,
		'/2way/3': 0,
		'/3way/1': 0,
		'/3way/2': 0,
		'/button/1':  0,
		'/button/2':  0,
		'/button/3':  0,
	  }

	for (i in init){
		console.log('send', i, init[i]);
		io.emit('message', i, init[i]);
	}
});

// require dependency for receiving controller values
const { Server } = require('node-osc');
const oscPort = 9999;

// setup a server to receive OSC messages from controllers
let osc = new Server(oscPort, '0.0.0.0', () => {
	console.log(`OSC server listening at port ${oscPort}`);
	
	// receive messages and forward
	osc.on('message', (msg) => {
		if (!msg[0].startsWith('/dial/') && !msg[0].startsWith('/slider/')) console.log('received:', ...msg);

		// store the new values as the initials 
		// for when page gets refreshed
		if (init[msg[0]]){
			init[msg[0]] = msg[1];
		}

		// forward to the browser
		io.emit('message', ...msg);
	});
});

// send all parameters from Max (for testing purposes)
max.addHandler('message', (...v) => {
	io.emit('message', ...v);
});

// ── Serial port listener (Arduino Mega via USB) ───────────────────
// Override the port with: SERIAL_PORT=/dev/ttyUSB0 npm start
const serialPath = process.env.SERIAL_PORT || '/dev/ttyACM0';

const serial = new SerialPort({ path: serialPath, baudRate: 115200 }, (err) => {
	if (err) {
		console.log(`Serial port ${serialPath} not available: ${err.message}`);
	}
});

serial.on('open', () => {
	console.log(`Serial port open: ${serialPath} at 115200 baud`);
});

const parser = serial.pipe(new ReadlineParser({ delimiter: '\n' }));

parser.on('data', (line) => {
	const parts = line.trim().split(' ');
	if (parts.length !== 2) return;
	const address = parts[0];
	const value   = parseFloat(parts[1]);
	if (!address.startsWith('/') || isNaN(value)) return;

	if (address === '/haptic/status') {
		console.log(value === 1 ? 'Haptic motor found.' : 'WARNING: haptic motor not found — check I2C wiring on SDA=20/SCL=21.');
		return;
	}

	if (!address.startsWith('/dial/') && !address.startsWith('/slider/')) console.log('serial:', address, value);

	if (init[address] !== undefined) { init[address] = value; }
	io.emit('message', address, value);
});