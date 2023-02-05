local util = require('util')

---@class ClientRequest : Request
---@field public params table<string, any>|nil

---PocketBase ComputerCraft Client
---
---@class Client
---@field public base_url string @The base PocketBase backend url address (eg. 'http://127.0.0.1.8090').
---@field public auth_store BaseAuthStore @A replaceable instance of the local auth store service.
---@field public lang string @Optional language code (default to `en-US`) that will be sent with the requests to the server as `Accept-Language` header.
---
---@field private recordServices table<string, RecordService>
local Client = {}

---Client:new creates a new client.
---
---@param base_url string|nil
---@param auth_store BaseAuthStore|nil
---@param lang string|nil
---@return Client
function Client:new(base_url, auth_store, lang)
    ---@type Client
    local o = {}

    -- Setup index table
    setmetatable(o, self)
    self.__index = self

    -- Apply given parameters
    if base_url == nil then
        o.base_url = '/'
    else
        o.base_url = base_url
    end

    if auth_store == nil then
        o.auth_store = LocalAuthStore:new()
    else
        o.auth_store = auth_store
    end

    if lang == nil then
        o.lang = "en-US"
    else
        o.lang = lang
    end

    -- TODO: Add other services

    return o
end

---Returns the RecordService associated to the specified collection.
---
---@param id_or_name string
---@return RecordService
function Client:collection(id_or_name)
    if self.recordServices[id_or_name] == nil then
        self.recordServices[id_or_name] = RecordService:new(self, id_or_name)
    end

    return self.recordServices[id_or_name]
end

---Builds a full client url by safely concatenating the provided path.
---
---@param path string
---@return string
function Client:build_url(path)
    local url = self.base_url
    if not util.ends_with(url, '/') then
        url = url .. '/'
    end

    if util.starts_with(path, '/') then
        url = url .. path:sub(2)
    else
        url = url .. path
    end

    return url
end

---Sends an api http request.
---
---@param path string
---@param req_config ClientRequest|nil
---@return boolean ok
---@return any|ClientResponseError response or error
function Client:send(path, req_config)
    ---@type ClientRequest
    local config = util.table_assign({ method = "GET", headers = {} }, req_config)

    -- serialize the body if needed and set the correct content type
    -- TODO: for FormData body the Content-Type header should be skipped
    if config.body ~= nil then
        if type(config.body) == 'table' then
            config.body = textutils.serialiseJSON(config.body)
        end

        if config.headers["Content-Type"] == nil then
            config.headers = util.table_assign({}, config.headers, {
                ["Content-Type"] = "application/json"
            })
        end
    end

    -- add Accept-Language header (if not already)
    if config.headers["Accept-Language"] == nil then
        config.headers = util.table_assign({}, config.headers, {
            ["Accept-Language"] = self.lang
        })
    end

    -- check if Authorization header can be added
    if self.auth_store ~= nil and
            self.auth_store.token ~= nil and
            config.headers["Authorization"] == nil then
        config.headers = util.table_assign({}, config.headers, {
            ["Authorization"] = self.auth_store.token
        })
    end

    -- TODO: handle auto cancelation for duplicated pending request
    -- TODO: remove the special cancellation params from the other valid query params

    -- build url + path
    local url = self:build_url(path)

    -- serialize the query parameters
    if config.params ~= nil then
        local query = self.serialize_query_params(config.params)
        if query ~= nil then
            if url:match("?") then
                url = url..'&'
            else
                url = url..'?'
            end
            url = url..query
        end
        config.params = nil
    end

    -- TODO: handle before send callback

    -- Set request url
    config.url = url

    -- send request
    local resp, err, err_resp = wrapRequest(config)
    local body
    if resp ~= nil then
        body = resp.readAll()
    else
        body = err_resp.readAll()
    end

    -- Try to parse body
    local status, data = pcall(function() return textutils.unserialiseJSON(body) end)
    if not status then
        data = nil
    end

    -- TODO: handle after send callback

    if resp == nil then
        return false, ClientResponseError:new({
            url = url,
            status = err_resp.getResponseCode(),
            data = data
        })
    end

    return true, data
end

---Sends a raw request and waits for an answer.
---
---@param config Request
---@return Response|nil The resulting http response, which can be read from.
---@return string A message detailing why the request failed.
---@return Response|nil The failing http response, if available.
function wrapRequest(config)
    http.request(config)
    while true do
        local event, param1, param2, param3 = os.pullEvent()
        if event == "http_success" and param1 == config.url then
            return param2
        elseif event == "http_failure" and param1 == config.url then
            return nil, param2, param3
        end
    end
end

---Serializes the provided query parameters into a query string.
---
---@param params table<string, any>
---@return string
function Client:serialize_query_params(params)
    local result = {}
    for k, v in pairs(params) do

    end
end

return Client
