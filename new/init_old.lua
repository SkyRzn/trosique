shot_cnt = 0;
shot_exp = 0;  --microsec
shot_delay = 0;  --millisec
shot_pin = 6 --GPIO 12
focus_pin = 7 --GPIO 13
client_conn = nil
state_init, state_main, state_work, state_ok = 0, 1, 2, 3
state = state_init


function send(data)
	local res = "HTTP/1.1 200 OK\r\n\r\n";
	if data then
		res = res..data;
	end
	client_conn:send(res);
end

function send_ok()
	print("ok");
	send("ok");
	state = state_ok;
end

function work_end()
	print("end");
	client_conn:close();
	collectgarbage();
	state = state_init;
end

function shot()
	tmr.wdclr();
	gpio.write(shot_pin, gpio.LOW);
	tmr.delay(shot_exp);
	gpio.write(shot_pin, gpio.HIGH);
	
	shot_cnt = shot_cnt - 1;
	
	if shot_cnt > 0 then
		tmr.alarm(0, shot_delay, 0, shot);
	else
		send_ok();
	end
end

function start()
	tmr.wdclr();
	if shot_delay == 0 then
		if shot_cnt == 1 then
			shot();
		else
			shot_delay = 500;
		end			
	end
	if shot_delay > 0 then
		tmr.alarm(0, shot_delay, 0, shot);
	end
end

function focus()
	gpio.write(focus_pin, gpio.LOW);
	tmr.delay(2000000);
	gpio.write(focus_pin, gpio.HIGH);
	work_end();
end

function recv(client, request)
	local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
	if method == nil then
		_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
	end
	local params = {};
	if vars ~= nil then
		for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
			params[k] = v;
		end
	end

	if (path == "/start") then
		if state == state_init then
			state = state_work;
			client_conn = client;
			shot_cnt = tonumber(params["count"]);
			shot_delay = tonumber(params["delay"]) * 1000;
			shot_exp = tonumber(params["exp"]) * 1000000;
			if shot_exp == 0 then
				shot_exp = 200000;
			end
			start();
			return;
		end
	elseif (path == "/focus") then
		if state == state_init then
			state = state_work;
			client_conn = client;
			focus();
			return;
		end
	elseif (path == "/status") then
		if state == state_init or state == state_work then
			send(state);
		end
	else
		if state == state_init then
			state = state_main;
			file.open("main.html", "r");
			send(nil);
			return;
		end
	end
	client:close()
	collectgarbage();
end

function sent(conn)
	print("sent");
	if state == state_main then
		local r = file.read(1400);
		if r then 
			conn:send(r);
		else
			file.close();
			work_end();
		end
	elseif state == state_ok then
		work_end();
	end
end

gpio.mode(shot_pin, gpio.OUTPUT, gpio.FLOAT);
gpio.write(shot_pin, gpio.HIGH);
gpio.mode(focus_pin, gpio.OUTPUT, gpio.FLOAT);
gpio.write(focus_pin, gpio.HIGH);

srv=net.createServer(net.TCP);
srv:listen(80, function(conn)
    conn:on("receive", recv)
	conn:on("sent", sent)
end);
