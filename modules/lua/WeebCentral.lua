function Register()

    module.Name = 'Weeb Central'
    module.Language = 'en'

    module.Domains.Add('weebcentral.com')

end

local function GetGalleryId()
    return url:regex('\\/(?:series|chapters)\\/([^\\/#?]+)', 1)
end

function GetInfo()

    info.Title = dom.SelectValue('//h1')
    info.Description = dom.SelectValue('//strong[contains(text(),"Description")]/following-sibling::p')
    info.AlternativeTitle = dom.SelectValues('//strong[contains(text(),"Associated Name(s)")]/following-sibling::ul//li')
    info.Author = dom.SelectValues('//strong[contains(text(),"Author(s)")]/parent::*//a')
    info.Tags = dom.SelectValues('//strong[contains(text(),"Tags")]/parent::*//a')
    info.Type = dom.SelectValues('//strong[contains(text(),"Type")]/parent::*//a')
    info.Status = dom.SelectValues('//strong[contains(text(),"Status")]/parent::*//a')
    info.DateReleased = dom.SelectValues('//strong[contains(text(),"Released")]//following-sibling::span')

    if(isempty(info.Title)) then
        info.Title = dom.Title:before('|')
    end

end

function GetChapters()

    if(not url:contains('/series/')) then
        return
    end

    -- We need to make an additional request to get the full chapters list.

    local galleryId = GetGalleryId()
    local chapterListEndpoint = '/series/' .. galleryId .. '/full-chapter-list'

    http.Headers['accept'] = '*/*'
    http.Headers['hx-current-url'] = url
    http.Headers['hx-request'] = 'true'
    http.Headers['hx-target'] = 'chapter-list'

    dom = Dom.New(http.Get(chapterListEndpoint))

    for chapterNode in dom.SelectElements('//a') do

        local chapterUrl = chapterNode.SelectValue('@href')
        local chapterTitle = chapterNode.SelectValue('.//span[contains(@class,"grow")]')

        chapters.Add(chapterUrl, chapterTitle)

    end

    chapters.Reverse()

end

function GetPages()
    pages.AddRange(dom.SelectValues('//img[contains(@alt,"Page") and not (@x-show)]/@src'))
end
