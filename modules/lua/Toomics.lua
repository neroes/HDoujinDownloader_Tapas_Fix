function Register()

    module.Name = 'Toomics'
    module.Type = 'Webtoon'

    module.Domains.Add('global.toomics.com')
    module.Domains.Add('toomics.com')

end

local function DoAgeVerification()

    http.Get('//'..module.Domain..'/en/index/set_display/?display=A')
    
end

function GetInfo()
    info.Title =  dom.SelectValue('//h2[contains(@class,"font-bold") and contains(@class,"mt-3")]')
    local authorArtist = dom.SelectValue('//p[contains(@class,"mt-3") and contains(@class,"text-gray-300")]')
    if authorArtist ~= nil then
        authorArtist = RegexReplace(authorArtist, '/', ',')--seem to use either / or | to separate author and artist
        authorArtist = authorArtist:gsub("|", ",")
        info.Author = authorArtist:match('^%s*([^,]+)')
        info.Artist = authorArtist:match('^[^,]+,%s*(.+)$')
    end
    local tags = dom.SelectValues('//a[@data-toon-idx]')
    info.Tags = RegexReplace(tags, '#', '')
    info.Language = url:regex('\\/(en|ko|sc|tc)\\/', 1)
    info.Summary = dom.SelectValue('//h2')
    info.Status = dom.SelectValue('//span[@class="date"]')

end

function GetChapters()

    for node in dom.SelectElements('//ol[contains(@class, "list-ep")]//a') do

        local number = node.SelectValue('div[contains(@class, "cell-num")]'):trim()
        local title = node.SelectValue('div[contains(@class, "cell-title")]'):trim()
        local url = node.SelectValue('@onclick'):regex("(?:'login',\\s|href=)'(.+?)'", 1)

        chapters.Add(url, number .. ' - ' .. title)

    end
    

end

function GetPages()
    if(dom.SelectValue('//meta[contains(@property, "og:url")]/@content'):contains('age_verification')) then
        
        DoAgeVerification()

        dom = Dom.New(http.Get(url))

    end
    pages.AddRange(dom.SelectValues('//img[contains(@id, "set_image")]/@data-src'))
    if(pages.Count() == 0) then
        Fail(Error.CaptchaRequired.WithHelpLink("https://github.com/HDoujinDownloader/HDoujinDownloader/wiki/Downloading-from-Anchira"))
    end
    Log(url)
    local episodeId, episodeNumber, seriesId = url:match("/code/(%d+)/ep/(%d+)/toon/(%d+)")
    Log('Episode ID:' .. episodeId .. ' Episode Number:' .. episodeNumber .. ' Series ID:' .. seriesId)
    --SendMockScrollTracking(seriesId, episodeNumber, episodeId)
end

