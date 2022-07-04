--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]

function Intro.GetLanguage(sentence)
    if Intro.Language[Intro.Settings.Language] and Intro.Language[Intro.Settings.Language][sentence] then
        return Intro.Language[Intro.Settings.Language][sentence]
    else
        return Intro.Language["default"][sentence]
    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:IntroChatInfo(msg, type)
    if SERVER then
        if type == 1 then
            self:SendLua("chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 0, 165, 225 ), [["..msg.."]])")
        elseif type == 2 then
            self:SendLua("chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 180, 225, 197 ), [["..msg.."]])")
        else
            self:SendLua("chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 225, 20, 30 ), [["..msg.."]])")
        end
    end

    if CLIENT then
        if type == 1 then
            chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 0, 165, 225 ), msg)
        elseif type == 2 then
            chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 180, 225, 197 ), msg)
        else
            chat.AddText(Color( 225, 20, 30 ), [[[Cinematic Intro] : ]] , Color( 225, 20, 30 ), msg)
        end
    end
end