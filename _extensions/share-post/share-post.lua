local kAfterBody = "after-body"
local kInHeader = "in-header"
local kBeforeBody = "before-body"

local kUsePackages = "packages"

local urlPattern = "(https?://[%w%$%-%_%.%+%!%*%'%(%)%:%%]+/)(.+)"

-- TODO: Support alignment
--  margin-left: auto; margin-right: auto; display: block;

-- TODO: Place a link for non-html output

local alignmentStyles = [[
<style>
.linkedin-post,
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

local function parseUrl(url)
    local baseUrl, urlPath = url:match(urlPattern)
    return {
        url = url,
        base = baseUrl,
        path = urlPath
    }
end

local beginInlines = { pandoc.RawInline('latex', '\\begin{tcolorbox}[]\n') }
local endInlines = { pandoc.RawInline('latex', '\n\\end{tcolorbox}') }

local function makeBox(text, url, icon) 
    return pandoc.Div(pandoc.List({
        beginInlines,
        pandoc.RawInline('latex', '{' .. icon .. '}'),
        pandoc.Link(text,url),
        endInlines
    }))
end

local boxPackages = {
    "tcolorbox",
    "fontawesome5"
}

local threads = {
    canHandle = function(urlData)
        return urlData.base:find("threads.net")
    end,
    handle = {
        html = function(urlData)
            local iframe = '<blockquote class="text-post-media" data-text-post-permalink="' .. urlData.url .. '" data-text-post-version="0"><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async defer src="https://www.threads.net/embed.js"></script>',
                [kInHeader] = alignmentStyles
            }
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded Threads Post", urlData.url, "\\faShareSquare"),
                [kUsePackages] = boxPackages
            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded Threads Post", urlData.url)
            }
        end
    }
}

local instagram = {
    canHandle = function(urlData)
        return urlData.base:find("instagram.com") 
    end,
    handle = {
        html = function(urlData)
            local iframe = '<blockquote class="instagram-media" data-instgrm-version="7" ><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async defer src="//platform.instagram.com/en_US/embeds.js"></script>'
            }
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded Instagram Post", urlData.url, "\\faInstagram"),
                [kUsePackages] = boxPackages

            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded Instagram Post", urlData.url)
            }
        end
    }
}

local twitter = {
    canHandle = function(urlData)
        return urlData.base:find("twitter.com")
    end,
    handle = {
        html = function(urlData)
            local iframe = '<blockquote class="twitter-tweet" id="foobar123"><a href="' .. urlData.url .. '"></a></blockquote>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>'
            }
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded Twitter Post", urlData.url, "\\faTwitterSquare"),
                [kUsePackages] = boxPackages
            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded Twitter Post", urlData.url)
            }
        end
    }
}

local pinterest = {
    canHandle = function(urlData)
        return urlData.base:find("pinterest.com")
    end,
    handle = {
        html = function(urlData)
            local id = urlData.path:gsub("pin/", "")
            if id:match("/$") then
                id = id:sub(1, -2)
            end
            local iframe = '<iframe class="pinterest-rendered" src="https://assets.pinterest.com/ext/embed.html?id=' .. id .. '" height="316" width="345" frameborder="0" scrolling="no" style=""></iframe>'
            return {
                block = pandoc.RawBlock("html", iframe),
            }
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded Pinterest Post", urlData.url, "\\faPinterestSquare"),
                [kUsePackages] = boxPackages
            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded Pinterest Post", urlData.url)
            }
        end
    }
}

local linkedin = {
    canHandle = function(urlData)
        return urlData.base:find("linkedin.com")
    end,
    handle = {
        html = function(urlData)
            local pattern = "(%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d+)"
            local id = urlData.path:match(pattern)
            if (id) then
                -- https://www.linkedin.com/posts/posit-software_quarto-quarto-14-activity-7156030921387778049-dHKD?utm_source=share&utm_medium=member_desktop
                local iframe = '<iframe class="linkedin-post" src="https://www.linkedin.com/embed/feed/update/urn:li:activity:' .. id .. '" height="1062" width="504" frameborder="0" allowfullscreen="" title="Embedded post"></iframe>'
                return {
                    block = pandoc.RawBlock("html", iframe),
                    [kAfterBody] = '<script src="' .. urlData.base .. 'embed.js" async="async"></script>',
                    [kInHeader] = alignmentStyles
                } 
            else
                return nil
            end
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded LinkedIn Post", urlData.url, "\\faLinkedin"),
                [kUsePackages] = boxPackages
            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded LinkedIn Post", urlData.url)
            }
        end
    }
}

local mastodon = {
    canHandle = function(urlData)
        return urlData.base:find("mastodon")
    end,
    handle = {
        html = function(urlData)
            local iframe = '<iframe src="' .. urlData.url .. '/embed" class="mastodon-embed" style="max-width: 100%; border: 0;" width="400" allowfullscreen="allowfullscreen"></iframe>'
            return {
                block = pandoc.RawBlock("html", iframe),
                [kAfterBody] = '<script src="' .. urlData.base .. 'embed.js" async="async"></script>',
                [kInHeader] = alignmentStyles
            }
        end,
        latex = function(urlData)
            return {
                block=makeBox("Embedded Mastodon Post", urlData.url, "\\faMastodon"),
                [kUsePackages] = boxPackages
            }
        end,
        other = function(urlData)
            return {
                block=pandoc.Link("Embedded Mastodon Post", urlData.url)
            }
        end
    }
}

local handlers = {
    threads,
    instagram,
    twitter,
    pinterest,
    linkedin,
    mastodon
}

return {
    ['share-post'] = function(args, kwargs, meta)
        local result_block
        local url = args[1]
        -- html output
        local urlData = parseUrl(url)
        for i,handler in ipairs(handlers) do

            if handler.canHandle(urlData) then 

                local make_result = handler.handle.other
                if quarto.doc.is_format("html") then
                    make_result = handler.handle.html
                elseif quarto.doc.is_format("pdf") then
                    make_result = handler.handle.latex
                end

                -- return the raw html block
                local result = make_result(urlData)
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
                if result[kUsePackages] ~= nil then
                    for _i,v in ipairs(result[kUsePackages]) do
                        quarto.doc.use_latex_package(v)
                    end
                end
            end
        end
        return result_block
    end
}