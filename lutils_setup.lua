function events.entity_init()
	-- see: https://github.com/lexize/lutils/tree/7ed1796f0a5c74ab999f7a817a0491d1b4e3b3cb/docs/wiki 
	if host:isHost() and type(lutils) == "LUtils" then
		lutils.file:setFolderName("lutils_root")		
	end
end