function Login()

  -- Login is currently not working (login page 404s).

    if(not http.Cookies.Contains('GTOOMICSremember_id')) then

        local originUrl = 'https://' .. module.Domain
        local refererUrl = originUrl .. '/en'
        local loginEndpoint = refererUrl .. '/auth/layer_login'
        
        http.Get(refererUrl)

        http.Referer = refererUrl

        http.PostData.Add('user_id', username)
        http.PostData.Add('user_pw', password)
        http.PostData.Add('save_user_id', '1')
        http.PostData.Add('keep_cookie', '1')
        http.PostData.Add('returnUrl', '/')
        http.PostData.Add('direction', 'N')
        http.PostData.Add('login_chk', '')
        http.PostData.Add('vip_chk', 'Y')

        http.Headers['accept'] = 'application/json, text/javascript, */*; q=0.01'
        http.Headers['content-type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        http.Headers['origin'] = originUrl
        http.Headers['x-requested-with'] = 'XMLHttpRequest'

        -- Add the "click position" cookie, which is set when the mouse is clicked.

        http.Cookies.Add('.toomics.com', 'cp', '631|326')

        local response = http.PostResponse(loginEndpoint)

        if(not response.Cookies.Contains('GTOOMICSremember_id')) then
            Fail(Error.LoginFailed)
        end

        global.SetCookies(response.Cookies)

    end

end

function SendMockScrollTracking(seriesId, episodeNumber, episodeId)
    local url = 'https://toomics.com/en/webtoon/tr_dt'
    local timestamps = GenerateRandomTimestamps(5, 10) -- 5 timestamps, up to 10 seconds ago
    local scrollPositions = GenerateRandomScrollPositions(5, 100, 1000) -- 5 events, 1000 pixes each
    local tracking_id = GetTrackingId(seriesId, episodeId, episodeNumber)
    local timestamps = GenerateRandomTimestamps(count, 10)
    Log('Generated timestamps:', timestamps)
    Log('Generated scroll positions:', scrollPositions)
    Log('Tracking ID:', tracking_id)
    
    local postData =
        'tr_i=' .. tracking_id ..
        '&ms%5B%5D=' .. scrollPositions[1] ..
        '&ms%5B%5D=' .. scrollPositions[2] ..
        '&ms%5B%5D=' .. scrollPositions[3] ..
        '&ms%5B%5D=' .. scrollPositions[4] ..
        '&ms%5B%5D=' .. scrollPositions[5] ..
        '&ev%5B%D=scroll&ev%5B%5D=scroll&ev%5B%5D=scroll&ev%5B%5D=scroll&ev%5B%5D=scroll' ..
        '&t_i=' .. seriesId ..
        '&t_o=' .. episodeId ..
        '&d_t=pc' ..
        '&s_t%5B%5D=&s_t%5B%5D=&s_t%5B%5D=&s_t%5B%5D=&s_t%5B%5D=' ..
        '&r_t%5B%5D=' .. timestamps[1] ..
        '&r_t%5B%5D=' .. timestamps[2] ..
        '&r_t%5B%5D=' .. timestamps[3] ..
        '&r_t%5B%5D=' .. timestamps[4] ..
        '&r_t%5B%5D=' .. timestamps[5]

    local response = http.Post(url, postData, 'application/x-www-form-urlencoded')
    Log('Scroll tracking POST data:', postData)
    print('Scroll tracking POST response:', response)
end

function GenerateRandomTimestamps(count, maxSecondsAgo)
    local timestamps = {}
    local now = os.time()
    for i = 1, count do
        -- Random offset in the last maxSecondsAgo seconds
        local offset = math.random(0, maxSecondsAgo)
        local t = now - offset
        -- Format: YYYY-MM-DD+HH:MM:SS.sss000 (with random milliseconds)
        local ms = math.random(0,999)
        local formatted = os.date('%Y-%m-%d+%H:%M:%S', t) .. string.format('.%03d000', ms)
        table.insert(timestamps, formatted)
    end
    -- Sort so they're in chronological order
    table.sort(timestamps)
    return timestamps
end

function GenerateRandomScrollPositions(count, minValue, maxValue)
    local positions = {}
    local last = minValue
    for i = 1, count do
        -- Ensure each scroll position increases
        local step = math.random(400, 800)
        last = last + step + math.random()
        table.insert(positions, string.format('%.6f', last))
    end
    return positions
end

function GetTrackingId(seriesId, episodeNumber, episodeId)
    local url = 'https://toomics.com/en/webtoon/tr_init'
    local now = os.date('%Y-%m-%d+%H:%M:%S', os.time()) .. '.000000'
    local screen_w = 1226
    local screen_h = 741
    local postData =
        't_i=' .. seriesId ..
        '&a_i=' .. episodeNumber ..
        '&t_o=' .. episodeId ..
        '&d_t=pc' ..
        '&r_t=' .. now ..
        '&s_w=' .. screen_w ..
        '&s_h=' .. screen_h ..
        '&u_a=Mozilla%2F5.0+(Windows+NT+10.0%3B+Win64%3B+x64%3B+rv%3A140.0)+Gecko%2F20100101+Firefox%2F140.0'
    
    Log('Sending POST data for tracking ID')
    local response = http.Post(url, postData)
    Log('Response: ' .. response)
    local json = Json.New(response)
    local tr_idx = json.SelectValue('tr_idx')
    Log('Tracking ID:', tr_idx)
    return tr_idx
end
