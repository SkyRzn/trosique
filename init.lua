shot_cnt = 0;
shot_exp = 0;  --microsec
shot_delay = 0;  --millisec
shot_pin = 6 --GPIO 12
focus_pin = 7 --GPIO 13
sending_main = false
client_conn = 0


function work_end()
	client_conn:close();
	collectgarbage();
end

function shot()
	gpio.write(shot_pin, gpio.LOW)
	tmr.delay(shot_exp);
	gpio.write(shot_pin, gpio.HIGH)
	
	shot_cnt = shot_cnt - 1;
	
	if shot_cnt > 0 then
		tmr.alarm(0, shot_delay, 0, shot);
	else
		work_end();
	end
end

function focus()
	print('focus')
	gpio.write(focus_pin, gpio.LOW)
	tmr.delay(2000000);
	gpio.write(focus_pin, gpio.HIGH)
	work_end();
end

function recv(client,request)
	local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
	if(method == nil)then
		_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
	end
	local params = {}
	if (vars ~= nil)then
		for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
			params[k] = v
		end
	end
	
	client:send("HTTP/1.1 200 OK\r\n\r\n");
	
	client_conn = client

	sending_main = false
	print("'"..path.."'");
	if (path == "/start") then
		shot_cnt = tonumber(params["count"]);
		shot_delay = tonumber(params["delay"]) * 1000;
		shot_exp = tonumber(params["exp"]) * 1000000;
		if shot_exp == 0 then
			shot_exp = 200000;
		end
		
		if shot_delay == 0 then
			if shot_cnt == 1 then
				shot();
				work_end();
			else
				shot_delay = 500;
			end			
		end
		if shot_delay > 0 then
			tmr.alarm(0, shot_delay, 0, shot);
		end
	elseif (path == "/focus") then
		focus();
	else
		file.open("main.html", "r");
		sending_main = true
		local r = file.read(1400);
		client:send(r);
		collectgarbage();
		return;
	end
	collectgarbage();
end

function sent(conn)
	if sending_main then
		local r = file.read(1400);
		if r then 
			conn:send(r);
		else
			file.close();
			conn:close();
			collectgarbage();
		end
	end
end

gpio.mode(shot_pin, gpio.OUTPUT, gpio.FLOAT)
gpio.write(shot_pin, gpio.HIGH)
gpio.mode(focus_pin, gpio.OUTPUT, gpio.FLOAT)
gpio.write(focus_pin, gpio.HIGH)

srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", recv)
	conn:on("sent", sent)
end)
