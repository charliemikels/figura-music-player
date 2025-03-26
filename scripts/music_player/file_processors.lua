


local function processors_init()
    -- establish a list of file processors
    --
    printTable(listFiles("./file_processors", false))
    printTable(listFiles("./", false))
    -- for _, script in ipairs(listFiles("/scripts", true)) do
    --     require(script)
    -- end
end

processors_init()
