-- 用户登陆,使用第三方登陆 QQ wechat
-- 更新分数
-- 拉取榜单

local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local netpack = require "skynet.netpack"
local protobuf = require "protobuf"

-- proto
local function load_protofile(pbfile)
    protobuf.register_file(pbfile)
    print(string.format("注册proto文件: %s", pbfile))
end

--链接管理
local connection = {}

-- 通信消息
local MSG = {}

-- proto消息处理函数
local datacmd = {}

-- 用户管理
local usermanager = {}

local queue

-- open close data 等都与netpack中对应了 代码在 lua-netpack.c +480

-- 客户端链接
function MSG.open(fd, msg)
    print("MSG.open")
    -- 这里将fd投递到框架，否则框架不会处理到这个fd
    socketdriver.start(fd)
end

function MSG.close(fd)
    print("MSG.close")
end

--------命令处理------------------------------------------------
function datacmd.AddScore(message)
    local data = protobuf.decode("ns.AddScore", message)

    local uid = data.userid
    local score = data.score

    if usermanager[uid] then
        usermanager[uid] = usermanager[uid] + score;
        print("user: ", uid, ", curcore: ", usermanager[uid])
    else
        usermanager[uid] = score;
        print("user: ", uid, ", curcore: ", usermanager[uid])
    end
end

function datacmd.Login(message)
end

function datacmd.ReqRank(message)
end

--------命令处理------------------------------------------------

function MSG.data(fd, msg, sz)
    print(string.format("MSG.MsgParser fd(%d) msg(%s) sz(%d)", fd, msg, sz))

    -- 解包
    local message = netpack.tostring(msg, sz)
    -- 反序列化
    local data = protobuf.decode("ns.Base", message)

    print(string.format("recv msg msgname(%s)", data.msgname))

    -- 根据消息名字投递到相应函数
    local f = datacmd[data.msgname]
    if f then
        f(message)  
    end
end

-- 注册消息

-- 注册socket类消息(只处理客户端上来的请求)
skynet.register_protocol {
    name = "socket",
    id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET=6
    unpack =  function(msg, sz)    -- 解包函数
        return netpack.filter(queue, msg, sz) 
    end,
    -- 参数 (session/*类似callbackid*/, source/*源*/, )
    dispatch = function(_, _, q, type, ...)   --分发函数
        print(type)
        if type then
            MSG[type](...)
        end 
    end 
}

skynet.start(
    function()
        InitServer()
    end 
)

-- 初始化服务器
function InitServer()
    local address="0.0.0.0"
    local port = 8383
    print(string.format("Listen on (%s) port (%d)", address, port))
    socket = socketdriver.listen(address, port)
    socketdriver.start(socket)
    load_protofile("./SpaceShooter.pb")
end



local function GetRank()
end
