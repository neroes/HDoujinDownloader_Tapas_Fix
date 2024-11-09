function Register()

    module.Name = 'Danbooru'
    module.Type = 'Artist CG'
    module.Strict = false
    module.DeferHttpRequests = true

    module.Domains.Add('danbooru.donmai.us')

end

local function InitializeDom()

    -- Note that Danbooru requires a non-spoofed user agent for all requests.
    -- https://e621.net/wiki_pages/2425

    http.Headers['User-Agent'] = API_CLIENT

    dom = Dom.New(http.Get(url))

end

local function GetPostUrlsFromResultPage()
    return dom.SelectValues('//div[contains(@class,"post-preview-container")]/a/@href')
end

local function GetNextResultsUrl()
    return dom.SelectValue('//a[contains(@class,"paginator-next")]/@href')
end

function GetInfo()

    InitializeDom()

    info.Title = dom.SelectValue('//title'):before('|')
    info.Tags = dom.SelectValues('//li[contains(@class,"tag-type-0")]/a[last()]')
    info.Artist = dom.SelectValues('//li[contains(@class,"tag-type-1")]/a[last()]')
    info.Parody = dom.SelectValues('//li[contains(@class,"tag-type-3")]/a[last()]')
    info.Characters = dom.SelectValues('//li[contains(@class,"tag-type-4")]/a[last()]')

    if(isempty(GetNextResultsUrl())) then
        info.PageCount = GetPostUrlsFromResultPage().Count()
    end

end

function GetPages()

    InitializeDom()

    -- Add all post URLs, and the next results URL.

    local nextResultsUrl = GetNextResultsUrl()

    pages.AddRange(GetPostUrlsFromResultPage())

    if(not isempty(nextResultsUrl)) then
        pages.Add(nextResultsUrl)
    end

    pages.Headers['User-Agent'] = API_CLIENT

end

function BeforeDownloadPage()

    InitializeDom()

    local tags = GetParameter(url, "tags")

    if(isempty(tags)) then

        page.Url = dom.SelectValue('//a[@download]/@href')

    else

        GetPages()

    end

end
