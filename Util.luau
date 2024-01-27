local Utilities = {}

Utilities.switch = function<K>(x: K, cases: {[K]: (string) -> ()}) 
	local found = false
	
	for i,v in pairs(cases) do 
		if (x == i) then
			found = true
			v(x)
		end
	end
	
	if found == true then return end
	
	if (cases["__default"] ~= nil) then 
		cases["__default"](x)
	end
end

Utilities.substring = function(t: {}, index, stop)
	local a = table.pack(table.unpack(t, index, stop))
	a["n"] = nil
	local str = ""
	for i,v in pairs(a) do 
		str = str .. v
	end

	a = str
	str = nil
	gcinfo()
	return a
end

return Utilities