local kAfterBody = "after-body"
local kInHeader = "in-header"
local kBeforeBody = "before-body"

local kAlign = "align"

local urlPattern = "(https?://[%w%$%-%_%.%+%!%*%'%(%)%:%%]+/)(.+)"

-- TODO: Support alignment
--  margin-left: auto; margin-right: auto; display: block;

-- TODO: Place a link for non-html output

local alignmentStyles = [[
<style>
.text-post-media,
.pinterest-rendered,
.twitter-tweet-rendered,
.instagram-media, 
.mastodon-embed {
    display: block;
    margin-left: auto !important;
    margin-right: auto !important;
}
</style>
]]


local handlers = {
    ['threads'] = function(urlData)
        if urlData.base:find("threads.net") then
            local iframe = '<blockquote class="text-post-media" data-text-post-permalink="' .. urlData.url .. '" data-text-post-version="0"><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async defer src="https://www.threads.net/embed.js"></script>',
                [kInHeader] = alignmentStyles
            }
        else
            return nil
        end
    end,
    ['instagram'] = function(urlData)
        if urlData.base:find("instagram.com") then
            local iframe = '<blockquote class="instagram-media" data-instgrm-version="7" ><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async defer src="//platform.instagram.com/en_US/embeds.js"></script>'
            }
        else
            return nil
        end
    end,
    ['twitter'] = function(urlData)
        if urlData.base:find("twitter.com") then
            local iframe = '<blockquote class="twitter-tweet" id="foobar123"><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>'
            }
        else
            return nil
        end
    end,
    ['pinterest'] = function(urlData)
        if urlData.base:find("pinterest.com") then
            local id = urlData.path:gsub("pin/", "")
            if id:match("/$") then
                id = id:sub(1, -2)
            end
            local iframe = '<iframe class="pinterest-rendered" src="https://assets.pinterest.com/ext/embed.html?id=' .. id .. '" height="316" width="345" frameborder="0" scrolling="no" style=""></iframe>'
            return {
                block = pandoc.RawBlock("html", iframe),
            }
        else
            return nil
        end
    end,    
    ['mastodon'] = function(urlData)
        if urlData.base:find("mastodon") then
            local iframe = '<iframe src="' .. urlData.url .. '/embed" class="mastodon-embed" style="max-width: 100%; border: 0;" width="400" allowfullscreen="allowfullscreen"></iframe>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script src="' .. urlData.base .. 'embed.js" async="async"></script>',
                [kInHeader] = alignmentStyles
            }
        else
            return nil
        end
    end,    
}




local function parseUrl(url)
    local baseUrl, urlPath = url:match(urlPattern)
    return {
        url = url,
        base = baseUrl,
        path = urlPath
    }
end

return {
    ['share-post'] = function(args, kwargs, meta)
        local url = args[1]
        local urlData = parseUrl(url)


        local result_block
        for k,v in pairs(handlers) do

            local result = v(urlData);
            if result ~= nil then
                -- return the raw html block
                result_block = result.block
                
                -- inject dependencies
                if result[kInHeader] ~= nil then
                    quarto.doc.include_text(kInHeader, result[kInHeader])
                end
                if result[kBeforeBody] ~= nil then
                    quarto.doc.include_text(kBeforeBody, result[kBeforeBody])
                end
                if result[kAfterBody] ~= nil then
                    quarto.doc.include_text(kAfterBody, result[kAfterBody])
                end
                break
            end

        end
        return result_block
    end
}