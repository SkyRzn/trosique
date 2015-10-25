function send(conn, data)
	local res = "HTTP/1.1 200 OK\r\n\r\n";
	if data then
		res = res..data;
	end
	conn:send(res);
end

function shot()
	tmr.wdclr();
	gpio.write(shot_pin, gpio.LOW);
	tmr.delay(shot_exp);
	gpio.write(shot_pin, gpio.HIGH);
	tmr.wdclr();
end

function focus()
	tmr.wdclr();
	gpio.write(focus_pin, gpio.LOW);
	tmr.delay(2000000);
	gpio.write(focus_pin, gpio.HIGH);
	tmr.wdclr();
end

function get_params(request)
	local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
	if method == nil then
		_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
	end
	local params = {"path": path};
	if vars ~= nil then
		for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
			params[k] = v;
		end
	end
	
	return params;
end

function shot_params(params)
	shot_cnt = tonumber(params["count"]);
	shot_delay = tonumber(params["delay"]) * 1000;
	shot_exp = tonumber(params["exp"]) * 1000000;
	if shot_exp == 0 then
		shot_exp = 200000;
	end
end

function init()
	gpio.mode(shot_pin, gpio.OUTPUT, gpio.FLOAT);
	gpio.write(shot_pin, gpio.HIGH);
	gpio.mode(focus_pin, gpio.OUTPUT, gpio.FLOAT);
	gpio.write(focus_pin, gpio.HIGH);
end

