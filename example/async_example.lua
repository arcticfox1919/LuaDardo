sleep(3000)

function add (b)
    local a = 1
    while( a < b ) do
        print("a value is", a)
        a = a + 1
    end
    return a
end

b = add(3)
dprint(b)
print("lua finished")